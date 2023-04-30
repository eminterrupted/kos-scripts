@lazyGlobal off.

// *~ Dependencies ~* //
// #region
// #include "0:/lib/globals.ks"
// #include "0:/lib/util.ks"
// #include "0:/lib/disp.ks"
// #include "0:/lib/engines.ks"
    
// #endregion



// *~ Variables ~* //
// #region
    // *- Local
    // #region
    local stagingState to 0.
    local localTS to 0.
    // #endregion

    // *- Global (Adds new globals specific to this library, and updates existing globals)
    // #region
    
    // New entries in global objects
    
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
                
            }
        }

        // InitStagingDelegate :: 
        // Adds the proper staging check and action delegates to the g_LoopDelegates object
        global function InitStagingDelegate
        {
            parameter _actionType,
                      _conditionType.

            set g_LoopDelegates["Staging"] to lexicon(
                "Action", GetStagingActionDelegate(_actionType)  // #TODO: Write GetStagingActionDelegate
                ,"Check", GetStagingConditionDelegate(_conditionType)
            ).
        }

        global function ArmAutoStagingNext
        {
            parameter _stgLimit to g_StageLimit,
                      _stgCondition is 0, // 0: ThrustValue < 0.01
                      _stgAction is 0. // 1 is experimental ullage check, 0 is regular safestage.

            local resultCode to 0.
            set g_StageLimit to _stgLimit.
            if Stage:Number <= g_StageLimit 
            {
                set resultCode to 2.
            }
            else
            {
                InitStagingDelegate(_stgAction, _stgCondition).
            }
            return resultCode.
        }

        // ArmAutoStaging :: (_stgLimit)<type> -> (ResultCode)<scalar>
        // Arms automatic staging based on current thrust levels. If they fall below 0.1, we stage
        global function ArmAutoStaging
        {
            parameter _stgLimit to g_StageLimit,
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

                set g_LoopDelegates["Staging"] to lexicon(
                    "Check", selectedCondition
                    ,"Action", SafeStage@
                ).

                if g_LoopDelegates:HasKey("Staging") set resultCode to 1.
            }

            return resultCode.
        }

        // ArmFairingJettison :: (fairingTag) -> <none>
        global function ArmFairingJettison
        {
            parameter _fairingTag is "ascent".

            local jettison_alt to 100000.
            local fairing_tag_extended to "fairing|{0}":Format(_fairingTag).
            local fairing_tag_ext_regex to "fairing\|{0}":Format(_fairingTag).

            local op to choose "gt" if _fairingTag:MatchesPattern("(ascent|asc|launch)") else "lt".

            for p in ship:PartsTaggedPattern(fairing_tag_ext_regex)
            {
                if p:tag:MatchesPattern("{0}\|\d*":format(fairing_tag_ext_regex))
                {
                    set jettison_alt to ParseStringScalar(p:tag:replace("{0}|":format(fairing_tag_extended),"")).
                }
                if p:HasModule("ProceduralFairingDecoupler")
                {
                    if not g_LoopDelegates["Events"]:HasKey(fairing_tag_extended)
                    {
                        set g_LoopDelegates["Events"][fairing_tag_extended] to lexicon(
                            "Tag", _fairingTag
                            ,"Alt", jettison_alt
                            ,"Op", op
                            ,"Modules", list(p:GetModule("ProceduralFairingDecoupler"))
                        ).
                    }
                    else
                    {
                        g_LoopDelegates["Events"][fairing_tag_extended]["Modules"]:add(p:GetModule("ProceduralFairingDecoupler")).
                    }
                    if not g_LoopDelegates["Events"][fairing_tag_extended]:HasKey("Delegate")
                    {
                        set g_LoopDelegates["Events"][fairing_tag_extended]["Delegate"] to choose
                        { if ship:altitude > jettison_alt { for m in g_LoopDelegates["Events"][fairing_tag_extended]["Modules"] { DoEvent(m, "jettison fairing").}} g_LoopDelegates["Events"]:Remove(fairing_tag_extended).} if op = "gt" else
                        { if ship:altitude < jettison_alt { for m in g_LoopDelegates["Events"][fairing_tag_extended]["Modules"] { DoEvent(m, "jettison fairing").}} g_LoopDelegates["Events"]:Remove(fairing_tag_extended).}.
                    }
                }
            }
            return g_LoopDelegates["Events"]:HasKey(fairing_tag_extended).
        }

        // ArmHotStaging :: _stage<Int> -> staging_obj<Lexicon>
        // Writes events to g_LoopDelegates to fire hot staging if applicable for a given stage (next by default)
        global function ArmHotStaging
        {
            parameter _stage is Stage:Number - 1.

            local actionDel to {}.
            local checkDel to {}.
            local delKey to "HotStg_{0}":Format(_stage).
            local engine_list to list().

            if ship:status <> "PRELAUNCH"
            {
                for eng in ship:engines
                {
                    if eng:stage = _stage
                    {
                        if eng:tag:MatchesPattern("(HotStg|HotStage|HotStaging|HS)") 
                        {
                            engine_list:add(eng).   
                        }
                    }
                }
                if engine_list:Length > 0
                {
                    set g_LoopDelegates:Events[delKey]["Engines"] to engine_list.
                    set g_LoopDelegates:Events[delKey]["EngSpecs"] to GetEnginesSpecs(engine_list).
                    set checkDel to { return g_ActiveEngines_Data:BurnTimeRemaining <= g_LoopDelegates:Events[delKey]:EngSpecs:SpoolTime + 0.1.}.
                    set actionDel to 
                    { 
                        OutInfo("Hot Staging...").
                        for eng in g_LoopDelegates:Events[delKey]["Engines"] 
                        { 
                            if not eng:ignition eng:activate.
                        }

                        OutInfo("Building thrust in stage").
                        local NextEngines_Data to GetEnginesPerformanceData(g_LoopDelegates:Events[delKey]:Engines).
                        until NextEngines_Data:Thrust >= g_ActiveEngines_Data:Thrust
                        { 
                            set g_ActiveEngines_Data to GetEnginesPerformanceData(g_ActiveEngines).
                            set NextEngines_Data to GetEnginesPerformanceData(g_LoopDelegates:Events[delKey]:Engines).
                        } 
                        OutInfo("Staging...").
                        stage.
                        wait 1. 
                        OutInfo().
                        g_LoopDelegates:Events:Remove(delKey).
                    }.
                    set g_LoopDelegates:Events[delKey]["CheckDel"] to checkDel@.
                    set g_LoopDelegates:Events[delKey]["ActionDel"] to actionDel@.

                    return true.
                }
                else
                {
                    return false.
                }
            }
            else
            {
                return false.
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
                            set g_NextEngines_Spec to GetEngineSpecs(g_NextEngines).
                        }
                    }
                    SafeStageWithUllage().
                    // set g_ActiveEngines to GetActiveEngines(). 
                    set g_NextEngines to GetNextEngines().
                    set g_NextEngines_Spec to GetEnginesSpecs(g_NextEngines).
                }.

                return stageAction@.
            }
        }
        
        
        // GetStagingConditionDelegate :: (_checkType)<string> -> (Result)<kOSDelegate>   // TODO: Implement other check types here (only thrust value for now)
        // Given a staging check type string, performs that condition check and returns the result
        local function GetStagingConditionDelegate
        {
            parameter _checkType is 0.

            // if _checkType = 0 // Thrust Value: Ship:AvailableThrust < 0.01
            // {
                local condition to CheckShipThrustCondition@.
                local boundCondition to condition:Bind(Ship, 0.01).
                return boundCondition.
            // }
            // else if _checkType = 1
            // {

            // }
        }


        // CheckStageThrustCondition :: (_ves)<Vessel>, (_checkVal)Scalar -> <ResultCode>(Scalar)
        local function CheckShipThrustCondition
        {
            parameter _ves,
                      _checkVal.

            local resultCode to 0.
            if _ves:AvailableThrust < _checkVal
            {
                set resultCode to 1.
            }
            return resultCode.
        }

        local function SafeStage
        {
            wait until Stage:Ready.
            stage.
            wait 0.01.
            if g_HotStageArmed
            {
                set g_HotStageArmed to ArmHotStaging().
            }
        }


        // Checks for ullage before  staging
        local function SafeStageWithUllage
        {
            wait until Stage:Ready.
            // Ullage check. Skips if engine set doesn't require it.
            if g_NextEngines_Spec:Ullage
            {
                set g_TS to Time:Seconds + 3.
                local doneFlag to false.
                until doneFlag or Time:Seconds > g_TS
                {
                    set g_NextEngines_Spec to GetEnginesSpecs(g_NextEngines).
                    if g_NextEngines_Spec:FuelStabilityMin > 0.75 
                    {
                        set doneFlag to true.
                    }
                    else
                    {
                        OutInfo("Ullage Check (Fuel Stability Rating: {0})":Format(round(g_NextEngines_Spec:FuelStabilityMin, 5))).
                    }
                }
                if not doneFlag 
                {
                    OutInfo("Ullage check timeout").
                }
            }

            stage.
            wait 0.01.

            if g_HotStageArmed
            {
                set g_HotStageArmed to ArmHotStaging().
            }
        }


        // SafeStage :: <none> -> <none>
        // Performs a staging function after waiting for the stage to report it is ready first
        local function SafeStageState
        {
            local ullageDelegate to { return true. }.

            if stagingState = 0
            {
                wait until Stage:Ready.
                stage.
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
                unset ullageDelegate.
                return true.
            }
        }
        // #endregion
    // #endregion

    // ** Steering
    // #region

    global function GetOrbitalSteeringDelegate
    {
        // parameter _delDependency is lexicon().
        parameter _steerPair is "flat:sun".

        local del to {}.

        if _steerPair = "flat:sun"
        {
            set del to { set s_Val to Heading(compass_for(Ship, Ship:Prograde), 0, 0).}.
        }
        
        return del@.
    }

    global function SetSteering
    {
        parameter _altTurn.

        if Ship:Altitude >= _altTurn
        {
            set s_Val to Ship:SrfPrograde - r(0, 4, 0).
        } 
        else
        {
            set s_Val to Heading(90, 88, 0).
        }
    }
    // #endregion
// #endregion