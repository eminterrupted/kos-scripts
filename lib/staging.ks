// #include "0:/lib/libLoader.ks"
@lazyGlobal off.

// *~ Dependencies ~* //
// Required libraries not loaded by libLoader by default go here
// #region
// #endregion


// *~ Variables ~* //
// Local and global variables used in this library
// #region
    // *- Local
    // #region
    local l_boosterMaxIdx to 0.
    // #endregion

    // *- Global
    // #region
    // #endregion
// #endregion


// *~ Functions ~* //
// #region
  
    // *- Staging
    // #region

        // -- Global
        // #region
        // ArmAutoStaging :: (_stgLimit)<type> -> (ResultCode)<scalar>
        // Arms automatic staging based on current thrust levels. if they fall below 0.1, we stage
        global function ArmAutoStaging
        {
            parameter _stgLimit is g_StageLimit,
                      _stgCondition is 0. // 0: ThrustValue < 0.01

            local resultCode to 0.
            set g_StageLimit to _stgLimit.
            if Stage:Number <= g_StageLimit 
            {
                set resultCode to 2.
            }
            else
            {
                local selectedCondition to GetStagingConditionDelegate(_stgCondition). 

                if not g_LoopDelegates:HasKey("Staging")
                {
                    set g_LoopDelegates["Staging"] to lexicon().
                }
                
                if g_LoopDelegates:HasKey("Staging") set resultCode to 1.
            }

            return resultCode.
        }

        global function ArmAutoStagingNext
        {
            parameter _stgLimit to g_StageLimit,
                      _stgCondition is 0, // 0: ThrustValue < 0.01
                      _stgAction is 0. // 1 is experimental ullage check, 0 is regular safestage.

            local resultCode to 0.
            set g_StageLimit to _stgLimit.

            if Stage:Number <= _stgLimit
            {
                set resultCode to 2.
            }
            else
            {
                InitStagingDelegate(_stgCondition, _stgAction).
                set resultCode to 1.
            }
            return resultCode.
        }

        global function DisableAutoStaging
        {
            g_LoopDelegates:Remove("Staging").
        }

        // ArmHotStaging :: _stage<Int> -> staging_obj<Lexicon>
        // Writes events to g_LoopDelegates to fire hot staging if applicable for a given stage (next by default)
        global function ArmHotStaging
        {
            local ActionDel to {}.
            local CheckDel to {}.
            local Engine_Obj to lexicon().
            local ExtraLeadTime to 0.
            local HotStage_List to Ship:PartsTaggedPattern("(HotStg|HotStage|HS)").
            local HotStageLeadTimes to lexicon().

            if HotStage_List:Length > 0
            {
                if not g_LoopDelegates:HasKey("Staging")
                {
                    set g_LoopDelegates["Staging"] to lexicon().
                }

                g_LoopDelegates:Staging:Add("HotStaging", lexicon()).

                for p in HotStage_List
                {
                    if p:IsType("Engine")
                    {
                        if Engine_Obj:HasKey(p:Stage)
                        {
                            Engine_Obj[p:Stage]:Add(p).
                        }
                        else
                        {
                            set Engine_Obj[p:Stage] to list(p).
                        }

                        if p:Tag:MatchesPattern("\w*\|\d*")
                        {
                            set ExtraLeadTime to p:Tag:Split("|")[1]:ToNumber(0).
                            if not HotStageLeadTimes:HasKey(p:Stage)
                            {
                                HotStageLeadTimes:Add(p:Stage, extraLeadTime).
                            }
                        }
                    }
                }

                // if g_Debug OutDebug("Engine_Obj Keys: {0}":Format(Engine_Obj:Keys:Join(";")), -6).
                // wait 1.

                for HotStageID in Engine_Obj:KEYS
                {
                    OutInfo("Arming Hot Staging for ID: {0}":Format(HotStageID)).
                    
                    // Set up the g_LoopDelegates object
                    g_LoopDelegates:Staging:HotStaging:Add(HotStageID, lexicon(
                        "Engines", Engine_Obj[HotStageID]
                        ,"EngSpecs", GetEnginesSpecs(Engine_Obj[HotStageID])
                        )
                    ).
                    local stageEngines to list().
                    local stageEngines_BT to 999999.

                    // This must protect us against considering boosters and timed-MECO engines in hot staging calculations
                    local hitFlag to False.
                    from { local i to HotStageID + 1.} until hitFlag step { set i to i + 1.} do
                    {
                        if g_ShipEngines_Spec:HasKey(i)
                        {
                            for eng in g_ShipEngines_Spec[i]:EngList
                            {
                                if eng:DecoupledIn >= HotStageID and not eng:Decoupler:Tag:Contains("booster")
                                {
                                    stageEngines:Add(eng).
                                }
                            }

                            if stageEngines:Length > 0 
                            {
                                set hitFlag to True.
                            }
                        }
                    }

                    set ExtraLeadTime to choose HotStageLeadTimes[HotStageID] if HotStageLeadTimes:HasKey(HotStageID) else 0.

                    set checkDel  to {
                        // parameter _stageEngs.

                        if Stage:Number - 1 = HotStageID
                        {
                            if MissionTime > 0 
                            {
                                if g_ActiveEngines:Length > 0
                                {
                                    local SpoolTime to (g_LoopDelegates:Staging:HotStaging[HotStageID]:EngSpecs:SpoolTime * 1.325) + ExtraLeadTime. 
                                    set stageEngines_BT to GetEnginesBurnTimeRemaining(GetActiveEngines(Ship, "NoBooster")).
                                    // set stageEngines_BT to g_ActiveEngines_Data:BurnTimeRemaining.
                                    set g_TR to stageEngines_BT - SpoolTime.
                                    OutInfo("HotStaging Armed: (ET: T-{0,6}s) ":Format(Round(g_TR, 2), 1)).

                                    return (stageEngines_BT <= SpoolTime) or (g_ActiveEngines_Data:Thrust <= 0.1).
                                }
                                else if t_Val > 0
                                {
                                    if g_Debug { OutDebug("Fuel Exhausted, hot staging").}
                                    return True.
                                }
                                else
                                {
                                    if g_Debug { OutDebug("Right stage, but fell through HotStaging checkdel").}
                                }
                            }
                        }
                        return False.
                    }.

                    set actionDel to { 
                        OutInfo("[{0}] Hot Staging Engines ({1})   ":Format(HotStageID, "Ignition")).
                        for eng in g_LoopDelegates:Staging:HotStaging[HotStageID]:Engines
                        {
                            if not eng:Ignition { eng:Activate.}
                        }

                        OutInfo("[{0}] Hot Staging Engines ({1})   ":Format(HotStageID, "SpoolUp")).
                        // set g_ActiveEngines_Data to GetEnginesPerformanceData(g_ActiveEngines).
                        local NextEngines_Data to GetEnginesPerformanceData(g_LoopDelegates:Staging:HotStaging[HotStageID]:Engines).
                        until NextEngines_Data:Thrust >= g_ActiveEngines_Data:Thrust
                        {
                            set s_Val                to g_SteeringDelegate:CALL().
                            set g_ActiveEngines_Data to GetEnginesPerformanceData(g_ActiveEngines).
                            set NextEngines_Data     to GetEnginesPerformanceData(g_LoopDelegates:Staging:HotStaging[HotStageID]:Engines).
                            OutInfo("HotStaging Thrust Diff: Active [{0}] Staged [{1}]":Format(Round(g_ActiveEngines_Data:Thrust, 2), Round(NextEngines_Data:Thrust, 2))).
                            wait 0.01.
                        }
                        OutInfo("Staging").
                        wait until Stage:Ready.
                        Stage.
                        wait 0.5.
                        OutInfo().
                        g_LoopDelegates:Staging:HotStaging:REMOVE(HotStageID).
                        if g_LoopDelegates:Staging:HotStaging:KEYS:Length = 0
                        {
                            g_LoopDelegates:Staging:Remove("HotStaging").
                            set g_HotStagingArmed to  False.
                            set g_NextHotStageID to -2.
                        }
                        else
                        {
                            ArmHotStaging().
                        }
                    }.

                    // Add the delegates to the previously set up object
                    g_LoopDelegates:Staging:HotStaging[HotStageID]:Add("Check", checkDel@).
                    g_LoopDelegates:Staging:HotStaging[HotStageID]:Add("Action", actionDel@).

                    // Update g_NextHotStageID 
                    set g_NextHotStageID to Max(HotStageID, g_NextHotStageID).
                    g_HotStageIDList:Add(HotStageID).
                }

                return True.
            }
            else
            {
                return False.
            }
        }

        // InitStagingDelegate :: 
        // Adds the proper staging check and action delegates to the g_LoopDelegates object
        global function InitStagingDelegate
        {
            parameter _conditionType,
                      _actionType.

            if g_LoopDelegates:HasKey("Staging")
            {
                g_LoopDelegates:Staging:Add("Check", GetStagingConditionDelegate(_conditionType)).
                g_LoopDelegates:Staging:Add("Action", GetStagingActionDelegate(_actionType)).
            }
            else
            {
                set g_LoopDelegates["Staging"] to lexicon(
                    "Check", GetStagingConditionDelegate(_conditionType)
                    ,"Action", GetStagingActionDelegate(_actionType)
                ).
            }
        }

        // StagingCheck :: (_program)<Scalar>, (_runmode)<Scalar>, (_checkType)<Scalar> -> (shouldStage)<Bool>
        global function StagingCheck
        {
            parameter _program,
                      _runmode,
                      _checkType is 0.

            if Stage:Number <= g_StageLimit
            {
                return False.
            }
            else
            {
                return True.
            }
        }
        
        // #endregion

        // -- Local
        // #region

        // GetStagingActionDelegate :: (_actionType)<Scalar> -> (actionDel)<kOSDelegate>
        // Returns a delegate of the staging function that should be used (via Stage, or directly via a part's ModuleDecoupler action).
        local function GetStagingActionDelegate
        {
            parameter _actionType is 0.

            if _actionType = 0
            {
                return SafeStage@.
            }
            else if _actionType = 1
            {
                local stageAction to {
                    if g_NextEngines_Spec:Keys:Length = 0
                    {
                        set g_NextEngines to GetNextEngines().
                        if g_NextEngines:Length > 0
                        {
                            set g_NextEngines_Spec to GetEnginesSpecs(g_NextEngines).
                        }
                    }

                    until SafeStageWithUllage(g_NextEngines, g_NextEngines_Spec)
                    {
                        DispLaunchTelemetry().
                        wait 0.01.
                    }
                    // set g_ActiveEngines to GetActiveEngines(). 
                    // set g_NextEngines to GetNextEngines().
                    // set g_NextEngines_Spec to GetEnginesSpecs(g_NextEngines).
                }.

                return stageAction@.
            }
            else if _actionType = 2
            {
                return SafeStageWithUllage2@.
            }
        }
        
        
        // GetStagingConditionDelegate :: (_checkType)<string> -> (Result)<kOSDelegate>   // TODO: Implement other check types here (only thrust value for now)
        // Given a staging check type string, performs that condition check and returns the result
        local function GetStagingConditionDelegate
        {
            parameter _checkType is 0,
                      _checkVal is 0.01.

            // if _checkType = 0 // Thrust Value: Ship:AvailableThrust < 0.01
            // {
                // local condition to GetShipThrustConditionDelegate(Ship, _checkVal).
                // local boundCondition to condition:BIND(Ship, _checkVal).
                // return boundCondition.
                local condition to GetShipThrustConditionDelegate(Ship, _checkVal).
                return condition.
            // }
            // else if _checkType = 1
            // {
                
            // }
        }

        // CheckStageThrustCondition :: (_ves)<Vessel>, (_checkVal)Scalar -> thrustDelegate (Delegate)
        local function GetShipThrustConditionDelegate
        {
            parameter _ves,
                      _checkVal is 0.01.

            local conditionDelegate to { 
                parameter __ves is _ves, checkVal is _checkVal. 
                
                //if __ves:AvailableThrust < checkVal and __ves:Status <> "PRELAUNCH" and throttle > 0 
                // if __ves:AvailableThrust < checkVal and throttle > 0 and Stage:Number >= g_StageLimit
                if __ves:AvailableThrust < checkVal and throttle > 0 // and Stage:Number > g_StageLimit
                { 
                    // OutDebug("[{0}] StagingCheckDel TRUE (AT:{1}/{2}|{3}/0|{4}/{5})":Format(Round(MissionTime, 1), Round(__ves:AvailableThrust, 2), checkVal, Round(throttle, 2), Stage:Number, g_StageLimit), 8).
                    return 1.
                } 
                else 
                {
                    // OutDebug("[{0}] StagingCheckDel FALSE (AT:{1}/{2}|{3}/0|{4}/{5})":Format(Round(MissionTime, 1), Round(__ves:AvailableThrust, 2), checkVal, Round(throttle, 2), Stage:Number, g_StageLimit), 8).
                    return 0.
                }
            }.
            return conditionDelegate@.
        }

        local function SafeStage
        {
            // Check if current stage has RCS that should be disabled before staging.

            for m in Ship:ModulesNamed("ModuleRCSFX")
            {
                if m:Part:DecoupledIn >= Stage:Number - 1
                {
                    m:SetField("RCS", False).
                }
            }
            wait until Stage:Ready.
            stage.
            wait 0.01.
        }


        // Simpler version of SafeStageWithUllage using new GetEngineFuelStability function
        local function SafeStageWithUllage2
        {
            local StageResult to False.
            local FuelStabilityMin to 0.98.

            set g_NextEngines       to GetNextEngines().
            
            if g_NextEngines:Length > 0 
            {
                set g_NextEngines_Spec  to GetEnginesSpecs(g_NextEngines).
                if g_NextEngines_Spec:Ullage
                {
                    // if g_NextEngines[0]:Stage < Stage:Number
                    // {
                    //     set StageResult to True.
                    // }
                    // else
                    // {
                        local FuelStability to GetEngineFuelStability(g_NextEngines).
                        OutInfo("Fuel Stability Rating (Min/Avg): {0} / {1})":format(round(FuelStability[0], 2), round(FuelStability[1], 2))). 
                        
                        set StageResult to FuelStability[0] >= FuelStabilityMin. 
                    // }
                }
                else
                {
                    set StageResult to True.
                }
            }
            else
            {
                OutInfo("[SafeStageWithUllage2] g_NextEngines:Length = 0", 2).   
            }

            if StageResult
            {
                local RCSResult to RCS. // Stores current RCS state
                set RCS to False. // Disables RCS just before staging in case the stage we drop had RCS ullage. We don't need that slamming back into us as we're building up thrust
                // lock throttle to 0.
                wait until Stage:Ready.
                Stage.
                wait 0.01.
                // lock throttle to t_Val.
                set RCS to rcsResult. // Restores the RCS state to whatever it was before staging.
            }
            OutInfo().
            return StageResult.
        }

        // Checks for ullage before staging
        local function SafeStageWithUllage
        {
            parameter _engList,
                      _engList_Spec is lexicon().

            // set g_NextEngines     to GetNextEngines().
            // set g_NextEngines_Spec to GetEnginesSpecs(g_NextEngines).

            // OutDebug("[{0}] Running SafeStageWithUllage":Format(Round(MissionTime, 1)), 3).
            local stageResult to False.
            
            if _engList_Spec:Keys:Length = 0
            {
                set _engList_Spec to GetEnginesSpecs(_engList).
            }
                        
            if _engList_Spec:HasKey("FuelStabilityMin")
            {
                // OutDebug("[{0}] FuelStabilityMin Key Found":Format(Round(MissionTime, 1)), 4).
                if _engList_Spec:FuelStabilityMin > 0.925
                {
                    OutInfo("Ullage Check Passed!").
                    set stageResult to true.
                }
                else
                {
                    OutInfo("Ullage Check (Fuel Stability Rating: {0})":Format(round(_engList_Spec:FuelStabilityMin * 100, 2))).
                }
            }
            else
            {
                // OutDebug("[{0}] FuelStabilityMin Key Missing":Format(Round(MissionTime, 1)), 4).
                set stageResult to true.
            }

            if stageResult
            {
                // OutDebug("[{0}] Staging triggered":Format(Round(MissionTime, 1)), 5).
                local rcsResult to RCS. // Stores current RCS state
                set RCS to False. // Disables RCS just before staging in case the stage we drop had RCS ullage. We don't need that slamming back into us as we're building up thrust
                wait until Stage:Ready.
                Stage.
                wait 0.01.
                set RCS to rcsResult. // Restores the RCS state to whatever it was before staging.
            }
            OutInfo().

            return stageResult.
        }


        // SafeStage :: <none> -> <none>
        // Performs a staging function after waiting for the stage to report it is ready first
        local function SafeStageState
        {
            local ullageDelegate to { return true. }.

            if stagingState = 0
            {
                wait until Stage:Ready.
                Stage.
                set stagingState to 1.
            }
            else if stagingState = 1
            {
                if g_ActiveEngines_Data["Spec"]["IsSepMotor"]
                { 
                    if g_ActiveEngines_Data["Spec"]["Ullage"]
                    {
                        set ullageDelegate to { return CheckUllage(). }.  // #TODO: Write CheckUllage()
                    }
                    set stagingState to 2.
                }
                else
                {
                    set stagingState to 4.
                }
            }
            else if stagingState = 2
            {
                if ullageDelegate:Call()
                {
                    set stagingState to 1.
                }
            }
            else if stagingState = 4
            {
                set stagingState to 0.
                UNset ullageDelegate.
                return true.
            }
        }
        // #endregion
    // #endregion

    // *- Booster Staging
    // #region

    // ArmBoosterStaging
    //
    global function ArmBoosterStaging
    {
        parameter _boosterTag.

        local boosterObj to lex().
        local minIdx to 9.
        local regStr to _boosterTag + "\|Booster\|(AS\|)?\d".
        local boosterDecouplers to Ship:PartsTaggedPattern(regStr).

        if boosterDecouplers:Length > 0
        {
            from { local i is 0.} until i >= 5 step { set i to i + 1.} do
            {
                for dc in Ship:PartsTaggedPattern("Ascent\|Booster\|(AS\|)?{0}":Format(i))
                if dc:Stage >= g_StageLimit
                {
                    local tagSpl to dc:Tag:Replace(" ",""):Split("|").
                    local boosterIdx to tagSpl[tagSpl:Length - 1]:ToNumber().
                    set l_boosterMaxIdx to Max(l_boosterMaxIdx, boosterIdx).
                    set minIdx to Min(minIdx, boosterIdx).

                    if boosterObj:HasKey(boosterIdx)
                    {
                        boosterObj[boosterIdx]:DC:Add(dc).
                    }
                    else
                    {
                        boosterObj:Add(boosterIdx, lex("DC", list(dc), "ENG", list(), "AS", tagSpl:Contains("AS"))).
                        if tagSpl:Contains("AS") 
                        {
                            set g_BoosterAirStart to True.
                        }
                    }

                    for eng in dc:PartsTagged("")
                    {
                        if eng:IsType("Engine") and not g_PartInfo:Engines:SepRef:Contains(eng:Name)
                        {
                            boosterObj[boosterIdx]:ENG:Add(eng).
                        }
                    }
                }
            }
        }

        if boosterObj:Keys:Length > 0 
        {
            return list(true, CheckBoosterStagingConditions@:Bind(boosterObj):Bind(minIdx), StageBoosters@:Bind(boosterObj):Bind(minIdx)).
        }
        else
        {
            return list(false, { return True.}, { return False.}).
        }
    }


    // CheckBoosterStagingConditions
    //
    local function CheckBoosterStagingConditions
    {
        parameter _boostObj,
                  _boostIdx is 0.

        local aggThrust to 0.
        local flameoutCount to 0.
        for eng in _boostObj[_boostIdx]:ENG 
        {
            if eng:Flameout 
            {
                set flameoutCount to flameoutCount + 1.
            }
            else
            {
                set aggThrust to aggThrust + eng:Thrust.
            }
        }
        OutInfo("[{0}/{1}]: {2} ":Format(flameoutCount, _boostObj[_boostIdx]:ENG:Length, Round(aggThrust, 2))).
        return flameoutCount = _boostObj[_boostIdx]:ENG:Length.
    }

    // StageBoosters
    //
    local function StageBoosters
    {
        parameter _boostObj,
                  _boostIdx is 0.

        for eng in _boostObj[_boostIdx]:ENG
        { 
            if eng:AllowShutdown
            {
                eng:Shutdown.
            }
        } 
        for dc in _boostObj[_boostIdx]:DC { 
            for p in dc:PartsNamedPattern("sep|spin")
            {
                if p:IsType("Engine") p:Activate.
            }
            DoEvent(dc:GetModule("ModuleAnchoredDecoupler"), "Decouple").
        }
        _boostObj:Remove(_boostIdx).
        
        local bstCheckDel  to { return True.}.
        local bstActionDel to { return False.}.

        if _boostObj:Keys:Length > 0
        {
            from { local i to _boostIdx + 1. local doneFlag to false.} until doneFlag or i > l_boosterMaxIdx step { set i to i + 1.} do
            {
                if _boostObj:HasKey(i)
                {
                    set bstCheckDel to CheckBoosterStagingConditions@:Bind(_boostObj):Bind(i).
                    set bstActionDel to StageBoosters@:Bind(_boostObj):Bind(i).
                    if _boostObj[i]:AS
                    {
                        for eng in _boostObj[i]:ENG
                        {
                            eng:Activate.
                        }
                    }
                    else
                    {
                        set g_BoosterAirStart to False.
                    }
                    set doneFlag to true.
                }
            }
        }

        // OutInfo("UPDATING G_SHIPENGINES").
        set g_ShipEngines_Spec to GetShipEnginesSpecs().
        
        return list(_boostObj:Keys:Length > 0, bstCheckDel@, bstActionDel@).
    }

    // #endregion

// #endregion