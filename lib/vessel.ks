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
    local l_SteeringDelegate_Standby to { return Ship:Facing.}.

    local l_curBoosterSetId      to -1.
    
    local l_rollCheck            to 0.
    local l_rollCheckWeightAvg   to 0.
    local l_rollCheckWeightAvgs  to list().
    local l_rollCheckTimout      to 3.
    local l_rollCheckTimestamp   to 0.
    local l_rollCheckTimeMark    to 0.
    local l_rollCheckTimeWindup  to 0.
    local l_rollCheckWindupLimit to list(-1, 1).

    local l_rollOffset to 0.
    local l_rollOffsets to list().

   global g_rollCheckObj to lex(
        "CTRL_REF", lex(
            -1, list(Terminal:Input:Backspace, Terminal:Input:DeleteRight)
            ,0, list()
            ,1, list(Terminal:Input:UpCursorOne, Terminal:Input:DownCursorOne)
            ,2, list(")", "(")
            ,3, list("}", "{")
        )
        ,"DEL", lex(
            "UPDATE", UpdateReentryRollOffsets@
        )
        ,"ROLL_OFFSETS", list(
            0
            ,0.25
            ,0.5
            ,1
            ,2.5
            ,5
            ,10
            ,22.5
            ,30
            ,45
            ,90
        )
    ).
    local l_rollOffsets_UpperBound to g_rollCheckObj:ROLL_OFFSETS:Length - 1.

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
    // New entries in global objects
    set g_PartInfo["LES"] to list(
        "ROC-MercuryLESBDB"
    ).

    set g_PartInfo["EventTypeRef"] to lexicon(
        "Antenna", list("ModuleDeployableAntenna", "extend antenna")
        ,"Solar",  list("ModuleDeployableSolarPanel", "extend")
    ).

    set g_PartInfo["PartModuleRef"] to lexicon(
        "longAntenna", list("ModuleDeployableAntenna", "extend antenna")
    ).
    // #endregion
// #endregion



