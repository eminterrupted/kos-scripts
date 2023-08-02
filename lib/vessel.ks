@LAZYGLOBAL off.

// *~ Dependencies ~* //
// #region
// #include "0:/lib/globals.ks"
// #include "0:/lib/util.ks"
// #include "0:/lib/disp.ks"
// #include "0:/lib/engines.ks"
// #include "0:/kslib/lib_l_az_calc.ks"
    
// #endregion



// *~ Variables ~* //
// #region
    // *- Local
    // #region
    local stagingState to 0.
    local localTS to 0.

    // Making copies of this object instead of specifying multiple times in code
    local boosterSetTemplate to lexicon(
        "DEC", lexicon(
            "PRT",  list()
            ,"MOD",  list()
        )
        ,"ENG", lexicon(
            "PRT", list()
            ,"THR", 0.0
            ,"TRP", 0.0
        )
        ,"CSR", lexicon(
            "RES", lexicon()
            ,"PCT", 0.0
            ,"MAS", 0.0
            ,"FLW", 0.0
            ,"FLX", 0.0
        )
        ,"BTR", 999999
    ).
    // #endregion

    // *- Global (Adds new globals specific to this library, and updates existing globals)
    // #region
    global g_UllageTS to -1.
    // New entries IN global objects
    set g_PartInfo["LES"] to list(
        "ROC-MercuryLESBDB"
    ).
    // #endregion
// #endregion



