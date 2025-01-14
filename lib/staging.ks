// #include "0:/lib/libLoader.ks"
// #include "0:/lib/dvCalc.ks"
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
    // local cachedAutoStageState to false.
    local l_stgDelayRegex to "(StageDelay|StgDly|SD|Dly)".
    local shipSysLex to Lexicon(
        "Staging", Lexicon(
            "Delay", lexicon(
                "Type", 0
                ,"Val", 0
                ,"Delegates", Lexicon(
                    "Check", list(
                         { parameter _params is list(). OutInfo("Stage Hold [T0]: SKIP", 1).return true.} // 0: No-op
                        ,{ parameter _params is list(). if _params:Length > 0 { local timerem to _params[0] - Time:Seconds.                                             OutInfo("Stage Hold [T1]: {0}       ":Format(TimeSpan(timerem):Full), 1). return timerem > 0.} else { return true.}} // 1: Time:   Check that UT has not exceeded the provided timestamp
                        ,{ parameter _params is list(). if _params:Length > 0 { local altThresh to _params[0]. local altDist to _params[0] - Ship:Altitude.             OutInfo("Stage Hold [T2]: {0} | {1} ":Format(altThresh, Round(altDist)), 1). return altThresh.} else { return true.}} // 2: Alt:    Wait until vessel reaches this alt
                        ,{ parameter _params is list(). if _params:Length > 0 { local apoThresh to _params[0] * _params[1]. local altDist to apoThresh - Ship:Altitude. local apoDist to apoThresh - Ship:Apoapsis. OutInfo("Stage Hold [T3]: {0} | {1} ":Format(apoThresh, Round(apoDist)), 1). return Ship:Altitude >= apoThresh.} else { return true.}} // 3: ApoPct: Wait until vessel reaches an altitude >= Apoapsis * this Pct
                    )
                    ,"Action", list(
                         { parameter _params is list(). OutInfo("", 1). return false.} // 0: No-op
                        ,{ parameter _params is list(). set g_AutoStageArmed to (Stage:Number > _params[0]). for p in _params:Parts { set p:Tag to "". OutInfo("", 1).} set shipSysLex:State to 3. return false.} // 1: Re-enable autostage
                        ,{ parameter _params is list(). set g_AutoStageArmed to (Stage:Number > _params[0]). for p in _params:Parts { set p:Tag to "". OutInfo("", 1).} set shipSysLex:State to 3. return false.} // 2: Alt:    Wait until vessel reaches this alt
                        ,{ parameter _params is list(). set g_AutoStageArmed to (Stage:Number > _params[0]). for p in _params:Parts { set p:Tag to "". OutInfo("", 1).} set shipSysLex:State to 3. return false.} // 3: ApoPct: Wait until vessel reaches an altitude >= Apoapsis * this Pct
                    )
                )
                ,"EstDuration", 0
                ,"Parts", Ship:PartsTaggedPattern(l_stgDelayRegex)
                ,"State", 0  // 0: Inactive, 1: Armed (In future stage), 2: Pending (In next stage), 3: Active (Currently holding), 4: Released (Delay is up, time to stage)
                ,"HoldStage", 0
                ,"RelStage",-1
            )
        )
    ).
    local stageDelayArmed to shipSysLex:Staging:Delay:Parts:Length > 0.
    
    local l_boosterMaxIdx to -1.
    local l_dVMaxStgIdx to 0.
    // #endregion

    // *- Global
    // #region
    global g_stageDelayActive to false.
    global g_stageDelayArmed to false.
    global g_stageAutoFlagCache to false.
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


        // ArmAutoStagingNext :: (_stgLimit)<scalar>, (_stgCondition)<scalar>, (_stgAction)<scalar> -> (ResultCode)<scalar>
        // Arms automatic staging based on current thrust levels. if they fall below 0.1, we stage
        global function ArmAutoStagingNext
        {
            parameter _stgLimit to g_StageLimit,
                      _stgCondition is 1, // 0: ThrustValue < 0.01
                      _stgAction is 1. // 1 is experimental ullage check, 0 is regular safestage.

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

                        set ExtraLeadTime to choose p:Tag:Split("|")[1]:ToNumber(0) if p:Tag:Split("|"):Length > 1 else choose p:Tag:Split(":")[1]:ToNumber(0) if p:Tag:Split(":"):Length > 1 else 0.
                        if not HotStageLeadTimes:HasKey(p:Stage)
                        {
                            HotStageLeadTimes:Add(p:Stage, ExtraLeadTime).
                        }
                        else if ExtraLeadTime > 0
                        {
                            set HotStageLeadTimes[p:Stage] to Max(HotStageLeadTimes[p:Stage], ExtraLeadTime).
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
                                // if g_RehydrateEngines_Flag
                                // {
                                set g_ActiveEngines to GetActiveEngines().
                                // }
                                if g_ActiveEngines:Length > 0
                                {
                                    local SpoolTime to (g_LoopDelegates:Staging:HotStaging[HotStageID]:EngSpecs:SpoolTime * 1.325) + ExtraLeadTime. 
                                    set stageEngines_BT to GetEnginesBurnTimeRemaining(g_ActiveEngines).
                                    // set stageEngines_BT to GetEnginesBurnTimeRemaining(GetActiveEngines(Ship, "NoBooster")).
                                    // set stageEngines_BT to g_ActiveEngines_Data:BurnTimeRemaining.
                                    set g_TR to stageEngines_BT - SpoolTime.
                                    OutInfo("HotStaging Armed: (ET: T-{0,6}s) ":Format(Round(g_TR, 2), 1)).

                                    return (g_TR < 0) or (g_ActiveEngines_Data:Thrust <= 0.1).
                                    // return (stageEngines_BT <= SpoolTime) or (g_ActiveEngines_Data:Thrust <= 0.1).
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
            set g_stageDelayArmed to SetupStageDelayHandler().

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
            parameter _checkType is 1,
                      _checkVal is 0.01.

            local condition to { parameter _params is list(). return true.}.

            if _checkType = 0 // Thrust Value: Ship:AvailableThrust < 0.01
            {
                // local condition to GetShipThrustConditionDelegate(Ship, _checkVal).
                // local boundCondition to condition:BIND(Ship, _checkVal).
                // return boundCondition.
                set condition to GetShipThrustConditionDelegate(Ship, _checkVal).
            }
            else if _checkType = 1
            {
                set condition to GetShipThrustConditionDelegate_Next(Ship, _checkVal).
            }
            return condition.
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
                if __ves:AvailableThrust < checkVal and throttle > 0 and Stage:Number > g_StageLimit
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

        // CheckStageThrustCondition :: (_ves)<Vessel>, (_checkVal)Scalar -> thrustDelegate (Delegate)
        local function GetShipThrustConditionDelegate_Next
        {
            parameter _ves,
                      _checkVal is 0.01.

            local conditionDelegate to { 
                parameter __ves is _ves, checkVal is _checkVal. 
                
                if g_AutoStageArmed
                {
                    if __ves:AvailableThrust < checkVal and throttle > 0 and Stage:Number > g_StageLimit
                    {
                        if stageDelayArmed
                        {
                            local stgDlyLex to shipSysLex:Staging:Delay:Copy().
                            if Stage:Number = stgDlyLex:HoldStage + 1
                            {
                                set stgDlyLex:State to 1.
                            }
                            else if Stage:Number <= stgDlyLex:HoldStage
                            {
                                set stgDlyLex:State to 2.
                                set g_stageDelayActive to True. 
                            }
                            else if Stage:Number <= stgDlyLex:
                            return 0.
                        }
                        return 1.
                        
                        // if stageDelayArmed
                        // {
                        //     local stageDelayObj to shipSysLex:Staging:Delay.

                        //     if stageDelayObj:State = 1
                        //     {
                        //         if Stage:Number <= stageDelayObj:HoldStage
                        //         {
                        //             // ArmStageDelay(stageDelayObj:Parts).
                        //             set g_stageDelayActive to ActivateStageDelay(stageDelayObj).
                        //             if g_stageDelayActive 
                        //             {
                        //                 set stageDelayObj:State to 2.
                        //             }
                        //         }
                        //     }
                        //     else if stageDelayObj:State >= 2 or g_stageDelayActive
                        //     {

                        //         if g_LoopDelegates:Events:HasKey("STGDLY")
                        //         {
                        //             if g_LoopDelegates:Events:STGDLY:Delegates:Check:Call(g_LoopDelegates:Events:STGDLY:Params)
                        //             {
                        //                 g_LoopDelegates:Events:STGDLY:Delegates:Action:Call(g_LoopDelegates:Events:STGDLY:Params).
                        //                 set g_stageDelayActive to False.
                        //                 set stageDelayArmed to False.
                        //                 return 1.
                        //             }
                        //         }
                        //     }
                        //     else
                        //     {
                        //         return 1.
                        //     }
                        // }
                        // else
                        // {
                        // }
                    }
                }
                else
                {
                    if g_stageDelayActive
                    {
                        if g_LoopDelegates:Events:HasKey("STGDLY")
                        {
                            if g_LoopDelegates:Events:STGDLY:Delegates:Check:Call(g_LoopDelegates:Events:STGDLY:Params)
                            {
                                g_LoopDelegates:Events:STGDLY:Delegates:Action:Call(g_LoopDelegates:Events:STGDLY:Params).
                                return 1.
                            }
                        }
                    }
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
                else if _engList_Spec:IsSolid
                {
                    OutInfo("Solid Motor").
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
                for dc in Ship:PartsTaggedPattern("Ascent\|Booster\|(AS\|)?{0}":Format(i:ToString))
                {
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
                            if eng:IsType("Engine") and not g_PartInfo:Engines:SepRef:Contains(eng:Name) and not g_PartInfo:Engines:VernRef:Contains(eng:Name)
                            {
                                boosterObj[boosterIdx]:ENG:Add(eng).
                            }
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
            return list(false, { return list(False, { return False.}, { return False.}).}, { return list(False, { return False.}, { return False.}).}).
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
            if dc:HasModule("ModuleAnchoredDecoupler") 
            {
                DoEvent(dc:GetModule("ModuleAnchoredDecoupler"), "Decouple").
            }
            else if dc:HasModule("ModuleDecouple")
            {
                DoEvent(dc:GetModule("ModuleDecouple"), "Decouple").
            }
        }
        _boostObj:Remove(_boostIdx).
        
        local bstCheckDel  to { return True.}.
        local bstActionDel to { return False.}.

        if _boostObj:Keys:Length > 0
        {
            // local i to l_boosterMaxIdx + 1.
            from { local i to _boostIdx + 0. local doneFlag to false.} until doneFlag or i > l_boosterMaxIdx step { set i to i + 1.} do
            {
                if _boostObj:HasKey(i)
                {
                    set bstCheckDel to CheckBoosterStagingConditions@:Bind(_boostObj):Bind(i).
                    set bstActionDel to StageBoosters@:Bind(_boostObj):Bind(i).
                    if _boostObj[i]:AS
                    {
                        for eng in _boostObj[i]:ENG
                        {
                            if not eng:Ignition eng:Activate.
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
        set g_ActiveEngines to GetActiveEngines().
        set g_ShipEngines_Spec to GetShipEnginesSpecs().
        
        return list(_boostObj:Keys:Length > 0, bstCheckDel@, bstActionDel@).
    }

    // #endregion

    // Delta-V based staging (stage when mnv dv remaining <= <n>)
    // #region

    // ArmDVStaging
    //
    global function ArmDVStaging
    {
        parameter _dvPartTag is "dvst(g|age|aging)\|(dv|stg)\|(-)*\d+".

        local dVObj to lex("DC", list(), "ENG", list()).
        local dVParts to Ship:PartsTaggedPattern(_dvPartTag).

        if dVParts:Length > 0 and HasNode
        {
            for checkStgIdx in Range(Stage:Number, g_StageLimit - 1, 1)
            {
                for p in dVParts
                {
                    if (p:IsType("Decoupler") and p:Stage >= checkStgIdx) or (p:DecoupledIn >= checkStgIdx)
                    {
                        local tagSpl to p:Tag:Replace(" ",""):Split("|").
                        
                        local dvRemainingAll to 0.
                        local dvRemainingStg to 0.
                        local dvStgParam        to tagSpl[tagSpl:Length - 1]:ToNumber(-1).
                        local dvStgType         to choose 1 if tagSpl[tagSpl:Length - 2] = "stg" else 0.
                        
                        if dvStgType = 0
                        {
                            if dvStgParam < 0
                            {
                                return list(false, g_NulCheckDel@, g_NulActionDel@).
                            }
                            set dvRemainingAll to dvStgParam.
                            set dvStgParam to choose p:Stage if p:IsType("Decoupler") else p:DecoupledIn.
                        }
                        else if dvStgType = 1
                        {
                            if dvStgParam < 0 
                            {
                                set dvStgParam to choose p:Stage if p:IsType("Decoupler") else p:DecoupledIn.
                            }
                            else if dvStgParam > Stage:Number 
                            {
                                return list(false, g_NulCheckDel@, g_NulActionDel@).
                            }
                            set dvRemainingStg to AvailStageDV(dvStgParam).
                            // set dvRemainingAll to dvRemainingAll + stgDv.
                            // set dvRemainingStg to choose stgDv if stgDv:STG:HasKey(dvStgParam) else 0.
                            // print "[ArmDVStaging] dvRemainingAll: [{0}]":Format(dvRemainingAll) at (2, 45).
                            print "[ArmDVStaging] dvRemainingStg: [{0}]":Format(dvRemainingStg) at (2, 46).
                        }
                        // local adjustedMnvDV to NextNode:DeltaV:Mag - dvRemainingStg.
                        local adjustedMnvDV to dvRemainingStg * 1.00525.

                        if p:IsType("Decoupler")
                        {
                            dvObj:DC:Add(p).
                        }
                        else if p:IsType("Engine")
                        {
                            dvObj:DC:Add(p:Decoupler).
                        }

                        for p_ in p:Decoupler:PartsNamedPattern("")
                        {
                            if p_:IsType("Engine")
                            {
                                dvObj:ENG:Add(p).
                            }
                        }
                        set dVObj to lex("TYPE", 1, "PARAM", dvStgParam, "MNVDV", adjustedMnvDV, "DC", dVObj:DC, "ENG", dvObj:ENG).
                        

                        local actionDel to DVStage@:Bind(dVObj).
                        local checkDel to CheckDVStagingConditions@:Bind(dVObj):Bind(dvStgParam).
                        
                        if not g_LoopDelegates:HasKey("Staging")
                        {
                            set g_LoopDelegates["Staging"] to lexicon().
                        }
                        else if g_LoopDelegates:Staging:HasKey("DVStaging")
                        {
                            g_LoopDelegates:Staging:Remove("DVStaging").
                        }
                        g_LoopDelegates:Staging:Add("DVStaging", lexicon("Obj", dvObj, "Check", checkDel, "Action", actionDel)).

                        return true.
                    }
                }
            }
        }
        return false.
    }

    // CheckDVStagingConditions
    //
    local function CheckDVStagingConditions
    {
        parameter _dvStgObj,
                  _checkStageIdx.

        if _checkStageIdx = Stage:Number - 1
        {
            if not HasNode
            {
                if g_LoopDelegates:HasKey("Staging")
                {
                    if g_LoopDelegates:Staging:HasKey("DVStaging")
                    {
                        g_LoopDelegates:Staging:Remove("DVStaging").
                    }
                }
                return true. // with the event object remove, this will no op if handled properly
            }

            local activeDVRemaining to NextNode:DeltaV:Mag.
            local result to _dvStgObj:MNVDV >= activeDVRemaining.
            
            print "[DVStaging] MNVDV Thresh: {0} ":Format(_dvStgObj:MNVDV) at (2, 50).
            print "[DVStaging] mnv node dv : {0} ":Format(Round(activeDVRemaining, 1)) at (2, 51).
            print "[DVStaging] dV Remaining: {0} ":Format(Round(activeDVRemaining - _dvStgObj:MNVDV, 1)) at (2, 52).
            return result.
        }
    }

    // StageDVs
    //
    local function DVStage
    {
        parameter _dvObj.

        for eng in _dvObj:ENG
        { 
            if eng:AllowShutdown
            {
                eng:Shutdown.
            }
        } 
        for dc in _dvObj:DC 
        { 
            for p in dc:PartsNamedPattern("sep|spin")
            {
                if p:IsType("Engine") p:Activate.
            }
            // DoEvent(dc:GetModule("ModuleAnchoredDecoupler"), "Decouple"). // Don't need this because autostaging should take care of things.
        }
        
        local bstCheckDel  to { return True.}.
        local bstActionDel to { return False.}.

        // OutInfo("UPDATING G_SHIPENGINES").
        //set g_ShipEngines_Spec to GetShipEnginesSpecs().
        
        return list(_dvObj:Keys:Length > 0, bstCheckDel@, bstActionDel@).
    }
    // #endregion

    // Stage delay - Wait time before next staging
    // #region
    

    // Currently works I think? But I don't like it >:(
    global function ArmStageDelay
    {
        parameter _stageDelayPart.
        
        local resultFlag to False.

        local stageDelayAlt to 0.
        local stageDelayPePct to 0.925.

        local stageDelay to 0.
        local stageDelayDefaultTime to 15.
        local stageDelayStr to stageDelayDefaultTime + "s".

        local stageDelayType to 0.  // 0: No/Op:  Improper tag 
                                    // 1: Time:   Wait this many seconds until next stage action
                                    // 2: Alt:    Wait until vessel reaches this alt
                                    // 3: ApoPct: Wait until vessel reaches an altitude >= Apoapsis * this Pct

        local stageDelayTag to _stageDelayPart:Tag:Split("|").    // "<(Ascent|MNV|Descent|Reentry|Landing)>|<(StageDelay|SD|StgDly|Delay|Dly)>|(\d*)<(s|m|%)>"

        local stageDelayPreStage to _stageDelayPart:Stage.
        local stageDelayTgtStage to stageDelayPreStage - 1.
        
        if stageDelayTag:Length > 2
        {
            set stageDelayStr to stageDelayTag[2].
        }
        
        if stageDelayStr:EndsWith("s") or stageDelayStr:EndsWith("\d")
        {
            set stageDelay to ParseStringScalar(stageDelayStr, stageDelayDefaultTime).
            set stageDelayType to 1.
        }
        else
        {
            if stageDelayStr:EndsWith("m")
            {
                set stageDelayAlt to ParseStringScalar(stageDelayStr, Min(Ship:Apoapsis, 150000)).
                set stageDelayType to 2.
            }
            else if stageDelayStr:EndsWith("%")
            {
                set stageDelayAlt to Ship:Apoapsis * ParseStringScalar(stageDelayStr, stageDelayPePct).
                set stageDelayType to 3.
            }
            
            if stageDelayType > 1 
            {
                local altDiff to stageDelayAlt - Ship:Altitude.
                local locGrav to GetLocalGravity(Ship:Body, Ship:Altitude + (altDiff / 2)).
                local vspd to Ship:VerticalSpeed.
                set stageDelay to (-vspd + Sqrt(vspd^2 + (2 * locGrav * altDiff))) / locGrav.
            }
        }
        
        if stageDelayType > 0
        {
            local stageDelayTS to Round(Time:Seconds + stageDelay, 2).
            set g_TS3 to stageDelayTS.

            set g_stageDelayActive to False.

            local paramList to list(
                stageDelayPreStage,
                stageDelayTgtStage,
                stageDelayType,
                stageDelayTS,
                stageDelayAlt
            ).
            
            // check del
            local checkDel to { 
                parameter _params is list(). 
                
                if Stage:Number <= _params[1]
                {
                    return true.
                }
                else if Stage:Number <= _params[0] // if Stage:Number <= _params[0] 
                {
                    if g_stageDelayActive
                    {
                        if _params[2] = 1
                        {
                            local timeLeft to _params[3] - Time:Seconds.
                            OutInfo("Type [{0}] | Tgt: [{1}] | Rem: [{2}]  ":Format(_params[2], _params[3], TimeSpan(timeLeft):Full), 1).
                            return timeLeft <= 0.
                        }
                        else if _params[2] = 2
                        {
                            if _params[4] > 0
                            {
                                local altLeft to Round(_params[4] - Ship:Altitude).
                                OutInfo("Type [{0}] | Tgt: [{1}] | Rem: [{2}]  ":Format(_params[2], _params[4], altLeft), 1).
                                return altLeft <= 0.
                            }
                            else
                            {
                                return true.
                            }
                        }
                        else if _params[2] = 3
                        {
                            if _params[4] > 0
                            {
                                local altLeft to Round(_params[4] - Ship:Altitude).
                                OutInfo("Type [{0}] | Tgt: [{1}] | Rem: [{2}]  ":Format(_params[2], _params[4], altLeft), 1).
                                return altLeft <= 0.
                            }
                            else
                            {
                                return true.
                            }
                        }
                        else
                        {
                            return true. // If we are unrecognized, pass through
                        }
                    }
                    else
                    {
                        OutInfo("[S{0}] Staging Delay Initiated ":Format(Stage:Number)).
                        set g_stageAutoFlagCache to g_AutoStageArmed.
                        set g_AutoStageArmed to False.
                        set g_stageDelayActive to True.
                    }
                }
                return false.
            }.

            // action del
            local actionDel to {
                parameter _params is list().

                if not g_AutoStageArmed
                {
                    if g_stageAutoFlagCache
                    {
                        if Stage:Number <= g_StageLimit
                        {
                            OutInfo("[S{0}] Stage Delay Cannot Resume, Stage Limit Met [{1}/{2}]":Format(_params[0], Stage:Number, g_StageLimit)).
                            OutInfo(" ", 2).
                        }
                        else
                        {
                            set g_AutoStageArmed to g_stageAutoFlagCache.
                            OutInfo("[S{0}] Staging Delay Exited ":Format(_params[0])).
                            OutInfo(" ", 2).
                        }
                    }
                }
                else
                {
                    OutInfo().
                    OutInfo(" ", 2).
                }

                set g_TS3 to 0.
                set g_stageDelayActive to false.
                set g_stageDelayArmed to false.

                return false.
            }.

            local stageDelayEvent to lexicon().
            local stageDelayEventID to "STGDLY".

            if not g_LoopDelegates:Events:HasKey(stageDelayEventID)
            {
                set stageDelayEvent to CreateLoopEvent(stageDelayEventID, "StageDelayEvent", paramList, checkDel@, actionDel@).
                set resultFlag to RegisterLoopEvent(stageDelayEvent).   
            }
        }

        return resultFlag.
    }


    global function SetupStageDelayHandler
    {
        parameter _partList is Ship:PartsTaggedPattern(l_stgDelayRegex).

        local result to false.

        local dlySecsToGo to 0.
        local dlyState to 0.
        local dlyType  to 0.
        local dlyValue to 0.
        local hldStg  to -1.
        local rlsStg   to -1.

        local stgDlyTimeDefault  to 11.25.
        local stgDlyAltDefault   to choose Min(g_MissionTag:Params[1], 150000) if g_MissionTag:HasKey("Params") else 150000.
        local stgDlyPePctDefault to 0.9125.

        // local pTagVal to list().

        if _partList:Length > 0
        {
            for p in _partList
            {
                if p:IsType("Decoupler") or p:IsType("Engine")
                {
                    set hldStg to Max(p:Stage + 1, hldStg).
                    set rlsStg  to Max(p:Stage, rlsStg).
                }
                else
                {
                    set hldStg to Max(p:DecoupledIn + 1, hldStg).
                    set rlsStg  to Max(p:DecoupledIn, rlsStg).
                }
                local pTagVal to p:Tag:Split("|")[2].
                

                if pTagVal:EndsWith("s") or pTagVal:EndsWith("\d")
                {
                    set dlyType to 1.
                    set dlyValue to ParseStringScalar(pTagVal, stgDlyTimeDefault).
                    // set dlySecsToGo to dlyValue.
                }
                else
                {
                    if pTagVal:EndsWith("m")
                    {
                        set dlyType to 2.
                        set dlyValue to ParseStringScalar(pTagVal, stgDlyAltDefault).
                    }
                    else if pTagVal:EndsWith("%")
                    {
                        set dlyType to 3.
                        set dlyValue to ParseStringScalar(pTagVal, stgDlyPePctDefault).
                    }   
                }
                set dlyState to 1.
            }

            if dlyValue > 0
            {
                local stgDlyLex to shipSysLex:Staging:Delay:Copy().

                set stgDlyLex:Type to dlyType.
                set stgDlyLex:Val to dlyValue.
                
                set stgDlyLex:HoldStage to hldStg.
                set stgDlyLex:RelStage to rlsStg.
                set stgDlyLex:State to dlyState.

                set shipSysLex:Staging:Delay to stgDlyLex.
                
                set result to true.
            }
        }
        return result.
    }
    
    // Maybe this will work better
    global function ActivateStageDelay
    {
        parameter _stageDelayLex is Lexicon().
        
        local resultFlag to False.

        // We have reached target hold stage and should commence the hold.
        local stageDelayType to _stageDelayLex:Type.    // 0: No/Op:  Improper tag 
                                                        // 1: Time:   Wait this many seconds until next stage action
                                                        // 2: Alt:    Wait until vessel reaches this alt
                                                        // 3: ApoPct: Wait until vessel reaches an altitude >= Apoapsis * this Pct

        local dlySecsToGo to 0.
        local dlyVal to _stageDelayLex:Val.
        local paramSet to list().
        local stageDelayEvent to lexicon().
        local stageDelayEventID to "STGDLY":Format(stageDelayType:ToString).

        if stageDelayType > 0
        {
            if stageDelayType = 1 // Timestamp
            {
                set dlySecsToGo to _stageDelayLex:Val.
                paramSet:Add(Round(Time:Seconds + Max(dlySecsToGo, 5)), 2).
            }
            else 
            {
                if stageDelayType = 2 // ApoPct
                {
                    paramSet:Add(dlyVal).
                }
                else if stageDelayType >= 3 
                {
                    paramSet:Add(g_MissionTag:PARAMS[1] * Max(0, Min(1.125, dlyVal))).
                }
                paramSet:Add(dlyVal).
                
                local altDiff to dlyVal - Ship:Altitude.
                local locGrav to GetLocalGravity(Ship:Body, Ship:Altitude + (altDiff / 2)).
                local vspd to Ship:VerticalSpeed.
                set dlySecsToGo to (vspd + Sqrt(vspd^2 + (2 * locGrav * altDiff))) / locGrav.
                set g_TS3 to dlySecsToGo + Time:Seconds.
            }

            set _stageDelayLex:EstDuration to dlySecsToGo.

            local actionDel to _stageDelayLex:Delegates:Action[Min(_stageDelayLex:Delegates:Action:Length - 1, Max(0, stageDelayType))].
            local checkDel  to _stageDelayLex:Delegates:Check[Min(_stageDelayLex:Delegates:Check:Length - 1, Max(0, stageDelayType))].
            
            if not g_LoopDelegates:Events:HasKey(stageDelayEventID)
            {
                set stageDelayEvent to CreateLoopEvent(stageDelayEventID, "StageDelayEvent", list(dlyVal), checkDel@, actionDel@).
                set resultFlag to RegisterLoopEvent(stageDelayEvent).   
            }
        }
        return resultFlag.
    }
    
    // #endregion

// #endregion