// *~ Functions ~* //
// #region

    // ** Staging
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
            local HotStage_List to Ship:PartsTaggedPattern("(HotStg|HotStage|HS)").
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
                    }
                }

                // if g_Debug OutDebug("Engine_Obj Keys: {0}":Format(Engine_Obj:Keys:Join(";")), -6).
                wait 1.

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

                    set checkDel  to {
                        // parameter _stageEngs.

                        if MissionTime > 0 and g_ActiveEngines:Length > 0
                        {
                            if Stage:Number - 1 = HotStageID
                            {
                                local SpoolTime to g_LoopDelegates:Staging:HotStaging[HotStageID]:EngSpecs:SpoolTime + 0.5. 
                                set stageEngines_BT to GetEnginesBurnTimeRemaining(GetActiveEngines(Ship, "NoBooster")).
                                // set stageEngines_BT to g_ActiveEngines_Data:BurnTimeRemaining.
                                set g_TR to stageEngines_BT - SpoolTime.
                                OutInfo("HotStaging Armed: (ET: T-{0,6}s) ":Format(Round(g_TR, 2), 1)).

                                return (stageEngines_BT <= SpoolTime) or (g_ActiveEngines_Data:Thrust <= 0.1).
                            }
                        }
                        else if MissionTime > 0 and t_Val > 0
                        {
                            if g_Debug { OutDebug("Fuel Exhausted, hot staging").}
                            return True.
                        }
                        else
                        {
                            if g_Debug { OutDebug("Fell through HotStaging checkdel").}
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
                        }
                        else
                        {
                            ArmHotStaging().
                        }
                    }.

                    // Add the delegates to the previously set up object
                    g_LoopDelegates:Staging:HotStaging[HotStageID]:Add("Check", checkDel@).
                    g_LoopDelegates:Staging:HotStaging[HotStageID]:Add("Action", actionDel@).
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
                // local boundCondition to condition:BIND(Ship, 0.1).
                // return boundCondition.
                return GetShipThrustConditionDelegate(Ship, _checkVal).
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
                if __ves:AvailableThrust < checkVal and throttle > 0 and Stage:Number >= g_StageLimit
                { 
                    // OutDebug("[{0}] StagingCheckDel TRUE (AT:{1}/{2}|{3}/0|{4}/{5})":Format(Round(MissionTime, 1), Round(__ves:AvailableThrust, 2), checkVal, Round(throttle, 2), Stage:Number, g_StageLimit), 1).
                    return 1.
                } 
                else 
                {
                    // OutDebug("[{0}] StagingCheckDel FALSE (AT:{1}/{2}|{3}/0|{4}/{5})":Format(Round(MissionTime, 1), Round(__ves:AvailableThrust, 2), checkVal, Round(throttle, 2), Stage:Number, g_StageLimit), 1).
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

    // Vessel Event Loop Handlers
    // #region

        // ArmAscentEvents :: <none> -> eventRegisteredCount<Scalar>
        // Arms events that should run during launches
        global function ArmAscentEvents
        {
            parameter _eventParts to Ship:PartsTaggedPattern("^ascent\|.*").

            local eventID to "".
            local eventRegisteredCount to 0.

            for eventPart in _eventParts
            {
                local epTag to eventPart:Tag:Replace("Ascent|","").
                local epTagSplit to epTag:Split("|").

                if epTag:MatchesPattern("^MECO\|\d*")
                {
                    if g_Debug OutDebug("[{0}|{1}] epTag MECO Match: {2}":Format(eventPart:Name, eventPart:UID, epTag), 10).
                    wait 0.1.
                    if not g_LoopDelegates:Events:HasKey("MECO")
                    {
                        set g_MECOArmed to SetupMECOEventHandler("Ascent").
                        set eventRegisteredCount to eventRegisteredCount + 1.
                    }
                }

                if epTagSplit[0]:MatchesPattern("(Decouple|DC)")
                {
                    wait 0.1.
                    set eventID to "DC".
                    local dcList to list().

                    if epTagSplit:Length > 1
                    {
                        if epTagSplit[1]:ToNumber(-808) = -808
                        {
                            local epConditionSplit to epTagSplit[1]:Split(";").
                            if epConditionSplit:length > 1
                            {
                                if epConditionSplit[0] = "BOOSTER"
                                {
                                    if g_Debug OutDebug("[{0}|{1}] epTag DC_Booster Match: {2}":Format(eventPart:Name, eventPart:UID, epTag), 10).
                                    set eventID to ("DC_BOOSTER_{0}"):Format(epConditionSplit[1]).
                                    set dcList to Ship:PartsTaggedPattern("Booster\|{0}":Format(epConditionSplit[1])).
                                }
                            }
                            else if epTagSplit[1] = "MECO"
                            {
                                if g_Debug OutDebug("[{0}|{1}] epTag DC_MECO Match: {2}":Format(eventPart:Name, eventPart:UID, epTag), 11).
                                set eventID to "DC_MECO".
                                if not g_LoopDelegates:Events:HasKey(eventID)
                                {
                                    set dcList to Ship:PartsTaggedPattern("Ascent\|(Decouple|DC)\|MECO").
                                }
                            }
                        }
                        else if epTagSplit[1]:MatchesPattern("\d*")
                        {
                            local dcMET to ParseStringScalar(epTag:Replace("Decouple|",""):ToNumber(-1)).
                            set eventID to "DC_{0}":Format(dcMET).
                            if not g_LoopDelegates:Events:HasKey(eventID)
                            {
                                set dcList to Ship:PartsTaggedPattern("Ascent\|(Decouple|DC)\|\d*").
                            }
                        }
                        else
                        {
                        }
                    }
                    else
                    {
                    }
                    
                    if not g_LoopDelegates:Events:HasKey(eventID) 
                    {
                        OutInfo("Arming DecouplerEvent [Count:{0}]":Format(dcList:Length)).
                        wait 1.
                        local dcEventRegistrationResult to SetupDecoupleEventHandler(eventID, dcList, "DecoupleEvent").
                        if dcEventRegistrationResult 
                        {
                            set eventRegisteredCount to eventRegisteredCount + 1.
                            set g_DecouplerEventArmed to True.
                        }

                        OutInfo("***Arming DecouplerEvent Result: [{0}]":Format(dcEventRegistrationResult)).
                    }
                }
            }

            return eventRegisteredCount.
        }

        // SetupOnDeployHandler :: [_partList<Part>] -> resultFlag<bool>
        // Creates and registers new events for the OnDeploy event type
        global function SetupOnDeployHandler
        {
            parameter _partList is Ship:PartsTaggedPattern("OnDeploy\|\d+")
                      ,_deployStage is -1.

            local resultFlag to False.
            
            if _partList:Length > 0
            {
                local deployStage to choose _partList[0]:DecoupledIn + 1 if _deployStage < 0 else _deployStage.
                local paramList to list(_partList, deployStage).

                local checkDel to { 
                    parameter _params is list().
                    
                    local _deployStage to _params[1].
                    
                    if Stage:Number <= _deployStage or g_OnDeployActive
                    {
                        return True.
                    }
                    return False.
                }.

                local actionDel to 
                { 
                    parameter _params is list(). 

                    local partList to _params[0].
                    local maxSet to 0.

                    for p in partList
                    {
                        set maxSet to Max(maxSet, p:tag:Split("|")[1]:ToNumber(-1)).
                    }

                    from { local i to 0.} until i > maxSet step { set i to i + 1.} do
                    {
                        OutInfo("OnDeploy.{0}: Active":Format(i)).
                        for p in ship:PartsTaggedPattern("OnDeploy\|{0}":Format(i))
                        {
                            for pType in g_PartInfo:PartModRef:Keys
                            {
                                for m in g_PartInfo:PartModRef[pType]
                                {
                                    if p:HasModule(m)
                                    {
                                        local deployMod to p:GetModule(m).
                                        local modEventTypes to g_ModEvents[pType][m].
                                        if modEventTypes:HasKey("Deploy")
                                        {
                                            local deployMap to modEventTypes:Deploy.
                                            if deployMap:IsType("List")
                                            {
                                                local modActions to deployMod:AllActions.
                                                from { local iE to 0. local doneFlag to False.} until iE = modActions:Length or doneFlag step { set iE to iE + 1.} do
                                                {
                                                    local eventAction to GetFormattedAction(deployMod, modActions[iE]).
                                                    if deployMap:Contains(eventAction)
                                                    {
                                                        if DoEvent(deployMod, eventAction) <> 1
                                                        {
                                                            DoAction(deployMod, eventAction).
                                                        }
                                                    }
                                                }
                                            }
                                            else
                                            {
                                                if DoEvent(p:GetModule(m), deployMap) <> 1
                                                {
                                                    DoAction(p:GetModule(m), deployMap).
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        wait 1.
                    }
                    return False.
                }.

                local deployEvent to CreateLoopEvent("OnDeploy", "OnDeployEvent", paramList, checkDel@, actionDel@).
                set resultFlag to RegisterLoopEvent(deployEvent).
            }

            return resultFlag.
        }

        // SetupDecoupleEventHandler :: _dcEventID<String>, _dcList<List[Decoupler]> -> resultFlag<bool>
        // Creates a new decouple event for auto-staging outside of MECO. Uses a tag on the decoupler to control.
        // The tag depends on what type of decoupling event it is.
        // Ugh, this is too complicated isn't it
        global function SetupDecoupleEventHandler
        {
            parameter _dcEventID,
                      _dcList is list(),
                      _dcEventType is "DecoupleEvent".

            local boosterEngs   to list().
            local dcSepRM       to lexicon().
            local dcUIDList     to list().
            local paramList     to list().
            local registerFlag  to False.
            local resultCode    to 0.
            local resultFlag    to False.

            local resultCodeLex to lexicon(
                "SUCCESS",  list(10, 11, 20, 21, 30, 31)
                ,"ERROR",   list(96, 99)
                ,"NOOP",    list(0, 19)
            ).

            // local dcTag to _dcList[0]:Tag.
            // local _partTagSplit to dcTag:Split("|").
            // if g_Debug OutDebug("[SetupDecoupleEventHandler] dcTag: [{0}]":Format(dcTag)).
            
            // local eventCheckVal to _partTagSplit[_partTagSplit:Length - 1]:Split(";").
            local eventCheckVal    to _dcEventID:Replace("DC_", ""):Split("_").
            local eventCheckScalar to choose eventCheckVal[0]:ToNumber(-1) if eventCheckVal:Length = 1 else eventCheckVal[1]:ToNumber(-1).

            // local _dcEventID to "DC_{0}":Format(eventCheckVal).
            if g_LoopDelegates:Events:HasKey(_dcEventID)
            {
            }
            else
            {
                // if g_Debug OutDebug("[SetupDecoupleEventHandler] Beginning event registration").
                set resultCode to 1.

                for _dc in _dcList
                {
                    for m in g_ModEvents:Decoupler:Keys
                    {
                        if _dc:Modules:Contains(m) 
                        {
                            dcUIDList:Add(_dc:UID).
                            for child in _dc:PartsTagged("")
                            {
                                if child:IsType("Engine")
                                {
                                    if g_PartInfo:Engines:SepRef:Contains(child:Name)
                                    {
                                        if not child:Ignition
                                        {
                                            if dcSepRM:HasKey(_dc:UID)
                                            {
                                                dcSepRM[_dc:UID]:Add(child).
                                            }
                                            else
                                            {
                                                set dcSepRM[_dc:UID] to list(child).
                                            }
                                        }
                                    }
                                    else
                                    {
                                        boosterEngs:Add(child).
                                    }
                                }
                            }
                        }
                    }
                }
                
                local checkDel to { return False.}.
                if eventCheckVal[0] = "MECO"
                {
                    set resultCode to 10.
                    set checkDel to { 
                        parameter _params is list(). 

                        local MECOResult to not g_LoopDelegates:Events:Keys:Contains("MECO"). // This is confusing code but the intent is to return False if g_LooopDelegates contains the "MECO" event. 
                                                                                            // Once that event has fired, it should be removed from g_LoopDelegates, at which point this will return True.

                        // OutInfo("Checking DecoupleDelegate MECO[{0}]":Format(g_LoopDelegates:Events:Keys:Contains("MECO")), 2). // This is backwards from the actual value but more human readable / maybe less confusing?
                        return MECOResult.
                    }.
                    set paramList to list(dcUIDList, dcSepRM).
                    set registerFlag to True.
                }
                else if eventCheckVal[0] = "BOOSTER"
                {
                    set resultCode to 20.
                    set checkDel to {
                        parameter _params is list().

                        local checkFlag to False.
                        local pendingStaging to list().
                        
                        for booster in _params[2]
                        {
                            // OutDebug("[{0}][{1}]({2})<booster>thr:{3}|avlthr:{4}  ":Format(Round(MissionTime, 1), booster:name + "|" + booster:Decoupler:Tag, _params[2]:Length, Round(booster:Thrust, 1), Round(booster:AvailableThrust, 1)), 5).
                            if booster:Ignition and not booster:Flameout
                            {
                                // OutDebug("[{0}][{3}] Booster Check [IGN: {1} FLM: {2}]":Format(Round(MissionTime, 2), booster:Ignition, booster:Flameout, booster:name), 6).
                                local conRes to choose booster:Resources[0] if g_PropInfo:Solids:Contains(booster:ConsumedResources:Values[0]:Name) else booster:ConsumedResources:Values[0].
                                if booster:Thrust <= 0.1
                                {
                                    // OutDebug("[{0}][{3}] Booster thrust trigger: {1} / {2} ":Format(Round(MissionTime, 2), booster:Thrust, 0.1, booster:name), 7).
                                    pendingStaging:Add(booster).
                                }
                                else if booster:MassFlow > 0
                                {
                                    // OutDebug("[{0}][{2}] Booster Mass Flow: {1} ":Format(Round(MissionTime, 2), booster:MassFlow, booster:name), 7).
                                    local resCalc to conRes:Capacity * (booster:GetModule("ModuleEnginesRF"):GetField("predicted residuals") * 0.9).
                                    // OutDebug("Amt: {0} | Cap: {1} | ResCalc: {2}":Format(Round(conRes:Amount, 2), Round(conRes:Capacity, 2), Round(resCalc, 2))).
                                    if conRes:Amount <= resCalc and booster:Thrust <= 0.25
                                    {
                                        // OutDebug("[{0}] conRes:Amount / resCalc / booster:Thrust: {1} / {2} / {3} ":Format(Round(MissionTime, 2), conRes:Amount, resCalc, booster:Thrust), 9).
                                        pendingStaging:Add(booster).
                                    }
                                }
                                else
                                {
                                    // OutDebug("Whoops, what's happening here.", 10).
                                }
                            }
                            else if booster:flameout
                            {
                                pendingStaging:Add(booster).
                            }
                        }
                        
                        set checkFlag to pendingStaging:Length = _params[2]:Length.
                        // if g_Debug OutDebug("[{0:8}] Booster checkDel result: [{1}]|[{2}]":Format(Round(MissionTime, 3), pendingStaging:Length, _params[2]:Length), 7).

                        // OutInfo("Checking DecoupleDelegate BOOSTER[{0}/{1}]":Format(pendingStaging:Length, _params[1]:Length)).
                        return checkFlag.
                    }.
                    set paramList to list(dcUIDList, dcSepRM, boosterEngs).
                    set registerFlag to True.
                }
                else if eventCheckScalar > -1
                {
                    set resultCode to 30.

                    set checkDel to { 
                        parameter _params is list(). 
                        OutInfo("Checking DecoupleDelegate ETA[{0}s]":Format(Round(_params[3] - MissionTime, 2))).
                        return MissionTime >= _params[3].
                    }.
                    set paramList to list(dcUIDList, dcSepRM, boosterEngs, eventCheckScalar).
                    set registerFlag to True.
                }
                else
                {
                    set resultCode to 96.
                }

                if registerFlag
                {
                    local actionDel to 
                    { 
                        parameter _params is list(). 

                        OutInfo("Decouple Action Delegate [#DC:{0}]":Format(_dcList:Length)).
                        set dcUIDList to _params[0].
                        set dcSepRM   to _params[1].

                        from { local i to 0.} until i = _dcList:Length or _dcList:Length = 0 step { set i to i + 1.} do
                        {
                            local dc    to _dcList[i].
                            
                            if dcUIDList:Contains(dc:UID)
                            {
                                local dcEventStr to "". 
                                local dcModule   to core.

                                for m in g_ModEvents:Decoupler:Keys 
                                {
                                    if dc:HasModule(m)
                                    {
                                        set dcModule to dc:GetModule(m).
                                        for event in dcModule:allevents
                                        {
                                            if event:Contains("decouple")
                                            {
                                                set dcEventStr to event:Replace("(callable) ", ""):Replace(", is KSPEvent", "").
                                            }
                                            else if event:Contains("Jettison Fairing")
                                            {
                                                set dcEventStr to "Jettison Fairing".
                                            }
                                        }
                                        
                                        // if g_ModEvents:Decoupler:HasKey(m)
                                        // {
                                        //     if dcModule:HasEvent("decouple")
                                        //     {
                                        //         //set dcEventStr to g_ModEvents:Decoupler[m]:Decouple if g_ModEvents:Decoupler:HasKey(m) else "decouple".
                                        //         set dcEventStr to "decouple".
                                        //     }
                                        //     else if dcModule:HasEvent("decouple top node")
                                        //     {
                                        //         set dcEventStr to "decouple top node".
                                        //     }

                                        // }
                                    }
                                }

                                if dcModule:Name <> "kOSProcessor"
                                {
                                    if dcSepRM:HasKey(dc:UID)
                                    {
                                        for sep in dcSepRM[dc:UID]
                                        {
                                            if not sep:Ignition
                                            {
                                                sep:Activate.
                                            }
                                        }
                                    }
                
                                    // for p in dc:PartsTagged("")
                                    // {
                                    //     if g_PartInfo:Engines:SepRef:Contains(p:Name)
                                    //     {
                                    //         if not p:Ignition 
                                    //         {
                                    //             p:Activate.
                                    //         }
                                    //     }
                                    // }

                                    set dcModule:Part:Tag to "".
                                    DoEvent(dcModule, dcEventStr).
                                    dcUIDList:Remove(dcUIDList:Find(dc:UID)).
                                }
                            }
                        }
                        // wait 0.01.
                        if Ship:PartsDubbedPattern("^Booster\|.*"):Length = 0
                        {
                            set g_BoostersArmed to False.
                        }
                        else
                        {
                            ArmBoosterStaging_NewShinyNext().
                        }
                        return False.
                    }.

                    // if g_Debug OutDebug("[SetupDecoupleEventHandler] Creating Loop Event").
                    local dcEvent to CreateLoopEvent(_dcEventID, _dcEventType, paramList, checkDel@, actionDel@).
                    // if g_Debug OutDebug("[SetupDecoupleEventHandler] Registering Loop Event").
                    set resultFlag to RegisterLoopEvent(dcEvent).

                    set resultCode to resultCode + 1.
                }
                else
                {
                    set resultCode to 99.
                }
            }
            
            // if g_Debug OutDebug("[SetupDecoupleEventHandler] resultCode: [{0}]":Format(resultCode), 1).
            if resultCode > 0 // = 0 means we no-op'd
            {
                if resultCodeLex:NOOP:Contains(resultCode)
                {
                }
                else if resultCodeLex:SUCCESS:Contains(resultCode)
                {
                    set resultFlag to True.
                    // if resultCode = 1
                    // {
                    //     // if g_Debug OutDebug("[SetupDecoupleEventHandler] Registration successful").
                    // }
                    // else if resultCode = 9
                    // {
                    //     // if g_Debug OutDebug("[SetupDecoupleEventHandler] Event Handler already exists for [{0}], skipping":Format(dcEventID)).    
                    // }
                }
                else if resultCodeLex:ERROR:Contains(resultCode)
                {
                    if g_Debug { OutDebug("[SetupDecoupleEventHandler] Registration failed [ResultCode: {0}]":format(resultCode), 0, "Red").}
                }
                else
                {
                    set resultCode to 31.
                }
            }
            else 
            {
                // if g_Debug OutDebug("[SetupDecoupleEventHandler] No-Op / Bypassed").
                set resultCode to 21.
            }

            return resultFlag or g_LoopDelegates:Events:HasKey(_dcEventID) or g_DecouplerEventArmed.
        }

        // SetupOnDeployEventHandler :: [_partList<List[Parts]>] -> resultFlag<bool>
        global function SetupOnDeployEventHandler
        {
            SetupOnDeployHandler().
        }

        // ArmOnReentryEvents :: [optionsList<List>] -> resultFlag<bool>
        global function ArmOnReentryEvents
        {
            parameter _options is list().

            local armState to lexicon( // #TODO Finish individual arm state delegates!
                "Fairing", lex( // Arms any tagged fairings for separation after atmospheric reentry
                    "Armed", False
                    ,"Del", ArmFairingJettison("reentry")@
                )
                ,"Gemini", lex( // Gemini has controls for CoM offsets
                    "Armed", False
                    ,"Del", {} // ArmGeminiCoMOffset@
                )
                ,"JettisonDrogue", lex( // Arms a tagged drogue parachute to be jettisoned at a given altitude
                    "Armed", False
                    ,"Del",  {} // ArmPartJettisonOnAltitude@
                )
                ,"Mercury", lex( // Arms the Mercury landing bag
                    "Armed", False
                    ,"Del", {} // ArmMercuryPartJettison@
                )
                ,"Parachute", lex( // Arms any parachutes present
                    "Armed", False
                    ,"Del",  {} // ArmParachutes@
                )
                ,"SciCollect", lex( // Attempts to collect science
                    "Armed", False
                    ,"Del", {} // ArmSciCollection@
                )
            ).

            for opt in _options
            {
                if      opt = "Gemini"          set armState:Gemini         to True.
                else if opt = "JettisonDrogue"  set armState:JettisonDrogue to True.
                else if opt = "Fairing"         set armState:Fairing        to True.
                else if opt = "Mercury"         set armState:Mercury        to True. 
                else if opt = "Parachute"       set armState:Parachute      to True.
                else if opt = "CollectSci"      set armState:SciCollect     to True.
            }

            from { local i to 0.} until i = armState:Keys:Length step { set i to i + 1.} do
            {
                if armState:Values[i]:Armed
                {
                    armState:Values[i]:Del:Call().
                }
            }
        }

        // SetupOnStageEventHandler :: [_partList<List[Parts]>] -> resultFlag<bool>
        // Creates and registers event delegates for parts that need actions to happen when the vessel reaches a specific stage number
        // Stage number and action derived from tags
        // Tag format: OnStage|<StgNum>|<SetIdx>|<EventType>;<Params>
        // Accepted values for EventType:
        // - Antenna
        // - Solar
        // - Science (defaults to all; use param with name of experiment for specific experiements)
        global function SetupOnStageEventHandler
        {
            parameter _partList.

            local actionDel to { parameter _params is list(). return False. }.
            local checkDel to  { parameter _params is list(). return True.  }. // By Default, if no modification this will automatically unregister.
            local maxSetIdx to 0.
            local deployStg to 0.
            local partMatrix to lexicon().

            for p in _partList
            {
                local eventType to "".
                local setIdx to 0.
                local tagSplit to p:tag:Split("|").

                if tagSplit:Length > 1
                {
                    set deployStg to tagSplit[1]:ToNumber().
                    if tagSplit:Length > 2
                    {
                        set setIdx to tagSplit[2]:ToNumber().
                        set maxSetIdx to Max(maxSetIdx, setIdx).
                    }

                    if partMatrix:HasKey(setIdx)
                    {
                        partMatrix[setIdx]:Add(p:UID, list(p)).
                        if tagSplit:Length > 3
                        {
                            set eventType to tagSplit[3].
                        }
                        partMatrix[setIdx][p:UID]:Add(eventType).
                    }
                    else
                    {
                        set partMatrix[setIdx] to lexicon(
                            p:UID, list(p, eventType)
                        ).
                    }
                }
            }
            
            local osEventID to "ONSTAGE_{0}":Format(deployStg).
            local paramList to list(partMatrix).

            if not g_LoopDelegates:Events:HasKey(osEventID)
            {
                set checkDel to { 
                    parameter _params is list().

                    return Stage:Number = deployStg.
                }.

                set actionDel to 
                { 
                    parameter _params is list(). 

                    local onStageMatrix to _params[0].
                    
                    from { local i to 0.} until i >= maxSetIdx or i >= onStageMatrix:Keys:Length step { set i to i + 1.} do
                    {
                        local partSet to onStageMatrix[i].

                        for pObj in partSet
                        {
                            local event         to "".
                            // local eventData     to "".
                            // local eventParam    to "".
                            local eventType     to "".
                            local eventRef      to list().
                            local m             to "".

                            if pObj:Length > 0
                            {
                                local p to pObj[0].
                                if pObj:Length > 1
                                {
                                    set eventType to pObj[1].
                                    // TODO: Add eventData param handler
                                    // set eventData to pObj[1]:Split(";").
                                    // if eventData:Length > 1
                                    // {
                                    //     set eventParam to eventData[1].
                                    // }

                                    set eventRef to g_PartInfo:EventTypeRef[eventType].
                                }
                                else
                                {
                                    set eventRef to g_PartInfo:PartModuleRef[p:Name].
                                }
                                set m to eventRef[0].
                                set event to GetFormattedEvent(eventRef[1]).

                                DoEvent(m, event).
                            }
                        }
                    }

                    return False.
                }.
            }

            local osEvent to CreateLoopEvent(osEventID, "OnStageEvent", paramList, checkDel@, actionDel@).
            local resultFlag to RegisterLoopEvent(osEvent).

            return resultFlag.
        }

        global function SetupSpinStabilizationEventHandler
        {
            parameter _partList is Ship:PartsTaggedPattern("SpinDC\|.*").

            local resultFlag to False.

            for dc in _partList
            {
                set resultFlag to ArmSpinStabilizationDC(dc).
            }

            return resultFlag.
        }
    // #endregion

    // Spin-stabilization
    // #region
    
    global function ArmSpinStabilizationDC
    {
        parameter _spinDC.

        local ctrlModules to list().
        local ctrlRCSModules to Ship:ModulesNamed("ModuleRCSFX").
        local ctrlSrfModules to Ship:ModulesNamed("FARControllableSurface").
        local ctrlUIDs    to list().
        
        local resultFlag to False.

        local spinForce to 1.
        local spinPreload to 15.
        local spinType to 0. // 0: Auto, prefers control surfaces in atmosphere and RCS in vacuum
                              // 1: Control Surfaces
                              // 2: RCS
                              // 3: #TODO Specific engines
        local spinTag to _spinDC:Tag:Split("|").

        local spinStage to _spinDC:Stage.

        if spinTag:Length > 1
        {
            set spinPreload to ParseStringScalar(spinTag[1], spinPreload).
            if spinTag:Length > 2 set spinForce to ParseStringScalar(spinTag[2], spinForce).
            if spinTag:Length > 3 set spinType to ParseStringScalar(spinTag[3], spinType).
        }

        if spinType = 0
        {
            if ctrlSrfModules:Length > 0
            {
                for m in ctrlSrfModules
                {
                    if m:Part:DecoupledIn <= _spinDC:Stage or m:Part:Tag:Contains("Spin")
                    {
                        ctrlModules:Add(m).
                        ctrlUIDs:Add(m:Part:UID).
                        set spinType to 1.
                    }
                }
            }
            
            if ctrlModules:Length = 0 
            {
                for m in ctrlRCSModules
                {    
                    if m:Part:DecoupledIn >= _spinDC:Stage or m:Part:Tag:Contains("Spin")
                    {
                        ctrlModules:Add(m).
                        ctrlUIDs:Add(m:Part:UID).
                        set spinType to 2.
                    }
                }
            }
        }
        else
        {
            if spinType = 1 and ctrlSrfModules:Length > 0
            {
                for m in ctrlSrfModules
                {
                    if m:Part:DecoupledIn <= _spinDC:Stage or m:Part:Tag:Contains("Spin")
                    {
                        ctrlModules:Add(m).
                        ctrlUIDs:Add(m:Part:UID).
                    }
                }
            }
            else if spinType = 2 and ctrlRCSModules:Length > 0
            {
                
                for m in ctrlRCSModules
                {
                    if m:Part:DecoupledIn >= _spinDC:Stage or m:Part:Tag:Contains("Spin")
                    {
                        ctrlModules:Add(m).
                        ctrlUIDs:Add(m:Part:UID).
                    }
                }
            }
        }
        
        if spinType > 0
        {
            local paramList to list(
                spinStage,
                ctrlModules,
                ctrlUIDs,
                spinType,
                spinForce
            ).
            
            set g_SpinActive to False.
            set g_TS0Ref to spinPreload.

            // check del
            local checkDel to {
                parameter _params is list().

                local doActionFlag to False.

                if g_ActiveEngines:Length > 0
                {
                    if _params[0] = g_ActiveEngines[0]:DecoupledIn
                    {
                        if g_SpinActive
                        {
                            // if g_Debug OutDebug("Spin Stabilization Active [REM: {0}]":Format(Round(g_TS0 - Time:Seconds, 2)), 6).
                            OutInfo("Spin Stabilization Active [REM: {0}] ":Format(Round(g_TS0 - Time:Seconds, 2)), 1).
                            if Time:Seconds >= g_TS0
                            {
                                set doActionFlag to True.
                                set g_TS0 to -1.
                                set g_TS0Ref to 0.
                            }
                        }
                        else if g_ActiveEngines_Data:HasKey("BurnTimeRemaining") 
                        {
                            local timeRem to Round(g_ActiveEngines_Data:BurnTimeRemaining - spinPreload, 2).
                            // if g_Debug OutDebug("Spin Stabilization Armed  [ETA: {0}]":Format(timeRem), 6).
                            OutInfo("Spin Stabilization Armed  [ETA: {0}]    ":Format(timeRem), 1).
                            if timeRem <= 0
                            {
                                if not g_SpinActive
                                {
                                    set doActionFlag to True.
                                    set g_TS0 to Time:Seconds + spinPreload.
                                }
                            }
                        }
                    }
                }

                return doActionFlag.
            }.

            // action del
            local steerVal to Ship:Facing.
            local l_SpinSteerDelHolder to { return steerVal.}.

            local actionDel to {
                parameter _params is list().

                local keepAlive to False.

                if g_SpinActive
                {
                    OutInfo("Spin Stabilization Disarmed   ", 1).
                    set Ship:Control:Roll to 0.
                    set g_SteeringDelegate to l_SpinSteerDelHolder.
                    unset l_SpinSteerDelHolder.
                    set g_SpinActive to False.
                    set g_SpinArmed to False.
                }
                else
                {
                    OutInfo("Initiating Spin Stabilization   ", 1).
                    set l_SpinSteerDelHolder to g_SteeringDelegate.
                    set steerVal to Ship:Facing.
                    set g_SteeringDelegate to { return steerVal.}.

                    if _params[3] = 1 and Body:ATM:AltitudePressure(Ship:Altitude) >= 0.1
                    {
                        from { local i to 0.} until i = _params[2]:Length step { set i to i + 1.} do
                        {
                            if g_ShipUIDs:Contains(_params[2][i])
                            {
                                local m to _params[1][i].
                                if not m:GetField("std. ctrl") m:SetField("std. ctrl", True).
                            }
                        }
                    }
                    else if _params[3] = 2 or Body:ATM:AltitudePressure(Ship:Altitude) < 0.1
                    {
                        // OutDebug(_params[1]:TypeName, 5).
                        // if _params[1]:IsType("List") OutDebug(_params[1][0]:TypeName, 6).
                        from { local i to 0.} until i = _params[2]:Length step { set i to i + 1.} do
                        {
                            if g_ShipUIDs:Contains(_params[2][i])
                            {
                                local m to _params[1][i].
                                if m:Name = "ModuleRCSFX" m:SetField("RCS", True).
                            }
                        }
                    }
                    // set l_SteeringDelegate_Standby to g_SteeringDelegate.
                    // set g_SteeringDelegate to { return Ship:Facing.}.
                    set Ship:Control:Roll to _params[4].
                    set g_SpinActive to True.
                }

                if g_SpinActive
                {
                    set keepAlive to True.
                }
                else
                {
                    set keepAlive to False.
                }

                return keepAlive.
            }.

            local spinEvent to lexicon().
            local spinEventID to "SPIN_{0}":Format(_spinDC:Stage).

            if not g_LoopDelegates:Events:HasKey(spinEventID)
            {
                set spinEvent to CreateLoopEvent(spinEventID, "SpinEvent", paramList, checkDel@, actionDel@).
                set resultFlag to RegisterLoopEvent(spinEvent).   
            }
        }

        return resultFlag.
    }
    // #endregion

    // -- Mass
    // #region

    // StageMass :: (<scalar>) -> <lexicon>
    // Returns a lex containing mass statistics for a given stage number
    global function GetStageMass
    {
        parameter stg.

        local stgMass to 0.

        //ISSUE: stgFuelMass appears to be about half (or at least, lower than) 
        //what it should be
        local stgFlowMass to 0.
        local stgFuelMass to 0.
        local stgFuelUsableMass to 0.
        local stgResidual to 0.
        local stgShipMass to 0.
        local totalResFlow to 0.
        
        local stgEngs    to GetEnginesForStage(stg).
        local stgDC      to GetEnginesDC(stgEngs).
        local nextDCStg  to choose stgDC:Stage if stgDC:IsType("Decoupler") else -1.
        local nextEngStg to GetNextEngineStage(stg).
        

        local engResUsed to lexicon(
            "RSRC", list()
            ,"RSDL", list()
            ,"FLOW", list()
        ).

        for eng in stgEngs {
            engResUsed:FLOW:Add(eng:MaxMassFlow).
            set stgFlowMass to stgFlowMass + eng:MaxMassFlow.

            local m to eng:GetModule("ModuleEnginesRF").
            local engResidual to m:GetField("predicted residuals").
            engResUsed:RSDL:Add(engResidual).

            for k in eng:ConsumedResources:Keys 
            {
                if not engResUsed:RSRC:Contains(k) engResUsed:RSRC:Add(k:replace(" ", "")).
            }
        }
        
        from { local i to 0.} until i >= engResUsed:RSDL:Length step { set i to i + 1.} do {
            local rsdl to engResUsed:RSDL[i].
            local flow to engResUsed:FLOW[i].
            local flowRes    to flow * (1 - rsdl).
            set totalResFlow to totalResFlow + flowRes.
        }
        set stgResidual to (stgFlowMass - totalResFlow) / stgFlowMass.

        // OutDebug("[GetStageMass][{0}] engResUsed:RSRC [{1}]":Format(stg, engResUsed:RSRC:Join(";")), crDbg()).

        for p in Ship:parts
        {
            // OutDebug("[GetStageMass][{0}] Processing part: [{1}]":Format(stg, p), crDbg()).
            if p:typeName = "Decoupler" 
            {
                if p:Stage <= stg set stgShipMass to stgShipMass + p:Mass.
                if p:Stage = stg set stgMass to stgMass + p:Mass.
                // OutDebug("[GetStageMass][{0}] Part is decoupler":Format(stg), crDbg()).
            }
            else if p:DecoupledIn <= stg
            {
                // OutDebug("[GetStageMass][{0}] Part <= stg":Format(stg), crDbg()).
                set stgShipMass to stgShipMass + p:Mass.
                if p:DecoupledIn >= nextDCStg // p:Stg <= stg and p:DecoupledIn >= nextDCStg and p:Stage <= stg // >= nextDCStg and p:DecoupledIn <= stg
                {
                    set stgMass to stgMass + p:Mass.
                }
            }

            if p:DecoupledIn <= stg and p:DecoupledIn >= nextDCStg and p:Resources:Length > 0 
            {
                for res in p:Resources
                {
                    if engResUsed:RSRC:Contains(res:Name) 
                    {
                        // print "Calculating: " + res:Name.
                        set stgFuelMass to stgFuelMass + (res:amount * res:density).
                    }
                }
                set stgFuelUsableMass to stgFuelMass * (1 - stgResidual).
            }
        }

        return lex("stage", stgMass, "fuel", stgFuelMass, "fuelActual", stgFuelUsableMass, "ship", stgShipMass).
    }

    // GetStageMass2 :: _stg<scalar>, [_shipStageCache<Lexicon>] -> shipStageCacheUpdated<Lexicon>
    // Utilizes cached data model
    global function GetStageMass2
    {
        parameter _stg,
                  _stgObject is g_ShipStageCache.

        local stgMass to 0.

        //ISSUE: stgFuelMass appears to be about half (or at least, lower than) 
        //what it should be
        local stgEngs to list().
        local stgFuelMass to 0.
        local stgShipMass to 0.
        local nextStg to Max(-1, _stg - 1).
        
        // Stage base caching
        if not _stgObject:HasKey(_stg)
        {
            _stgObject:Add(_stg, lexicon()).
        }

        if _stgObject[_stg]:HasKey("ENG")
        {
            set stgEngs to _stgObject[_stg]:ENG.
        }
        else
        {
            set stgEngs to GetEnginesForStage(_stg).
            set _stgObject[_stg]["ENG"] to stgEngs.
        }

        // Resources
        local engResUsed to list().
        if stgEngs:Length > 0
        {
            if _stgObject[_stg]:HasKey("FUELMASS")
            {
                set engResUsed to _stgObject[_stg]:FUELMASS.
            }
            else
            {       
                for eng in stgEngs
                {
                    for k in eng:ConsumedResources:Keys 
                    {
                        if not engResUsed:Contains(k) engResUsed:Add(k:replace(" ", "")).
                        if _stgObject[_stg]:HasKey("CONRES")
                        {
                            if not _stgObject[_stg]:CONRES:HasKey(k)
                            {
                                _stgObject[_stg]:CONRES:Add(k, eng:ConsumedResources[k]).
                            }
                        }
                    }
                }
            }
        }

        // Actual mass calculation
        local partMassObj to lexicon("STAGE", 0, "FUEL", 0, "SHIP", 0).

        if _stgObject[_stg]:HasKey("PARTMASS")
        {
            set partMassObj to _stgObject[_stg]:PARTMASS.
        }
        else
        {
            for p in Ship:Parts
            {
                if p:typeName = "Decoupler" 
                {
                    if p:Stage <= _stg set stgShipMass to stgShipMass + p:Mass.
                    if p:Stage = _stg set stgMass to stgMass + p:Mass.
                }
                else if p:DecoupledIn <= _stg
                {
                    set stgShipMass to stgShipMass + p:Mass.
                    if p:DecoupledIn = _stg
                    {
                        set stgMass to stgMass + p:Mass.
                    }
                }

                if p:DecoupledIn >= nextStg and p:Resources:Length > 0 
                {
                    for res in p:Resources
                    {
                        if engResUsed:Contains(res:Name) 
                        {
                            // print "Calculating: " + res:Name.
                            set stgFuelMass to stgFuelMass + (res:amount * res:density).
                        }
                    }
                }
            }

            set partMassObj to lexicon("stage", stgMass, "fuel", stgFuelMass, "ship", stgShipMass).
        }

        set _stgObject[_stg]["PARTMASS"] to partMassObj.

        return _stgObject.
    }

    // #endregion

    // ** Steering
    // #region

    // CheckReentryRollControl :: <none> -> (_effectiveRollValue)<Scalar>
    // Returns the current rotation value to apply to the current steering vector based on keyboard input 
    global function CheckReentryRollControl
    {
        local effectiveRollValue to r_Val.
        local rollModifierValue to 0.
        
        local l_Reentry_Control_Obj to lexicon(
            "CTRL_REF", l_rollControlRef
        ).

        local l_Reentry_Control_Priority_List to list().

        if g_TermChar <> ""
        {
            if g_TermChar = Terminal:Input:Backspace
            {
                set l_rollCheck to 0.
            }
            else if g_TermChar = Terminal:Input:DeleteRight
            {
                set l_rollCheck to 0.
                set r_Val to 0.
            }
            else if g_TermChar = "+"
            {
                set l_rollCheck to choose 0 if l_rollCheck < 0 else l_rollOffsets_UpperBound.
            }
            else if g_TermChar = "_"
            {
                set l_rollCheck to choose 0 if l_rollCheck > 0 else -l_rollOffsets_UpperBound.
            }
            else if g_TermChar = Terminal:Input:UpCursorOne
            {
                set l_rollCheck to Max(-(l_rollOffsets_UpperBound), Min(l_rollCheck + 1, l_rollOffsets_UpperBound)).
            }
            else if g_TermChar = Terminal:Input:RightCursorOne
            {
                set l_rollCheck to Max(-(l_rollOffsets_UpperBound), Min(l_rollCheck + 2, l_rollOffsets_UpperBound)).
            }
            else if g_TermChar = Terminal:Input:DownCursorOne
            {
                set l_rollCheck to Max(-(l_rollOffsets_UpperBound), Min(l_rollCheck - 1, l_rollOffsets_UpperBound)).
            }
            else if g_TermChar = Terminal:Input:LeftCursorOne
            {
                set l_rollCheck to Max(-(l_rollOffsets_UpperBound), Min(l_rollCheck + 2, l_rollOffsets_UpperBound)).
            }
            else if g_TermChar = ")"
            {
                set l_rollCheck to Max(-(l_rollOffsets_UpperBound), Min(l_rollCheck + 3, l_rollOffsets_UpperBound)).
            }
            else if g_TermChar = "}"
            {
                set l_rollCheck to Max(-(l_rollOffsets_UpperBound), Min(l_rollCheck + 5, l_rollOffsets_UpperBound)).
            }
            else if g_TermChar = "("
            {
                set l_rollCheck to Max(-(l_rollOffsets_UpperBound), Min(l_rollCheck - 3, l_rollOffsets_UpperBound)).
            }
            else if g_TermChar = "{"
            {
                set l_rollCheck to Max(-(l_rollOffsets_UpperBound), Min(l_rollCheck - 5, l_rollOffsets_UpperBound)).
            }
            set l_rollCheckTimeMark to Time:Seconds.
            set l_rollCheckTimestamp to l_rollCheckTimestamp + Min(1, l_rollCheckTimeMark - (l_rollCheckTimeStamp - l_rollCheckTimout)).
            set g_TermCharRead to True.
        }
        set l_rollCheckWeightAvg to Abs(Time:Seconds - l_rollCheckTimestamp).
        
        set rollModifierValue  to choose l_rollCheckObj:ROLL_OFFSETS[l_rollCheck] if l_rollCheck > 0 else -(l_rollCheckObj:ROLL_OFFSETS[Abs(l_rollCheck)]).
        
        if l_rollCheck <> 0
        {
            set effectiveRollValue to Mod(Ship:Facing:Roll + rollModifierValue, 360).
        }
        
        return effectiveRollValue.
    }

    local function UpdateReentryRollOffsets
    {
        parameter _pChar is g_TermChar. 

        local curRollPosition to VAng(Ship:Up:Vector, -Body:Position).
        local doneFlag to False.
        local effectiveOffset to l_rollOffset.
        local incr to 0.
        local sign to 0.
        
        from { local i to 0.} until i = g_rollCheckObj:CTRL_REF:Keys:Length or doneFlag step { set i to i + 1.} do
        {
            local refListId to g_rollCheckObj:CTRL_REF:Keys[i].

            if g_rollCheckObj:CTRL_REF[refListId]:Contains(_pChar)
            {
                set sign to (-1 + (g_rollCheckObj:CTRL_REF[refListId]:IndexOf(_pChar) * 2)).
                set incr to incr + (g_rollCheckObj:CTRL_REF:Keys[g_rollCheckObj:CTRL_REF:Keys:Find(refListId)] * sign).
                set doneFlag to True.
            }

            if refListId > 0
            {
                set effectiveOffset to curRollPosition + incr.
            }
            else
            {
                if sign > 0 
                {
                    set l_rollCheck to 0.
                    set l_rollCheckWeightAvg to 0.
                    l_rollCheckWeightAvgs:Clear().
                    set effectiveOffset to curRollPosition.
                }
                else
                {
                    set effectiveOffset to curRollPosition.
                }
            }
        }
        set r_Val to effectiveOffset.

        return effectiveOffset.
    }

    local function UpdateReentryRollOffsets_Old
    {
        parameter _pChar is g_TermChar. 

        local curRollPosition to VAng(Ship:Up:Vector, -Body:Position).
        local doneFlag to False.
        local effectiveOffset to l_rollOffset.
        local incr to 0.
        local sign to 0.
        local tgtTimeDelta to 0.
        
        local l_rollCheckWeightedAvg_UpperBound to l_rollCheckWeightAvgs:Length - 1.

        from { local i to 0.} until i = g_rollCheckObj:CTRL_REF:Keys:Length or doneFlag step { set i to i + 1.} do
        {
            local refListId to g_rollCheckObj:CTRL_REF:Keys[i].

            if g_rollCheckObj:CTRL_REF[refListId]:Contains(_pChar)
            {
                set sign to (-1 + (g_rollCheckObj:CTRL_REF[refListId]:IndexOf(_pChar) * 2)).
                set incr to incr + (g_rollCheckObj:CTRL_REF:Keys[g_rollCheckObj:CTRL_REF:Keys:Find(refListId)] * sign).
                set l_rollCheckTimestamp to Min(l_rollCheckTimestamp + 1, Time:Seconds + l_rollCheckTimout).
                set l_rollCheckTimeMark to Time:Seconds.
                
                l_rollCheckWeightAvgs:Add(Max(l_rollCheckWeightAvgs(0) * 1, 1)).
                
                set l_rollCheckTimestamp to l_rollCheckTimeMark + (1 + l_rollCheckTimeWindup).
                set doneFlag to True.
            }
            set tgtTimeDelta to Max(0, l_rollCheckTimestamp - l_rollCheckTimeMark).

            if refListId > 0
            {
                if l_rollCheckWeightAvgs:length > 8
                {
                    set l_rollCheckWeightAvg to (l_rollCheckWeightAvg * 8) - l_rollCheckWeightAvgs[l_rollCheckWeightedAvg_UpperBound].
                    l_rollCheckWeightAvgs:Remove(l_rollCheckWeightedAvg_UpperBound).
                }

                local curInputWeight to Max(l_rollCheckWindupLimit[0], Min(l_rollCheckWindupLimit[1], (tgtTimeDelta / l_rollCheckTimout) - 0.00125)).
                set l_rollCheckWeightAvg to (l_rollCheckWeightAvg + curInputWeight) / l_rollCheckWeightAvgs:Length.
                
                set l_rollCheck to Round(l_rollCheck + (g_rollCheckObj:CTRL_REF[l_rollCheck] * sign)).
                set effectiveOffset to curRollPosition + (l_rollCheckWeightAvg * (g_rollCheckObj:ROLL_OFFSETS[refListId])).
            }
            else
            {
                if sign > 0 
                {
                    set l_rollCheck to 0.
                    set l_rollCheckWeightAvg to 0.
                    l_rollCheckWeightAvgs:Clear().
                    set effectiveOffset to curRollPosition.
                }
                else
                {
                    set effectiveOffset to curRollPosition.
                }
            }
        }
        set r_Val to effectiveOffset.

        return sign.
    }

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
        // parameter _delDependency is lexicon().
        parameter _steerDelID is "Flat:Sun",
                  _fShape     is 1.075. // 0.975.

        local del to {}.

        if g_AzData:Length = 0
        {
            set g_AzData to l_az_calc_init(g_MissionTag:Params[1], g_MissionTag:Params[0]).
        }

        if g_AngDependency:Keys:Length = 0
        {
            set g_AngDependency to InitAscentAng_Next(g_MissionTag:Params[0], g_MissionTag:Params[1], _fShape, 5, 30, True, list(0.00275, 0.00125, 0.0075, 1)). // (tgtInc, tgtAp, _fShape, pitLimMin, pitLimMax, InitPid, PidInfo(P, I, D, ChangeRate (upper / lower bounds for PID))).
        }

        if _steerDelID = "Flat:Sun"
        {
            set del to { return Heading(compass_for(Ship, Ship:Prograde), 0, 0).}.
        }
        else if _steerDelID = "AngErr:Sun"
        {
            RunOncePath("0:/lib/launch.ks").
            // if g_Debug OutDebug("g_MissionTag:Params: {0}":Format(g_MissionTag:Params:Join(";"))).
            set del to GetAscentSteeringDelegate(g_MissionTag:Params[1], g_MissionTag:Params[0], g_AzData).
            // set del to { return Heading(l_az_calc(g_azData), GetAscentAng_Next(g_AngDependency) * _fShape, 0).}.
        }
        else if _steerDelID = "Apo:Sun"
        {
            RunOncePath("0:/lib/launch.ks").
            set del to { return Heading(l_az_calc(g_azData), pitch_for(Ship, Ship:Prograde), 0).}.
        }
        else if _steerDelID = "ApoErr:Sun"
        {
            RunOncePath("0:/lib/launch.ks").
            set del to { return Heading(l_az_calc(g_azData), GetAscentAng_Next(g_AngDependency), 0).}.
        }
        else if _steerDelID = "lazCalc:Sun"
        {
            set del to { return Ship:Facing.}.
        }
        else if _steerDelID = "PIDApoErr:Sun"
        {
            OutInfo("Transitioning to PIDApoErr:Sun guidance").
            set g_AngDependency:RESET_PIDS to True.
            set del to { 
                local pidPit to GetAscentAng_PIDyParty(g_AngDependency).
                DispPIDLoopValues(g_PIDS[g_AngDependency:APO_PID]).
                return Heading(l_az_calc(g_azData), pidPit, 0).
            }.
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
            set s_Val to Heading(90, 88, 0).
        }
    }
    // #endregion

    // ** Side Boosters
    // #region
    global function ArmBoosterStaging
    {
        set g_BoosterObj to lexicon().

        local BoosterParts to Ship:PartsTaggedPattern("(^booster)+((\||\.)\d*)+(\|AS)?").

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
            set g_BoostersArmed to False.
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
            set g_BoostersArmed to False.
        }
        return g_BoostersArmed.
    }

    global function ArmBoosterStaging_NextReally
    {
        set g_BoosterObj to lexicon().

        local boosterDCList to Ship:PartsTaggedPattern("Booster\|\d*").
        local armedFlag to False.

        if boosterDCList:Length > 0
        {
            from { local i to 0.} until i = boosterDCList:Length step { set i to i + 1.} do
            {
                local airStart to False.
                local ep to boosterDCList[i].
                local epTagSplit to ep:Tag:Split("|").

                local dcEventId to "DC_BOOSTER_0".
                local dcEventGenericID to "DC_BOOSTER".

                if epTagSplit:Length > 1 
                {
                    set dcEventID to "DC_BOOSTER_{0}":Format(epTagSplit[1]).
                    if epTagSplit:Length > 2 set airStart to True.
                }
                
                if not g_LoopDelegates:Events:HasKey(dcEventId)
                {
                    SetupDecoupleEventHandler(dcEventId, boosterDCList, dcEventGenericID).
                    set armedFlag to True.
                }
            }
        }
        return armedFlag.
    }


    global function ArmBoosterStaging_NewShinyNext
    {
        parameter _setId is -1.

        set g_BoosterObj to lexicon().

        if _setId < 0
        {
            if l_curBoosterSetId >= 0
            {
                set _setId to l_curBoosterSetId.
            }
            else
            {
                set _setId to 0.
                set l_curBoosterSetId to _setId.
            }
        }
        else
        {
            set l_curBoosterSetId to _setId.
        }

        local armedFlag to False.
        
        if Ship:PartsTaggedPattern("Booster\|\d+"):Length > 0
        {
            local doneFlag to False.
            local endAfterNext to False.
            from { local setId to _setId.} until doneFlag or setId > 9 step { set setId to setId + 1.} do
            {
                if endAfterNext 
                {
                    set doneFlag to true.
                }
                
                local dcRegex to "Booster\|{0}":Format(setId).
                local setDCList to Ship:PartsTaggedPattern(dcRegex).

                if setDCList:Length > 0 
                {
                    if setDCList[0]:Tag:EndsWith("AS")
                    {
                        local asEventId to "AS_BOOSTER_{0}":Format(setId).
                        local checkEventId to "DC_BOOSTER_{0}":Format(Max(0, setId - 1):ToString).
                        if not g_LoopDelegates:Events:HasKey(asEventId)
                        {
                            set g_BoosterAirStart to SetupBoosterAirStartHandler(setDCList, setId, checkEventId).
                        }
                    }
                    else
                    {
                        local dcEventID to "DC_BOOSTER_{0}":Format(setId).
                        local dcEventGenericID to "DC_BOOSTER".
                        if not g_LoopDelegates:Events:HasKey(dcEventId)
                        {
                            set armedFlag to SetupDecoupleEventHandler(dcEventId, setDCList, dcEventGenericID).
                        }
                    }
                    set endAfterNext to True.
                }
            }
        }
        return armedFlag.
    }

    // SetupBoosterAirstartHandler :: [_partList<List[Part]>] -> resultFlag<bool>
    global function SetupBoosterAirStartHandler
    {
        parameter _dcList is Ship:PartsTaggedPattern("(^Booster\|\d*)+(\|AS$)+"),
                  _setId is 0,
                  _checkId  is "".

        local asEngList to list().
        local resultFlag to False.
        if _checkId:Length = 0
        {
            set _checkId to "DC_BOOSTER_{0}":Format((Max(0, _setId - 1))).
        }

        if _dcList:Length > 0
        {
            // set _setId to _dcList[0]:Tag:Split("|")[1]:ToNumber(_setId).
            local asEventId to "AS_BOOSTER_{0}":Format(_setId).

            for p in _dcList
            {
                for m in p:ModulesNamed("ModuleEnginesRF")
                {
                    local mp to m:Part.
                    if not g_PartInfo:Engines:SepRef:Contains(mp:Name) or mp:Tag:Length > 0
                    {
                        asEngList:Add(mp).
                    }
                }
            }

            local paramList to list(asEventId, _dcList, asEngList, _setId, _checkId).

            local checkDel to {
                parameter _params is list().
                // OutInfo("[{0}] Checking for key: {1} [{2}] ":Format(Round(MissionTime, 2), _checkId, g_LoopDelegates:Events:HasKey(_params[4])), 1).
                return not g_LoopDelegates:Events:HasKey(_params[4]).
            }.

            local actionDel to {
                parameter _params is list().

                for eng in _params[2]
                {
                    if (not eng:Ignition and not eng:Flameout) // and eng:Ignitions > 0
                    {
                        eng:Activate.
                        if eng:Decoupler:Tag:EndsWith("|AS")
                        {
                            set eng:Decoupler:Tag to eng:Decoupler:Tag:Replace("|AS", "").
                        }
                    }
                }

                set g_BoostersArmed to ArmBoosterStaging_NewShinyNext(_params[3]).
                return False.
            }.

            local asEvent to CreateLoopEvent(asEventId, "AS_BOOSTER", paramList, checkDel@, actionDel@).
            set resultFlag to RegisterLoopEvent(asEvent).
        }

        return resultFlag.
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

        OutInfo("Processing booster tree for part: {0} ({1})":Format(_p:name, _p:UID)).

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
                "DC", lexicon(
                    dc:UID, lexicon(
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
        local as to False.
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
                ,"PARTS", lexicon()
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
                ,"RESLIST", list()
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

        local result to False.

        if g_BoostersArmed 
        {
            // writeJson(g_BoosterObj, "0:/data/g_boosterobj.json").
            // OutInfo("[{0,-7}]Boosters: [Armed(X)] [Set( )] [Update( )] [Cond( )]":Format(g_Counter)).
            // if g_BoosterObj:Keys:Length > 0
            // {
            //     OutInfo("[{0,-7}]Boosters: [Armed(X)] [Set(X)] [Update( )] [Cond( )]":Format(g_Counter)).
            //     local doneFlag to False.
            //     local ThrustThresh to 0.
            //     print g_BoosterObj:Keys at (2, 48).
            //     print g_BoosterObj[0] at (2, 50).
            //     from { local i to 0.} until i = g_BoosterObj:Keys:Length or doneFlag step { set i to i + 1.} do
            //     {
            //         local bSet to g_BoosterObj:Values[i].
            //         if not g_BoosterObj:Keys[i] = "UPDATE"
            //         {
            //             // local bSet to g_BoosterObj[g_BoosterObj:Keys[i]].
            //             if bSet:HasKey("UPDATE") 
            //             {
            //                 OutInfo("[{0,-7}]Boosters: [Armed(X)] [Set(X)] [Update(X)] [Cond( )]":Format(g_Counter)).
            //                 set g_BoosterObj to bSet:UPDATE:Call().
            //                 wait 0.01.
            //                 // writeJson(g_BoosterObj, Path("0:/data/g_BoosterObj.json")).
            //                 // local check to bSet["RES"]["PCTLEFT"] <= _pctThresh.
            //                 // OutInfo("BoosterStageCondition: {0} ({1})":Format(check, bSet["RES"]["PCTLEFT"]), 2).
            //                 // if bSet["RES"]["PCTLEFT"] <= _pctThresh
            //                 // if bSet["ENG"]:Values[0]:P:Thrust < 0.1
            //                 local bSetKey to bSet:Keys[i].
            //                 local engPresent to bSet:HasKey("Eng").
            //                 local allPresent to choose bSet["ENG"]:HasKey("AllThrust") if engPresent else False.
            //                 local avlPresent to choose bSet["ENG"]:HasKey("AvlThrust") if engPresent else False.

            //                 print "KEY [{0}] | ENG [{1}] | ALL [{2}] | AVL [{3}]":Format(bsetKey, engPresent, allPresent, avlPresent) at (0, 35).
            //                 set ThrustThresh to Max(ThrustThresh, bSet["ENG"]:AVLTHRUST * _pctThresh).
            //                 OutInfo("THRUST: {0} ({1})":Format(Round(bSet["ENG"]:ALLTHRUST, 2), Round(ThrustThresh, 2))).
            //                 if bSet["ENG"]:ALLTHRUST < ThrustThresh
            //                 {
            //                     OutInfo("[{0,-7}]Boosters: [Armed(X)] [Set(X)] [Update(X)] [Cond(X)]":Format(g_Counter)).
            //                     StageBoosterSet(i).
            //                     // set bSet to "".
            //                     wait 0.025.
            //                     g_BoosterObj:Remove(i).
            //                     wait 0.01.
                                
            //                     if g_BoosterObj:Keys:Length < 1
            //                     {
            //                         set g_BoostersArmed to False.
            //                     }
            //                     else
            //                     {
                                    
            //                     }
            //                     set doneFlag to true.
            //                 }
            //                 else
            //                 {
            //                     OutInfo("[{0,-7}]Boosters: [Armed(X)] [Set(X)] [Update(X)] [Cond(-)]":Format(g_Counter)).
            //                 }
            //             }
            //             else
            //             {
            //                 OutInfo("[{0,-7}]Boosters: [Armed(X)] [Set(X)] [Update(-)] [Cond( )]":Format(g_Counter)).
            //             }
            //         }
            //     }
            // }
            
            set result to (g_LoopDelegates["RegisteredEventTypes"]:HasKey("DC_BOOSTER")) or (g_LoopDelegates["RegisteredEventTypes"]:HasKey("AS_BOOSTER")).
        }
        return result.
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
            return False.
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
                        set boostersArmed to False.
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
            local result to False.

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
                    set g_FairingsArmed to False.
                    return False.
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
            parameter _fairings is list().

            if _fairings:Length > 0
            {
                for f in _fairings
                {
                    if f:IsType("Part") { set f to f:GETMODULE("ProceduralFairingDecoupler"). }
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
                return False.
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
                        return False.
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
                        set g_LESArmed to False.
                    }
                    return False.
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

    // ** Vessel Metadata
    // #region

    // GetShipUIDs :: <none> -> uidList<list>
    // Returns a list of UIDs for all parts currently on the vessel. Useful for ensuring a part exists before trying to take action on it.
    global function GetShipUIDs
    {
        local uidList to list().

        for p in ship:Parts
        {
            uidList:Add(p:UID).
        }

        return uidList.
    }
    // #endregion

// #endregion