// *~ Functions ~* //
// #region

    // ** Staging
    // #region

        // -- Global
        // #region

        // StagingCheck :: (_program)<Scalar>, (_runmode)<Scalar>, (_checkType)<Scalar> -> (shouldStage)<Bool>
        global function StagingCheck
        {
            parameter _program,
                      _runmode,
                      _checkType is 0.

            if Stage:Number <= g_StageLimit
            {
                return false.
            }
            else
            {
                return TRUE.
            }
        }

        // InitStagingDelegate :: 
        // Adds the proper staging check and action delegates to the g_LoopDelegates object
        global function InitStagingDelegate
        {
            parameter _conditionType,
                      _actionType.

            set g_LoopDelegates["Staging"] to LEX(
                "Check", GetStagingConditionDelegate(_conditionType)
                ,"Action", GetStagingActionDelegate(_actionType)
            ).
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

                set g_LoopDelegates["Staging"] to LEX(
                    "Check", selectedCondition@
                    ,"Action", SafeStage@
                ).

                if g_LoopDelegates:HASKEY("Staging") set resultCode to 1.
            }

            return resultCode.
        }

        global function DisableAutoStaging
        {
            g_LoopDelegates:Remove("Staging").
        }

        // ArmHotStaging :: _stage<Int> -> staging_obj<Lexicon>
        // Writes events to g_LoopDelegates to fire hot staging if applicable FOR a given stage (next by default)
        global function ArmHotStaging
        {
            local ActionDel to {}.
            local CheckDel to {}.
            local Engine_Obj to LEX().
            local HotStage_List to Ship:PARTSTAGGEDPATTERN("(HotStg|HotStage|HS)").
            
            if HotStage_List:Length > 0
            {
                if not g_LoopDelegates:HASKEY("Staging")
                {
                    set g_LoopDelegates["Staging"] to LEX().
                }

                g_LoopDelegates:Staging:Add("HotStaging", LEX()).

                FOR p IN HotStage_List
                {
                    if p:isTYPE("Engine")
                    {
                        if Engine_Obj:HASKEY(p:Stage)
                        {
                            Engine_Obj[p:Stage]:ADD(p).
                        }
                        else
                        {
                            set Engine_Obj[p:Stage] to LisT(p).
                        }
                    }
                }
                
                FOR HotStageID IN Engine_Obj:KEYS
                {
                    OutInfo("Arming Hot Staging for Engine(s): {0}":Format(HotStageID)).
                    
                    // Set up the g_LoopDelegates object
                    g_LoopDelegates:Staging:HotStaging:ADD(HotStageID, LEX(
                        "Engines", Engine_Obj[HotStageID]
                        ,"EngSpecs", GetEnginesSpecs(Engine_Obj[HotStageID])
                        )
                    ).
                    local stageEngines to list().
                    local stageEngines_BT to 999999.

                    for eng in g_ActiveEngines
                    {
                        if eng:DecoupledIn >= HotStageID
                        {
                            stageEngines:Add(eng).
                        }
                    }

                    set checkDel  to {
                        set stageEngines_BT to GetEnginesBurnTimeRemaining(stageEngines).
                        if Stage:Number - 1 = HotStageID {
                            local SpoolTime to g_LoopDelegates:Staging:HotStaging[HotStageID]:EngSpecs:SpoolTime + 0.5. 
                            OutInfo("HotStaging Armed: (ET: T-{0,6}s) ":Format(round(stageEngines_BT - SpoolTime, 2), 1)).
                            return (stageEngines_BT <= SpoolTime) or (Ship:AvailableThrust <= 0.1).
                            // OutInfo("HotStaging Armed: (ETS: {0}s) ":Format(ROUND(g_ActiveEngines_Data:BurnTimeRemaining - g_LoopDelegates:Staging:HotStaging[HotStageID]:EngSpecs:SpoolTime + 0.25, 2)), 1).
                            // return (g_ActiveEngines_Data:BurnTimeRemaining <= g_LoopDelegates:Staging:HotStaging[HotStageID]:EngSpecs:SpoolTime + 0.25) or (Ship:AvailableThrust <= 0.1).
                        }
                        else
                        {
                            return false.
                        }
                    }.

                    set actionDel to { 
                        OutInfo("[{0}] Hot Staging Engines ({1})   ":Format(HotStageID, "Ignition")).
                        FOR eng IN g_LoopDelegates:Staging:HotStaging[HotStageID]:Engines
                        {
                            if not eng:Ignition { eng:Activate.}
                        }

                        OutInfo("[{0}] Hot Staging Engines ({1})   ":Format(HotStageID, "SpoolUp")).
                        set g_ActiveEngines_Data to GetEnginesPerformanceData(g_ActiveEngines).
                        local NextEngines_Data to GetEnginesPerformanceData(g_LoopDelegates:Staging:HotStaging[HotStageID]:Engines).
                        until NextEngines_Data:Thrust >= g_ActiveEngines_Data:Thrust
                        {
                            set s_Val                to g_LoopDelegates:Steering:CALL().
                            set g_ActiveEngines_Data to GetEnginesPerformanceData(g_ActiveEngines).
                            set NextEngines_Data     to GetEnginesPerformanceData(g_LoopDelegates:Staging:HotStaging[HotStageID]:Engines).
                            OutInfo("HotStaging Thrust Diff: Active [{0}] Staged [{1}]":Format(Round(g_ActiveEngines_Data:Thrust, 2), Round(NextEngines_Data:Thrust, 2)), 1).
                            wait 0.01.
                        }
                        OutInfo().
                        OutInfo("Staging").
                        wait until Stage:Ready.
                        Stage.
                        wait 0.5.
                        OutInfo().
                        OutInfo("", 1).
                        g_LoopDelegates:Staging:HotStaging:REMOVE(HotStageID).
                        if g_LoopDelegates:Staging:HotStaging:KEYS:Length = 0
                        {
                            g_LoopDelegates:Staging:Remove("HotStaging").
                            set g_HotStagingArmed to  false.
                        }
                        else
                        {
                            ArmHotStaging().
                        }
                    }.

                    // Add the delegates to the previously set up object
                    g_LoopDelegates:Staging:HotStaging[HotStageID]:ADD("Check", checkDel@).
                    g_LoopDelegates:Staging:HotStaging[HotStageID]:ADD("Action", actionDel@).
                }

                return True.
            }
            else
            {
                return False.
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
        
        
        // GetStagingConditionDelegate :: (_checkType)<string> -> (Result)<kOSDelegate>   // TODO: Implement other check types here (only thrust value FOR now)
        // Given a staging check type string, performs that condition check and returns the result
        local function GetStagingConditionDelegate
        {
            parameter _checkType is 0,
                      _checkVal is 0.01.

            // if _checkType = 0 // Thrust Value: Ship:AvailableThrust < 0.01
            // {
                local condition to GetShipThrustConditionDelegate(Ship, _checkVal).
                // local boundCondition to condition:BIND(Ship, 0.1).
                // return boundCondition.
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

            local conditionDelegate to { parameter __ves is _ves, checkVal is _checkVal. if __ves:AvailableThrust < checkVal and __ves:Status <> "PRELAUNCH" and throttle > 0 { return 1.} else {return 0.}}.
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

            // if Ship:PartsTaggedPattern("Spin\|"):Length > 0
            // {
            //     ArmSpinStabilization().
            // }
            // if g_HotStageArmed
            // {
            //     set g_HotStageArmed to ArmHotStaging().
            // }
        }


        // Simpler version of SafeStageWithUllage using new GetEngineFuelStability function
        local function SafeStageWithUllage2
        {
            local StageResult to false.
            local FuelStabilityMin to 0.98.

            set g_NextEngines to GetNextEngines().
            
            if g_NextEngines:Length > 0 
            {
                if g_NextEngines[0]:Stage < Stage:Number - 1 or not g_NextEngines[0]:Ullage
                {
                    set StageResult to true.
                }
                else
                {
                    local FuelStability to GetEngineFuelStability(g_NextEngines).
                    OutInfo("Fuel Stability Rating (Min/Avg): {0} / {1})":format(round(FuelStability[0], 2), round(FuelStability[1], 2))). 
                    
                    set StageResult to FuelStability[0] >= FuelStabilityMin. 
                }
            }

            if StageResult
            {
                local RCSResult to RCS. // Stores current RCS state
                set RCS to false. // Disables RCS just before staging in case the stage we drop had RCS ullage. We don't need that slamming back into us as we're building up thrust
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

        // Checks FOR ullage before staging
        local function SafeStageWithUllage
        {
            parameter _engList,
                      _engList_Spec is lexicon().

            // set g_NextEngines     to GetNextEngines().
            // set g_NextEngines_Spec to GetEnginesSpecs(g_NextEngines).

            local stageResult to false.
            
            if _engList_Spec:Keys:Length = 0
            {
                set _engList_Spec to GetEnginesSpecs(_engList).
            }
                        
            if _engList_Spec:HasKey("FuelStabilityMin")
            {
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
                set stageResult to true.
            }

            if stageResult
            {
                local rcsResult to RCS. // Stores current RCS state
                set RCS to false. // Disables RCS just before staging in case the stage we drop had RCS ullage. We don't need that slamming back into us as we're building up thrust
                wait until Stage:Ready.
                Stage.
                wait 0.01.
                set RCS to rcsResult. // Restores the RCS state to whatever it was before staging.
            }
            OutInfo().

            return stageResult.
        }


        // SafeStage :: <none> -> <none>
        // Performs a staging function after waiting FOR the stage to report it is ready first
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

    // Spin-stabilization
    // #region
    
    global function ArmSpinStabilization
    {
        local spinArmed to false.
        if g_ActiveEngines:Length > 0
        {
            local dc to g_ActiveEngines[0]:Decoupler.
            if dc:Tag:MatchesPattern("Spin\|")
            {
                local spinTime to dc:Tag:Replace("Spin|"):ToNumber(15).

                local checkDel to { parameter _params is list(). if params:length  = 0 { set _params to list(spinTime).} if g_ActiveEngines_Data:BurnTimeRemaining <= _params[0] { return 1.} else { return 0.}}.
                local actionDel to { if g_ActiveEngines_Data:BurnTimeRemaining > 0.25 { if Ship:Control:Roll = 0 { set Ship:Control:Roll to 1.} return true.} else { set Ship:Control:Roll to 0. return false.}}.

                local spinEventData to CreateLoopEvent("SpinStabilization", "Spin", list(15), checkDel@, actionDel@).
                set spinArmed to RegisterLoopEvent(spinEventData).
            }
        }

        return spinArmed.
    }
    // #endregion

    // ** Steering
    // #region

    global function GetSteeringError
    {
        parameter _type is "ang".

             if _type:MatchesPattern("ang")  return SteeringManager:AngleError.
        else if _type:matchesPattern("pit")  return SteeringManager:PitchError.
        else if _type:MatchesPattern("yaw")  return SteeringManager:YawError.
        else if _type:MatchesPattern("roll") return SteeringManager:RollError.
    }

    global function GetOrbitalSteeringDelegate
    {
        // parameter _delDependency is LEX().
        parameter _steerPair is "Flat:Sun",
                  _fShape    is 0.975.

        local del to {}.

        if g_AzData:Length = 0
        {
            set g_AzData to l_az_calc_init(g_MissionTag:Params[1], g_MissionTag:Params[0]).
        }
        if g_AngDependency:Keys:Length = 0
        {
            set g_AngDependency to InitAscentAng_Next(g_MissionTag:Params[0], g_MissionTag:Params[1], _fShape, 5, 22.5).
        }

        if _steerPair = "Flat:Sun"
        {
            set del to { return HEADING(compass_for(Ship, Ship:Prograde), 0, 0).}.
        }
        else if _steerPair = "AngErr:Sun"
        {
            RunOncePath("0:/lib/launch.ks").
            if g_Debug OutDebug("g_MissionTag:Params: {0}":Format(g_MissionTag:Params:Join(";"))).
            set del to GetAscentSteeringDelegate(g_MissionTag:Params[1], g_MissionTag:Params[0], g_AzData).
            // set del to { return HEADING(l_az_calc(g_azData), GetAscentAng_Next(g_AngDependency) * _fShape, 0).}.
        }
        else if _steerPair = "ApoErr:Sun"
        {
            RunOncePath("0:/lib/launch.ks").
            set del to { return HEADING(l_az_calc(g_azData), GetAscentAng_Next(g_AngDependency), 0).}.
        }
        else if _steerPair = "lazCalc:Sun"
        {
            set del to { return Ship:Facing.}.
        }
        
        return del@.
    }

    global function SetSteering
    {
        parameter _altTurn.

        if Ship:ALTITUDE >= _altTurn
        {
            set s_Val to Ship:SRFPROGRADE - r(0, 4, 0).
        } 
        else
        {
            set s_Val to HEADING(90, 88, 0).
        }
    }
    // #endregion

    // ** Side Boosters
    // #region
    global function ArmBoosterStaging
    {
        set g_BoosterObj to lexicon().

        local BoosterParts to Ship:PartsTaggedPattern("(^booster)+((\||\.)\d*)+").

        local setIdxList to UniqueSet().
        if BoosterParts:Length > 0
        {
            OutInfo("BoosterParts:Length > 0"). wait 1.
            for p in BoosterParts
            {
                local setIdx to p:Tag:Replace("booster",""):Replace("|",""):Replace(".",""):Replace("as",""):ToNumber(0).
                set g_BoosterObj[setIdx] to ProcessBoosterTree(p, setIdx, g_BoosterObj).
                setIdxList:Add(setIdx).
            }
            set g_BoostersArmed to true.
        }
        else 
        {
            OutInfo("BoosterParts:Length = 0"). wait 1.
            set g_BoostersArmed to false.
        }
        return g_BoostersArmed.
    }

    global function ArmBoosterStaging2
    {
        set g_BoosterObj to lexicon().

        local BoosterParts to Ship:PartsTaggedPattern("(^booster)+(\|\.)+(\d*)+").

        local setIdxList to UniqueSet().
        if BoosterParts:Length > 0
        {
            for p in BoosterParts
            {
                local setIdx to p:Tag:Replace("booster",""):Replace("|",""):Replace(".",""):Replace("as",""):ToNumber(0).
                set g_BoosterObj[setIdx] to ProcessBoosterTree(p, setIdx, g_BoosterObj).
                if setIdxList:Contains(setIdx)
                {
                }
                else 
                {
                    setIdxList:Add(setIdx).
                }
            }
            set g_BoostersArmed to true.
        }
        else 
        {
            set g_BoostersArmed to false.
        }
        return g_BoostersArmed.
    }


    local function GetBoosterUpdateDel
    {
        parameter _dc is Core:Part.

        local updateDel to { parameter _boosterObj is g_BoosterObj. return _boosterObj.}.

        if not (_dc = Core:Part)
        {
            local setIdx to _dc:Tag:Replace("booster",""):Replace("|",""):Replace("as",""):ToNumber(0).
            OutInfo("_dc: {0}":Format(_dc:name)).
            set updateDel to
            { 
                parameter _boosterObj is g_BoosterObj.

                if _boosterObj:HasKey(setIdx)
                { 
                    if _boosterObj[setIdx]:HasKey("ENG")
                    {
                        set _boosterObj[setIdx]["ENG"]:ALLTHRUST to 0.
                    }
                }
                //set _boosterObj to ProcessBoosterTree(_dc, setIdx, _boosterObj).
                local boosterEngs to list().
                for engObj in _boosterObj[setIdx]["ENG"]:Parts:Values
                {
                    boosterEngs:Add(engObj:P).
                }
                set _boosterObj[setIdx]["ENG"]:ALLTHRUST to GetThrustForEngines(boosterEngs).
                return _boosterObj.
            }.
        }
        else
        {
            OutInfo("_dc in GetBoosterUpdateDel is core:part!").
        }
        return updateDel@.
    }

    global function GetThrustForEngines
    {
        parameter _engList.

        local allThrust to 0.

        for eng in _engList
        {
            set allThrust to allThrust + eng:Thrust.
        }
        return allThrust.
    }



    // ArmBoosterStaging_Next :: <none> -> _resultFlag<bool>
    // Will attempt to arm auto-staging for boosters using like the 13th attempt at this. Apparently I suck at this.
    global function ArmBoosterStaging_Next
    {
        local primedBoosters    to Ship:PartsTaggedPattern("(^booster)(\||\.)\d+").
        local boosterIdxSet     to UniqueSet(). 
        if primedBoosters:Length > 0
        {
            for pb in primedBoosters
            {
                local pbSetIdx  to pb:Tag:Replace("booster",""):Replace("AS",""):Replace("|",""):Replace(".","").
                set   pbSetIdx  to pbSetIdx:ToNumber(0).
                boosterIdxSet:Add(pbSetIdx).

                set g_BoosterObj to InitBoosterSet(pbSetIdx, g_BoosterObj).
                set g_BoosterObj to HydrateBoosterSet(pbSetIdx, g_BoosterObj).
                

            }
        }

        
    }

    // InitBoosterSet :: (_setIdx<Scalar>), [_boosterObj<Lexicon>] -> _boosterObj<Lexicon>
    // Initiates a new object for a given set Scalar Idx, provided a set doesn't already exist with that Idx
    local function InitBoosterSet
    {
        parameter _setIdx,
                  _boosterObj is g_BoosterObj,
                  _force is False.

        if not _boosterObj:HasKey(_setIdx) or _force
        {
            set _boosterObj[_setIdx] to boosterSetTemplate:Copy.
        }

        return _boosterObj.
    }


    // HydrateBoosterSet :: (_setIdx<Scalar>), [_boosterObj<Lexicon>] -> _boosterObj<Lexicon>
    // Given a setIdx and boosterObj (usually g_BoosterObj), will hydrate the set
    local function HydrateBoosterSet
    {
        parameter _setIdx,
                  _boosterObj is g_BoosterObj.

        local setParts to Ship:PartsTaggedPattern("(^booster)((\||\.){0})":Format(_setIdx)).
        local setObj to lexicon().

        if _boosterObj:HasKey(_setIdx)
        {
            set setObj to _boosterObj[_setIdx].
        }
        else
        {
            set setObj to boosterSetTemplate:Copy.
        }
        
        for p in setParts
        {
            if p:IsType("Decoupler") 
            {
                set g_BoosterObj to ProcessBoosterSetDecoupler(p, _setIdx, g_BoosterObj).
            }
            else if p:IsType("Engine")
            {
                set g_BoosterObj to ProcessBoosterSetEngine(p, _setIdx, g_BoosterObj).
            }
        }
        set _boosterObj[_setIdx] to setObj.

        

        return _boosterObj.
    }


    local function ProcessBoosterSetDecoupler
    {

    }

    local function ProcessBoosterSetEngine
    {

    }


    // ProcessBoosterSetItem :: (_p<Part>), (_setIdx<Scalar>), [_boosterObj<Lexicon>] -> _boosterObj<Lexicon>
    // Given a part, attempts to set it as either a decoupler and then process that decoupler's engine(s), or as an engine and then processes the decoupler.
    local function ProcessBoosterSetItem
    {
        parameter _p,
                  _setIdx,
                  _boosterObj is g_BoosterObj.

        OutInfo("Processing Booster Item [{0}][{1}]":Format(_setIdx, _p:name)).
        
        local setObj to _boosterObj[_setIdx].
        
        //local dc to choose _p if _p:IsType("Decoupler") else _p:Decoupler.
        local dc  to _p:Decoupler.
        local eng to _p.
        local mdc to "".
        if _p:IsType("Decoupler")
        {
            set dc to _p.
            from { local i to 0.} until i = dc:Children:Length step { set i to i + 1.} do
            {
                if dc:Children[i]:IsType("Engine")
                {

                }
            }
        }
        

        set mdc to choose dc:GetModule("ModuleAnchoredDecoupler") if dc:HasModule("ModuleAnchoredDecoupler") else dc:GetModule("ModuleDecouple").

        if _boosterObj:HasKey(_setIdx)
        {
            set setObj to _boosterObj[_setIdx].
            if setObj:HasKey("DC")
            {
                if setObj:DC:HasKey("PRT")
                {
                    if setObj:DC:Parts:Contains(dc)
                    {
                    }
                    else
                    {
                        setObj:DC:Parts:Add(dc).
                        if setObj:DC:HasKey("MOD")
                        {
                            setObj:DC:Modules:Add(mdc).
                        }
                    }
                }
                else
                {
                    set setObj:DC["PRT"]   to list(dc).
                    set setObj:DC["MOD"] to list(mdc).
                }
            }
            else
            {
                set setObj["DC"] to lexicon(
                    "PRT",    list(dc)
                    ,"MOD", list(mdc)
                ).
            }

            set _boosterObj[_setIdx] to setObj.
        }

        return _boosterObj.
    }


    // GetBoosterResources :: (_item<part>), (_setObj<lexicon>) -> (_setObj<lexicon>)
    // Populates a lexicon with pointers to booster resources
    local function GetBoosterConsumedResources
    {
        parameter _eng,
                  _setIdx,
                  _boosterObj is g_BoosterObj.

        local _setObj to lexicon().

        if _boosterObj:HasKey(_setIdx) and _eng:IsType("Engine")
        {
            if _setObj:ENG:PRT:Contains(_eng)
            {
            }
            else
            {
                _setObj:ENG:PRT:Add(_eng).
                for res in _eng:ConsumedResources
                {
                    local processAmountsFlag to False.

                    if _setObj:CSR:Res:HasKey(res:Name)
                    {
                        if g_PropInfo:Solids:Contains(res:Name)
                        {
                            set processAmountsFlag to True.
                        }
                        else
                        {
                            set processAmountsFlag to False. 
                        }
                    }
                    else
                    {
                        set processAmountsFlag to True.
                    }

                    if processAmountsFlag
                    {
                        local resAmt  to res:Amount.
                        local resCap  to res:Capacity.
                        local resMass to resAmt * res:Density.
                        local resPct  to Round(resAmt / resCap, 4).

                        set _setObj:CSR:MAS to setResMass. 
                        set _setObj:CSR:FLW to setMassFlow.
                        set _setObj:CSR:FLX to setMaxMassFlow.
                        set _setObj:CSR:PCT to resPct.
                        
                        local engRemainingBurn to choose 0 if setResMass <= 0 or setMassFlow <= 0 else Round(setResMass / setMassFlow, 2).
                        set _setObj:BTR to Round((_setObj:BTR + engRemainingBurn) / _setObj:ENG:PRT:Length, 2).
                    }
                }
            }
        }

        return _setObj.
    }

    local function UpdateBoosterResources
    {
        parameter _item,
                  _setObj.

        local setResMass     to choose _setObj:CSR:MAS if _setObj:CSR:HasKey("MAS") else 0.
        local setMassFlow    to choose _setObj:CSR:FLW if _setObj:CSR:HasKey("FLW") else 0.
        local setMaxMassFlow to choose _setObj:CSR:FLX if _setObj:CSR:HasKey("FLX") else 0.

        if _item:IsType("Engine")
        {
            if _setObj:ENG:PRT:Contains(_item)
            {
            }
            else
            {
                _setObj:ENG:PRT:Add(_item).
                for res in _item:ConsumedResources
                {
                    local processFlag to False.

                    if _setObj:CSR:Res:HasKey(res:Name)
                    {
                        if g_PropInfo:Solids:Contains(res:Name)
                        {
                            set processFlag to True.
                        }
                        else
                        {
                            set processFlag to False. 
                        }
                    }
                    else
                    {
                        set processFlag to True.
                    }

                    if processFlag
                    {
                        local resAmt  to res:Amount.
                        local resCap  to res:Capacity.
                        local resMass to resAmt * res:Density.
                        local resPct  to Round(resAmt / resCap, 4).

                        set   setResMass     to setResMass       + resMass.
                        set   setMassFlow    to setMassFlow      + res:MassFlow.
                        set   setMaxMassFlow to setMaxMassFlow   + res:MaxMassFlow.
                        
                        set _setObj:CSR:MAS to setResMass. 
                        set _setObj:CSR:FLW to setMassFlow.
                        set _setObj:CSR:FLX to setMaxMassFlow.
                        set _setObj:CSR:PCT to resPct.
                        
                        local engRemainingBurn to choose 0 if setResMass <= 0 or setMassFlow <= 0 else Round(setResMass / setMassFlow, 2).
                        set _setObj:BTR to Round((_setObj:BTR + engRemainingBurn) / _setObj:ENG:PRT:Length, 2).
                    }
                }
            }
        }

        return _setObj.
    }



    local function ProcessBoosterTree
    {
        parameter _p,
                _setIdx,
                _boosterObj.

        OutInfo("Processing booster tree for part: {0} ({1})":Format(_p:name, _p:UID), 1).

        local dc to choose _p if _p:IsType("Decoupler") else _p:Decoupler.
        local m to choose dc:GetModule("ModuleAnchoredDecoupler") if dc:HasModule("ModuleAnchoredDecoupler") else dc:GetModule("ModuleDecouple").
        local event to "decouple".

        // for _e in m:AllEvents
        // {
        //     if _e:MatchesPattern("\(callable\).*decouple.*is KSPEvent")
        //     {
        //         set event to _e:Replace("(callable) ",""):Replace(", is KSPEvent","").
        //     }
        // }
        
        // This resets the lex for each loop
        if not _boosterObj:HasKey(_setIdx)
        {
            set _boosterObj[_setIdx] to lexicon(
                "DC", lex(
                    dc:UID, lex(
                        "P", dc
                        ,"M", m
                        ,"E", event
                        ,"S", dc:Stage
                    )
                )
                ,"UPDATE", GetBoosterUpdateDel(dc)
            ).
        }
        else
        {
            if not _boosterObj[_setIdx]:HasKey("DC")
            {
                set _boosterObj[_setIdx]["DC"] to lexicon().
            }
            
            set _boosterObj[_setIdx]["DC"][dc:UID] to lexicon(
                "P", dc
                ,"M", m
                ,"E", event
                ,"S", dc:Stage
            ).

            if not _boosterObj[_setIdx]:HasKey("UPDATE")
            {
                set _boosterObj[_setIdx]["UPDATE"] to GetBoosterUpdateDel(dc).
            }
        }
        
        // Check to see if we need to airstart this booster set
        local as to false.
        if _p:Tag:Split("|"):Length > 2
        {
            if _p:Tag:Split("|")[1] = "as"
            {
                set as to true.
            }
        } 
        else if _p:Tag:Split("."):Length > 2
        {
            if _p:Tag:Split(".")[1] = "as" 
            {
                set as to true.
            }
        }
        set _boosterObj[_setIdx]["AS"] to as.


        for child in dc:Children
        {
            set _boosterObj to ProcessBoosterChildren(child, _setIdx, _boosterObj).
        }
        // if _boosterObj[setIdx]["RES"]:HasSuffix("AMOUNT")
        // {
        //     set _boosterObj[setIdx]["RES"]["PCTLEFT"] to Round(_boosterObj[setIdx]["RES"]:AMOUNT / _boosterObj[setIdx]["RES"]:CAPACITY, 5).
        // }
        // else
        // {
        //     set _boosterObj[setIdx]["RES"]["PCTLEFT"] to 1.
        // }

        return _boosterObj.
    }

    local function ProcessBoosterChildren
    {
        parameter _p,
                _setIdx,
                _boosterObj.

        // OutInfo("Processing Child for (Set): [{0}] ({1})":Format(_p:Name, _setIdx), 1).

        local _bcObj to _boosterObj.
        if not _p:HasModule("ProceduralFairingDecoupler")
        {
            if _p:IsType("Engine")
            {
                set _bcObj to ProcessBoosterEngine(_p, _setIdx, _bcObj).
            }
            
            if _p:HasModule("ModuleFuelTank")
            {
                set _bcObj to ProcessBoosterTank(_p, _setIdx, _bcObj).
            }
            
            if _p:Children:Length > 0
            {
                for _child in _p:Children
                {
                    set _bcObj to ProcessBoosterChildren(_child, _setIdx, _bcObj).
                }
            }
        }
        
        return _bcObj.
    }

    local function ProcessBoosterEngine
    {
        parameter _p,
                _setIdx,
                _boosterObj.

        // OutInfo("Processing Engine: [{0}]":Format(_p:Name), 1).

        local _beObj to _boosterObj.
        
        if not _beObj[_setIdx]:HasKey("ENG")
        {
            set _beObj[_setIdx]["ENG"] to lexicon(
                "ALLTHRUST", 0
                ,"AVLTHRUST", 0
                ,"PCTTHRUST", 0
                ,"PARTS", lex()
            ).
        }
        if not _beObj[_setIdx]:HasKey("SEP")
        {
            set _beObj[_setIdx]["SEP"] to lexicon().
        }

        if g_PartInfo:Engines:SEPREF:Contains(_p:Name) and _p:Tag:Length = 0
        {
            set _beObj[_setIdx]["SEP"][_p:UID] to _p.
        }
        else
        {
            local curThr  to _p:Thrust.
            local avlThr  to _p:AvailableThrustAt(Body:Atm:AltitudePressure(Ship:Altitude)).

            set _beObj[_setIdx]["ENG"]["PARTS"][_p:UID] to lexicon(
                "P", _p
                ,"M", _p:GetModule("ModuleEnginesRF")
                ,"S", _p:Stage
                ,"T", _p:Config
            ).
            set _beObj[_setIdx]["ENG"]:ALLTHRUST to _beObj[_setIdx]["ENG"]:ALLTHRUST + curThr.
            set _beObj[_setIdx]["ENG"]:AVLTHRUST to _beObj[_setIdx]["ENG"]:AVLTHRUST + avlThr.
            // set _beObj[_setIdx]["ENG"]:PCTTHRUST to Round(max(_beObj[_setIdx]["ENG"]:ALLTHRUST, 0.00000001) / max(_beObj[_setIdx]["ENG"]:AVLTHRUST, 0.0001), 4).
        }

        return _beObj.
    }

    local function ProcessBoosterTank
    {
        parameter _p,
                _setIdx,
                _boosterObj.

        // OutInfo("Processing Tank: [{0}]":Format(_p:Name), 1).

        local _btObj to _boosterObj.
        if not _btObj[_setIdx]:HasKey("TANK")
        {
            set _btObj[_setIdx]["TANK"] to lexicon().
        }

        set _btObj[_setIdx]["TANK"][_p:UID] to lexicon(
            "P", _p
            ,"M", _p:GetModule("ModuleFuelTank")
        ).
        set _btObj to ProcessBoosterTankResources(_p, _btObj).

        return _btObj.
    }

    local function ProcessBoosterTankResources
    {
        parameter _p,
                _setIdx,
                _boosterObj.

        local _brObj to _boosterObj.

        if not _brObj[_setIdx]:HasKey("RES")
        {
            set _brObj[_setIdx]["RES"] to lexicon(
                "AMOUNT", 0
                ,"CAPACITY", 0
                ,"RESLisT", list()
            ).
        }

        for _res in _p:Resources
        {
            _brObj[_setIdx]["RES"][_res:Name]:RESLisT:Add(_res).
            set _brObj[_setIdx]["RES"][_res:Name]:AMOUNT to Round(_brObj[_setIdx]["RES"][_res:Name]:AMOUNT + _res:Amount, 5).
            set _brObj[_setIdx]["RES"][_res:Name]:CAPACITY to Round(_brObj[_setIdx]["RES"][_res:Name]:CAPACITY + _res:Capacity, 5).
        }
        return _brObj.
    }

    global function CheckBoosterStageCondition
    {
        parameter _pctThresh to 0.0625.

        if g_BoostersArmed 
        {
            // writeJson(g_BoosterObj, "0:/data/g_boosterobj.json").
            OutInfo("[{0,-7}]Boosters: [Armed(X)] [Set( )] [Update( )] [Cond( )]":Format(g_Counter)).
            if g_BoosterObj:Keys:Length > 0
            {
                OutInfo("[{0,-7}]Boosters: [Armed(X)] [Set(X)] [Update( )] [Cond( )]":Format(g_Counter)).
                local doneFlag to false.
                local ThrustThresh to 0.
                print g_BoosterObj:Keys at (2, 48).
                print g_BoosterObj[0] at (2, 50).
                from { local i to 0.} until i = g_BoosterObj:Keys:Length or doneFlag step { set i to i + 1.} do
                {
                    local bSet to g_BoosterObj:Values[i].
                    if not g_BoosterObj:Keys[i] = "UPDATE"
                    {
                        // local bSet to g_BoosterObj[g_BoosterObj:Keys[i]].
                        if bSet:HasKey("UPDATE") 
                        {
                            OutInfo("[{0,-7}]Boosters: [Armed(X)] [Set(X)] [Update(X)] [Cond( )]":Format(g_Counter)).
                            set g_BoosterObj to bSet:UPDATE:Call().
                            wait 0.01.
                            // writeJson(g_BoosterObj, Path("0:/data/g_BoosterObj.json")).
                            // local check to bSet["RES"]["PCTLEFT"] <= _pctThresh.
                            // OutInfo("BoosterStageCondition: {0} ({1})":Format(check, bSet["RES"]["PCTLEFT"]), 2).
                            // if bSet["RES"]["PCTLEFT"] <= _pctThresh
                            // if bSet["ENG"]:Values[0]:P:Thrust < 0.1
                            local bSetKey to bSet:Keys[i].
                            local engPresent to bSet:HasKey("Eng").
                            local allPresent to choose bSet["ENG"]:HasKey("AllThrust") if engPresent else false.
                            local avlPresent to choose bSet["ENG"]:HasKey("AvlThrust") if engPresent else false.

                            print "KEY [{0}] | ENG [{1}] | ALL [{2}] | AVL [{3}]":Format(bsetKey, engPresent, allPresent, avlPresent) at (0, 35).
                            set ThrustThresh to Max(ThrustThresh, bSet["ENG"]:AVLTHRUST * _pctThresh).
                            OutInfo("THRUST: {0} ({1})":Format(Round(bSet["ENG"]:ALLTHRUST, 2), Round(ThrustThresh, 2)), 1).
                            if bSet["ENG"]:ALLTHRUST < ThrustThresh
                            {
                                OutInfo("[{0,-7}]Boosters: [Armed(X)] [Set(X)] [Update(X)] [Cond(X)]":Format(g_Counter)).
                                StageBoosterSet(i).
                                // set bSet to "".
                                wait 0.025.
                                g_BoosterObj:Remove(i).
                                wait 0.01.
                                
                                if g_BoosterObj:Keys:Length < 1
                                {
                                    set g_BoostersArmed to false.
                                }
                                else
                                {
                                    
                                }
                                set doneFlag to true.
                            }
                            else
                            {
                                OutInfo("[{0,-7}]Boosters: [Armed(X)] [Set(X)] [Update(X)] [Cond(-)]":Format(g_Counter)).
                            }
                        }
                        else
                        {
                            OutInfo("[{0,-7}]Boosters: [Armed(X)] [Set(X)] [Update(-)] [Cond( )]":Format(g_Counter)).
                        }
                    }
                }
            }
            else
            {
                OutInfo("Boosters disarmed").
                set g_BoostersArmed to false.
            }
        }
    }

    local function StageBoosterSet
    {
        parameter _setIdx.

        if g_BoosterObj:HasKey(_setIdx)
        {
            // local stgSet to g_BoosterObj[_setIdx].
        
            for eng in g_BoosterObj[_setIdx]["ENG"]:Parts:Values
            {
                if eng:P:Ignition and not eng:P:Flameout
                {
                    eng:P:Shutdown.
                }
            }
            wait 0.01.
            for sep in g_BoosterObj[_setIdx]["SEP"]:Values
            {
                DoEvent(sep:GetModule("ModuleEnginesRF"), "activate engine").
                wait 0.01.
            }
            wait 0.01.
            for dc in g_BoosterObj[_setIdx]["DC"]:Keys
            {
                DoEvent(g_BoosterObj[_setIdx]["DC"][dc]:M, g_BoosterObj[_setIdx]["DC"][dc]:E).
            }
            wait 0.01.

            // Check for AirStarts in the next booster set if present
            if g_BoosterObj:HasKey(_setIdx + 1)
            {
                if g_BoosterObj[_setIdx + 1]:AS
                {
                    for eng in g_BoosterObj[_setIdx + 1]["ENG"]:Parts:Values
                    {
                        if not eng:P:Ignition
                        {
                            eng:P:Activate.
                        }
                    }
                }
            }
            wait 0.01.
            // wait until Stage:Ready.
            // Stage.
            return true.
        }
        else
        {
            return false.
        }
        
    }

    local function CheckBoosterStaging_Old
    {
        parameter _boosterIdx is 0.
                
        local booster_index to _boosterIdx.
        set curBoosterTag   to "booster.{0}":Format(booster_index).
        local boosterParts  to Ship:PartsTagged(curBoosterTag).
        if boosterParts:Length > 0
        {
            set cb to boosterParts[0]. // cb = CheckBooster
            if cb:IsType("Decoupler")
            {

            }
            else if cb:IsType("Engine")
            {
                if cb:Thrust <= 0.0001
                {
                    for i in Range (0, cb:SymmetryCount - 1, 1)
                    {
                        cb:SymmetryPartner(i):Shutdown.
                    }
                    wait until Stage:Ready.
                    stage.
                    wait 0.01.
                
                    if Ship:PartsTaggedPattern("booster.\d*"):Length < 1
                    {
                        set boostersArmed to false.
                    }
                    else
                    {
                        set booster_index to booster_index + 1.
                    }
                }
            }
        }
        return booster_index.
    }

    // #endregion

    // ** Fairings
    // #region
    // ArmFairingJettison :: (fairingTag) -> <none>
        global function ArmFairingJettison
        {
            parameter _fairingTag is "ascent".

            local jettison_alt to 100000.
            local fairing_tag_ext_regex to "fairing\|{0}":Format(_fairingTag).

            local op to choose "gt" if _fairingTag:MATCHESPATTERN("(ascent|asc|launch)") else "lt".
            local result to false.

            local fairingSet to Ship:PartsTaggedPattern(fairing_tag_ext_regex).
            if fairingSet:Length > 0
            {
                set jettison_alt to choose jettison_alt if fairingSet[0]:Tag:Split("|"):Length < 3 else ParseStringScalar(fairingSet[0]:Tag:Split("|")[2]).

                local checkDel to choose { 
                    parameter _params to list(). return Ship:Altitude > _params[0].
                } 
                if op = "gt" else
                { 
                    parameter _params to list(). return Ship:Altitude < _params[0].
                }.

                local actionDel to {
                    parameter _params is list().
                    
                    JettisonFairings(_params[1]).
                    OutInfo("Fairing jettison").
                    return false.
                }.

                local fairingEvent to CreateLoopEvent("Fairings", "CheckAction", list(jettison_alt, fairingSet), checkDel@, actionDel@). 
                set result to RegisterLoopEvent(fairingEvent).
            }
            return result.
        }

        // JettisonFairings :: _fairings<list> -> <none>
        // Will jettison fairings provided
        global function JettisonFairings
        {
            parameter _fairings is LisT().

            if _fairings:Length > 0
            {
                FOR f IN _fairings
                {
                    if f:isTYPE("Part") { set f to f:GETMODULE("ProceduralFairingDecoupler"). }
                    DoEvent(f, "jettison fairing").
                }
            }
        }
    // #endregion

    // ** LES Tower
    // #region

        // ArmLESTower :: <none> -> Armed<bool>
        // Creates an event for LES functionality which performs the following two functions
        // 1. Activate the engine and decouple the capsule if the Abort group is activated. Yes, I know this is an action in a check. But I don't want to do two events for this.
        // 2. Jettisons the LES tower at a certain speed above which it would no longer be useful
        global function ArmLESTower
        {
            local AbortDCModuleList to list().
            local AbortParts to Ship:PartsTaggedPattern("Abort").
            local LES to "".

            if abortParts:Length > 0
            {
                for p in abortParts
                {
                    if p:IsType("Decoupler")
                    {
                        if p:HasModule("ModuleDecouple")
                        {
                            AbortDCModuleList:Add(p:GetModule("ModuleDecouple")).
                        }
                        else if p:HasModule("ModuleAnchoredDecoupler")
                        {
                            AbortDCModuleList:Add(p:GetModule("ModuleAnchoredDecoupler")).
                        }
                    }
                }
            }

            for p in ship:engines
            {
                if g_PartInfo:LES:Contains(p:name)
                {
                    set LES to p.
                }
            }

            if LES:IsType("String")
            {
                return false.
            }
            else
            {
                local checkDel to {
                    parameter _params is list().

                    if Abort or Ship:Altitude >= 100000 or Ship:Velocity:Surface:Mag > 2025
                    {
                        return true.
                    }
                    else
                    {
                        return false.
                    }
                }.
                
                local actionDel to {
                    parameter _params is list().

                    _params[0]:Activate.
                    wait 0.01.

                    if Abort
                    {
                        // TODO: Send range safety event to listener core
                        if g_DualCore
                        {
                            // Send the signal with time delay param here I guess
                        }

                        for m in _params[1]
                        {
                            if not DoEvent(m, "Decouple")
                            {
                                DoAction(m, "Decouple", true).
                            }
                        }
                        OutMsg("*** ABORT ***", 2).
                        Breakpoint().
                        ThrowException().
                    }
                    else
                    {
                        local m to _params[0]:GetModule("ModuleDecouple").
                        if not DoEvent(m, "Decouple")
                        {
                            DoAction(m, "Decouple", true).
                        }
                        OutMsg("LES Tower Jettison").
                    }
                    return false.
                }.
                
                local lesEvent to CreateLoopEvent("LES", "event", list(LES, AbortDCModuleList), checkDel@, actionDel@).
                return RegisterLoopEvent(lesEvent).
            }
        }
    // #endregion

    // ** Solar Panels
    // #region

    // ExtendSolarPanels :: _panelList<Module> -> <none>
    // Given a list of ModuleROSolar items, extends any panels that have the event available
    global function ExtendSolarPanels
    {
        parameter _panelList is Ship:ModulesNamed("ModuleROSolar").

        for m in _panelList
        {
            DoAction(m, "extend solar panel", true).
        }
    }
    // #endregion

// #endregion