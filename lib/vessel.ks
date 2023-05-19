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
    LOCAL stagingState TO 0.
    LOCAL localTS TO 0.
    // #endregion

    // *- Global (Adds new globals specific TO this library, and updates existing globals)
    // #region
    global g_UllageTS to -1.
    // New entries IN global objects
    
    // #endregion
// #endregion



// *~ Functions ~* //
// #region

    // ** Staging
    // #region

        // -- Global
        // #region

        // StagingCheck :: (_program)<Scalar>, (_runmode)<Scalar>, (_checkType)<Scalar> -> (shouldStage)<Bool>
        GLOBAL FUNCTION StagingCheck
        {
            PARAMETER _program,
                      _runmode,
                      _checkType IS 0.

            IF STAGE:NUMBER <= g_StageLimit
            {
                RETURN false.
            }
            ELSE
            {
                RETURN TRUE.
            }
        }

        // InitStagingDelegate :: 
        // Adds the proper staging check and action delegates TO the g_LoopDelegates object
        GLOBAL FUNCTION InitStagingDelegate
        {
            PARAMETER _actionType,
                      _conditionType.

            SET g_LoopDelegates["Staging"] TO LEX(
                "Action", GetStagingActionDelegate(_actionType)  // #TODO: Write GetStagingActionDelegate
                ,"Check", GetStagingConditionDelegate(_conditionType)
            ).
        }

        GLOBAL FUNCTION ArmAutoStagingNext
        {
            PARAMETER _stgLimit TO g_StageLimit,
                      _stgCondition IS 0, // 0: ThrustValue < 0.01
                      _stgAction IS 0. // 1 IS experimental ullage check, 0 IS regular safestage.

            LOCAL resultCode TO 0.
            SET g_StageLimit TO _stgLimit.
            IF STAGE:NUMBER <= g_StageLimit 
            {
                SET resultCode TO 2.
            }
            ELSE
            {
                InitStagingDelegate(_stgAction, _stgCondition).
            }
            RETURN resultCode.
        }

        // ArmAutoStaging :: (_stgLimit)<type> -> (ResultCode)<scalar>
        // Arms automatic staging based on current thrust levels. IF they fall below 0.1, we stage
        GLOBAL FUNCTION ArmAutoStaging
        {
            PARAMETER _stgLimit TO g_StageLimit,
                      _stgCondition IS 0. // 0: ThrustValue < 0.01

            LOCAL resultCode TO 0.
            SET g_StageLimit TO _stgLimit.
            IF STAGE:NUMBER <= g_StageLimit 
            {
                SET resultCode TO 2.
            }
            ELSE
            {
                LOCAL selectedCondition TO GetStagingConditionDelegate(_stgCondition). 

                SET g_LoopDelegates["Staging"] TO LEX(
                    "Check", selectedCondition
                    ,"Action", SafeStage@
                ).

                IF g_LoopDelegates:HASKEY("Staging") SET resultCode TO 1.
            }

            RETURN resultCode.
        }

        GLOBAL FUNCTION DisableAutoStaging
        {
            g_LoopDelegates:Remove("Staging").
        }


        // ArmFairingJettison :: (fairingTag) -> <none>
        GLOBAL FUNCTION ArmFairingJettison
        {
            PARAMETER _fairingTag IS "ascent".

            LOCAL jettison_alt TO 100000.
            LOCAL fairing_tag_extended TO "fairing|{0}":FORMAT(_fairingTag).
            LOCAL fairing_tag_ext_regex TO "fairing\|{0}":FORMAT(_fairingTag).

            LOCAL op TO choose "gt" IF _fairingTag:MATCHESPATTERN("(ascent|asc|launch)") ELSE "lt".
            local result to false.

            OutDebug("AFJ: Line 136").

            local fairingSet to Ship:PartsTaggedPattern(fairing_tag_ext_regex).
            if fairingSet:Length > 0
            {
                set jettison_alt to choose jettison_alt if fairingSet[0]:Tag:Split("|"):Length < 3 else ParseStringScalar(fairingSet[0]:Tag:Split("|")[2]).

                local checkDel to choose { 
                    parameter _params to list(). return Ship:Altitude > _params[0].
                } 
                if op = "gt" ELSE
                { 
                    parameter _params to list(). return Ship:Altitude < _params[0].
                }.

                local actionDel to {
                    parameter _params is list().
                    
                    JettisonFairings(_params[1]).
                    OutDebug("Fairing action performed").
                    return false.
                }.

                local fairingEvent to CreateLoopEvent("Fairings", "CheckAction", list(jettison_alt, fairingSet), checkDel@, actionDel@). 
                set result to RegisterLoopEvent(fairingEvent).
            }
            return result.
        }

            
        //     FOR p IN SHIP:PARTSTAGGEDPATTERN(fairing_tag_ext_regex)
        //     {
        //         OutDebug("AFJ: Line 139").
        //         IF p:TAG:MATCHESPATTERN("{0}\|\d*":FORMAT(fairing_tag_ext_regex))
        //         {
        //             OutDebug("AFJ: Line 142").
        //             SET jettison_alt TO ParseStringScalar(p:TAG:REPLACE("{0}|":FORMAT(fairing_tag_extended),"")).
        //         }
        //         IF p:HASMODULE("ProceduralFairingDecoupler")
        //         {
        //             OutDebug("AFJ: Line 147").
        //             IF not g_LoopDelegates["Events"]:HASKEY("Fairings")
        //             {
        //                 OutDebug("AFJ: Line 150").
        //                 SET g_LoopDelegates["Events"]["Fairings"] TO LEX(
        //                     "Tag", _fairingTag
        //                     ,"Alt", jettison_alt
        //                     ,"Op", op
        //                     ,"Modules", LIST(p:GETMODULE("ProceduralFairingDecoupler"))
        //                     ,"Delegates", LEX(
        //                         "Check", {},
        //                         "Action", {}
        //                     )
        //                 ).
        //             }
        //             ELSE
        //             {
        //                 OutDebug("AFJ: Line 160").
        //                 g_LoopDelegates:Events:Fairings:Modules:ADD(p:GETMODULE("ProceduralFairingDecoupler")).
        //             }

        //             OutDebug("AFJ: Line 166").
        //             SET g_LoopDelegates:Events:Fairings:Delegates:Check TO choose
        //             { 
        //                 parameter _params to list(). return SHIP:ALTITUDE > jettison_alt.
        //             } 
        //             IF op = "gt" ELSE
        //             { 
        //                 parameter _params to list(). return SHIP:altitude < jettison_alt.
        //             }.
                    
        //             // if not g_LoopDelegates:Events:Fairings:Delegates:HasKey("Action")
        //             // {
        //             OutDebug("AFJ: Line 178").
        //             //g_LoopDelegates:Events:Fairings:Delegates:Add(
        //             set g_LoopDelegates:Events:Fairings:Delegates:Action to {
        //                 parameter _modules is g_LoopDelegates:Events:Fairings:Modules.

        //                 JettisonFairings(_modules).
        //                 OutDebug("Fairing action performed").
        //                 return false.
        //             }.
        //             // }
        //             // else
        //             // {
        //             //     OutDebug("AFJ: Line 187").
        //             // }

        //             OutDebug("AFJ: Line 189").
        //         }
        //     }
        //     wait 3.
        //     RETURN g_LoopDelegates["Events"]:HASKEY("Fairings").
        // }

        // JettisonFairings :: _fairings<list> -> <none>
        // Will jettison fairings provided
        GLOBAL FUNCTION JettisonFairings
        {
            PARAMETER _fairings IS LIST().

            IF _fairings:LENGTH > 0
            {
                FOR f IN _fairings
                {
                    IF f:ISTYPE("Part") { SET f TO f:GETMODULE("ProceduralFairingDecoupler"). }
                    DoEvent(f, "jettison fairing").
                }
            }
        }

        // ArmHotStaging :: _stage<Int> -> staging_obj<Lexicon>
        // Writes events TO g_LoopDelegates TO fire hot staging IF applicable FOR a given stage (next by default)
        GLOBAL FUNCTION ArmHotStaging
        {
            LOCAL ActionDel TO {}.
            LOCAL CheckDel TO {}.
            LOCAL Engine_Obj TO LEX().
            LOCAL HotStage_List TO SHIP:PARTSTAGGEDPATTERN("(HotStg|HotStage|HS)").

            local StageActiveEngines to list().


            IF HotStage_List:LENGTH > 0
            {
                if not g_LoopDelegates:HASKEY("Staging")
                {
                    set g_LoopDelegates["Staging"] to LEX().
                }

                g_LoopDelegates:Staging:Add("HotStaging", LEX()).

                FOR p IN HotStage_List
                {
                    IF p:ISTYPE("Engine")
                    {
                        IF Engine_Obj:HASKEY(p:STAGE)
                        {
                            Engine_Obj[p:STAGE]:ADD(p).
                        }
                        ELSE
                        {
                            SET Engine_Obj[p:STAGE] TO LIST(p).
                        }
                    }
                }
                
                FOR EngListID IN Engine_Obj:KEYS
                {
                    OutInfo("Arming Hot Staging for Engine(s): {0}":Format(EngListID)).
                    
                    // Set up the g_LoopDelegates object
                    g_LoopDelegates:Staging:HotStaging:ADD(EngListID, LEX(
                        "Engines", Engine_Obj[EngListID]
                        ,"EngSpecs", GetEnginesSpecs(Engine_Obj[EngListID])
                        )
                    ).

                    SET checkDel  TO { 
                        IF STAGE:NUMBER - 1 = EngListID {
                            OutInfo("HotStaging Armed: (ETS: {0}s) ":FORMAT(ROUND(g_ActiveEngines_Data:BurnTimeRemaining - g_LoopDelegates:Staging:HotStaging[EngListID]:EngSpecs:SpoolTime + 0.25, 2)), 1).
                            RETURN (g_ActiveEngines_Data:BurnTimeRemaining <= g_LoopDelegates:Staging:HotStaging[EngListID]:EngSpecs:SpoolTime + 0.25) or (Ship:AvailableThrust <= 0.1).
                        }
                    }.

                    SET actionDel TO { 
                        OutInfo("[{0}] Hot Staging Engines ({1})   ":FORMAT(EngListID, "Ignition")).
                        FOR eng IN g_LoopDelegates:Staging:HotStaging[EngListID]:Engines
                        {
                            IF not eng:IGNITION { eng:ACTIVATE.}
                        }

                        OutInfo("[{0}] Hot Staging Engines ({1})   ":FORMAT(EngListID, "SpoolUp")).
                        SET g_ActiveEngines_Data TO GetEnginesPerformanceData(g_ActiveEngines).
                        LOCAL NextEngines_Data TO GetEnginesPerformanceData(g_LoopDelegates:Staging:HotStaging[EngListID]:Engines).
                        UNTIL NextEngines_Data:Thrust >= g_ActiveEngines_Data:Thrust
                        {
                            SET s_Val                TO g_LoopDelegates:Steering:CALL().
                            SET g_ActiveEngines_Data TO GetEnginesPerformanceData(g_ActiveEngines).
                            SET NextEngines_Data     TO GetEnginesPerformanceData(g_LoopDelegates:Staging:HotStaging[EngListID]:Engines).
                            OutInfo("HotStaging Thrust Diff: Active [{0}] Staged [{1}]":FORMAT(Round(g_ActiveEngines_Data:Thrust, 2), Round(NextEngines_Data:Thrust, 2)), 1).
                            WAIT 0.01.
                        }
                        OutInfo().
                        OutInfo("Staging").
                        WAIT UNTIL STAGE:READY.
                        STAGE.
                        WAIT 0.5.
                        OutInfo().
                        g_LoopDelegates:Staging:HotStaging:REMOVE(EngListID).
                        if g_LoopDelegates:Staging:HotStaging:KEYS:LENGTH = 0
                        {
                            g_LoopDelegates:Staging:Remove("HotStaging").
                            set g_HotStagingArmed to  false.
                        }
                        else
                        {
                            ArmHotStaging().
                        }
                    }.

                    // Add the delegates TO the previously set up object
                    g_LoopDelegates:Staging:HotStaging[EngListID]:ADD("Check", checkDel@).
                    g_LoopDelegates:Staging:HotStaging[EngListID]:ADD("Action", actionDel@).
                }

                RETURN TRUE.
            }
            ELSE
            {
                RETURN FALSE.
            }
        }
        // #endregion

        // -- Local
        // #region

        // GetStagingActionDelegate :: (_actionType)<Scalar> -> (actionDel)<kOSDelegate>
        // Returns a delegate of the staging function that should be used (via Stage, or directly via a part's ModuleDecoupler action).
        LOCAL function GetStagingActionDelegate
        {
            PARAMETER _actionType IS 0.

            IF _actionType = 0
            {
                RETURN SafeStage@.
            }
            ELSE IF _actionType = 1
            {
                LOCAL stageAction TO {
                    IF g_NextEngines_Spec:Keys:LENGTH = 0
                    {
                        SET g_NextEngines TO GetNextEngines().
                        IF g_NextEngines:LENGTH > 0
                        {
                            SET g_NextEngines_Spec TO GetEnginesSpecs(g_NextEngines).
                        }
                    }

                    until SafeStageWithUllage(g_NextEngines, g_NextEngines_Spec)
                    {
                        DispLaunchTelemetry().
                        wait 0.01.
                    }
                    // SET g_ActiveEngines TO GetActiveEngines(). 
                    // SET g_NextEngines TO GetNextEngines().
                    // SET g_NextEngines_Spec TO GetEnginesSpecs(g_NextEngines).
                }.

                RETURN stageAction@.
            }
        }
        
        
        // GetStagingConditionDelegate :: (_checkType)<string> -> (Result)<kOSDelegate>   // TODO: Implement other check types here (only thrust value FOR now)
        // Given a staging check type string, performs that condition check and returns the result
        LOCAL function GetStagingConditionDelegate
        {
            PARAMETER _checkType IS 0.

            // IF _checkType = 0 // Thrust Value: SHIP:AvailableThrust < 0.01
            // {
                LOCAL condition TO CheckShipThrustCondition@.
                LOCAL boundCondition TO condition:BIND(Ship, 0.01).
                RETURN boundCondition.
            // }
            // ELSE IF _checkType = 1
            // {

            // }
        }


        // CheckStageThrustCondition :: (_ves)<Vessel>, (_checkVal)Scalar -> <ResultCode>(Scalar)
        LOCAL function CheckShipThrustCondition
        {
            PARAMETER _ves,
                      _checkVal.

            LOCAL resultCode TO 0.
            IF _ves:AvailableThrust < _checkVal and SHIP:STATUS <> "PRELAUNCH"
            {
                SET resultCode TO 1.
            }
            RETURN resultCode.
        }

        LOCAL function SafeStage
        {
            WAIT UNTIL STAGE:READY.
            stage.
            WAIT 0.01.
            // IF g_HotStageArmed
            // {
            //     SET g_HotStageArmed TO ArmHotStaging().
            // }
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
                    OutInfo("Ullage Check (Fuel Stability Rating: {0})":FORMAT(round(_engList_Spec:FuelStabilityMin * 100, 2))).
                }
            }
            else 
            {
                set stageResult to true.
            }

            if stageResult
            {
                wait until Stage:Ready.
                Stage.
                wait 0.01.
            }
            
            return stageResult.
        }


        // SafeStage :: <none> -> <none>
        // Performs a staging function after waiting FOR the stage TO report it IS ready first
        LOCAL function SafeStageState
        {
            LOCAL ullageDelegate TO { RETURN true. }.

            IF stagingState = 0
            {
                WAIT UNTIL STAGE:READY.
                STAGE.
                SET stagingState TO 1.
            }
            ELSE IF stagingState = 1
            {
                IF g_ActiveEngines_Data["Spec"]["IsSepMotor"]
                { 
                    IF g_ActiveEngines_Data["Spec"]["Ullage"]
                    {
                        SET ullageDelegate TO { RETURN CheckUllage(). }.  // #TODO: Write CheckUllage()
                    }
                    SET stagingState TO 2.
                }
                ELSE
                {
                    SET stagingState TO 4.
                }
            }
            ELSE IF stagingState = 2
            {
                IF ullageDelegate:Call()
                {
                    SET stagingState TO 1.
                }
            }
            ELSE IF stagingState = 4
            {
                SET stagingState TO 0.
                UNSET ullageDelegate.
                RETURN true.
            }
        }
        // #endregion
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

    GLOBAL FUNCTION GetOrbitalSteeringDelegate
    {
        // PARAMETER _delDependency IS LEX().
        PARAMETER _steerPair IS "Flat:Sun",
                  _fShape    IS 0.9875.

        LOCAL del TO {}.
        IF g_azData:LENGTH = 0
        {
            SET g_AzData TO l_az_calc_init(g_MissionParams[1], g_MissionParams[0]).
        }

        IF g_AngDependency:Keys:LENGTH = 0
        {
            SET g_AngDependency TO InitAscentAng_Next(g_MissionParams[1], _fShape, 10).
        }

        IF _steerPair = "Flat:Sun"
        {
            SET del TO { RETURN HEADING(compass_for(SHIP, SHIP:Prograde), 0, 0).}.
        }
        ELSE IF _steerPair = "AngErr:Sun"
        {
            RunOncePath("0:/lib/launch.ks").
            SET del TO { RETURN HEADING(l_az_calc(g_azData), GetAscentAng_Next(g_AngDependency) * _fShape, 0).}.
        }
        ELSE IF _steerPair = "ApoErr:Sun"
        {
            RunOncePath("0:/lib/launch.ks").
            set del to { return HEADING(l_az_calc(g_azData), GetAscentAng_Next(g_AngDependency) * _fShape, 0).}.
        }
        ELSE IF _steerPair = "lazCalc:Sun"
        {
            SET del TO { RETURN SHIP:FACING.}.
        }
        
        RETURN del@.
    }

    GLOBAL FUNCTION SetSteering
    {
        PARAMETER _altTurn.

        IF SHIP:ALTITUDE >= _altTurn
        {
            SET s_Val TO SHIP:SRFPROGRADE - r(0, 4, 0).
        } 
        ELSE
        {
            SET s_Val TO HEADING(90, 88, 0).
        }
    }
    // #endregion
// #endregion