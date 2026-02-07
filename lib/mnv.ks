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
    // #endregion

    // *- Global
    // #region
    // #endregion
// #endregion


// *~ Functions ~* //
// #region
    // *- Maneuver Type Calcs
    // #region
    
    // AddLunarTransferNode :: [_minETA(seconds)<scalar>], [_tgtPe(m)<scalar>] -> mnvNode<Node>
    // Uses helpers to add a lunar transfer node to the flight plan
    global function AddLunarTransferNode
    {
        parameter _minETA is 0,
                  _tgtPe is 100000.

        local tgtAlt            to Moon:Orbit:Semimajoraxis - Earth:Radius - Moon:Radius - _tgtPe.
        local transPhase        to GetLunarTransferPhase(_tgtPe).
        // local currMeanAnomaly   to GetMeanAnomaly(Ship:Orbit).
        local timeToTransPhase  to GetTimeToPhase(transPhase, Moon, Ship, _minETA).

        local transMnvDv  to CalcDvBE(Ship:Periapsis, Ship:Apoapsis, Ship:Periapsis, tgtAlt, tgtAlt, "Ap", Earth).
        local transNode   to Node(Time:Seconds + timeToTransPhase, 0, 0, transMnvDv[0]).
        add transNode.

        return transNode.
    }

    // #endregion

    // *- Maneuver Calc Helpers (Local)
    // #region

    // GetLunarTransferPhase :: _arrivalAlt(m)<Scalar> -> transferPhase<scalar>
    // Returns a transfer phase to arrive at the desired altitude
    // https://ai-solutions.com/_freeflyeruniversityguide/interplanetary_hohmann_transfe.htm
    local function GetLunarTransferPhase
    {
        parameter _arrivalAlt.

        local arrivalSMA to choose _arrivalAlt + Moon:Radius if _arrivalAlt > 0 else 0.
        local tgtAlt to Moon:Orbit:SemiMajorAxis - arrivalSMA - Earth:Radius.
        local transSMA to GetTransferSMA(tgtAlt + Earth:Radius, Ship:Orbit:SemiMajorAxis).  
        local transPeriod to GetTransferPeriod(transSMA). // (2 * Constant:pi * Sqrt((transMnv:SMA^3) / Earth:Mu)).
        local tgtAngVelo to (360 / (2 * Constant:pi)) * (Earth:Mu / Moon:Orbit:SemiMajorAxis^3).

        if g_Debug { OutDebug("{0}: [{1}]":Format("_arrivalAlt", _arrivalAlt), -1).}
        if g_Debug { OutDebug("{0}: [{1}]":Format("arrivalSMA", Round(arrivalSMA))).}
        if g_Debug { OutDebug("{0}: [{1}]":Format("tgtAlt", Round(tgtAlt)), 1).}
        if g_Debug { OutDebug("{0}: [{1}]":Format("transSMA", Round(transSMA)), 2).}
        if g_Debug { OutDebug("{0}: [{1}]":Format("transPeriod", Round(transPeriod, 1)), 3).}
        if g_Debug { OutDebug("{0}: [{1}]":Format("tgtAngVelo", Round(tgtAngVelo, 15)), 4).}

        Breakpoint().

        if g_Debug { OutDebug("", -1).}
        if g_Debug { OutDebug().}
        if g_Debug { OutDebug("", 1).}
        if g_Debug { OutDebug("", 2).}
        if g_Debug { OutDebug("", 3).}
        if g_Debug { OutDebug("", 4).}
        wait 0.25.

        return 180 - (0.5 * transPeriod * tgtAngVelo). // Transfer Phase
    }

    // GetTimeToPhase :: _tgtPhase(deg)<Scalar>, _curPhase(deg)<Scalar>, [_minETA(s)<Scalar>] -> phaseETA(s)(Scalar) 
    local function GetTimeToPhase
    {
        parameter _tgtPhase,
                  _tgtObj,
                  _ogObj,
                  _minETA is 0.

        local phaseTS       to Time:Seconds + _minETA.
        local startPhase    to GetPhaseAngleAtTime(_tgtObj, _ogObj, phaseTS).
        local phaseDiff     to Mod(360 + _tgtPhase - startPhase, 360).
        local tgtMeanAngMotion  to (2 * Constant:Pi) / _tgtObj:Orbit:Period.
        local ogMeanAngMotion   to  (2 * Constant:Pi) / _ogObj:Orbit:Period.
        local timeToTgtPhase    to phaseDiff / Abs(tgtMeanAngMotion - ogMeanAngMotion).
        
        if g_Debug { OutDebug("{0}: [{1}]":Format("_tgtPhase", Round(_tgtPhase, 2)), -1).}
        if g_Debug { OutDebug("{0}: [{1}]":Format("startPhase", Round(startPhase, 2))).}
        if g_Debug { OutDebug("{0}: [{1}]":Format("phaseDiff", Round(phaseDiff, 2)), 1).}
        if g_Debug { OutDebug("{0}: [{1}]":Format("tgtMeanAngMotion", Round(tgtMeanAngMotion, 15)), 2).}
        if g_Debug { OutDebug("{0}: [{1}]":Format("ogMeanAngMotion", Round(ogMeanAngMotion, 15)), 3).}
        if g_Debug { OutDebug("{0}: [{1}]":Format("timeToTgtPhase", Round(timeToTgtPhase, 5)), 4).}

        Breakpoint().

        if g_Debug { OutDebug("", -1).}
        if g_Debug { OutDebug().}
        if g_Debug { OutDebug("", 1).}
        if g_Debug { OutDebug("", 2).}
        if g_Debug { OutDebug("", 3).}
        if g_Debug { OutDebug("", 4).}

        wait 0.25.

        return timeToTgtPhase + _minETA.
    }

    // #endregion

    // *- Maneuver Exec
    // #region

    // ExecNodeBurn :: _inNode<node> -> <none>
    // Given a node object, executes it
    global function ExecNodeBurn
    {
        parameter _inNode is node().

        local curEngs to list().
        local curEngsSpecs to lexicon().
        local dvRateList to list().
        local dvRate to 0.
        local dv to _inNode:deltaV:mag.
        local lastDv    to 0.
        local burnDur to list(0, 0).
        local burnEngs to list().
        local burnEngsSpec to lexicon().
        local fullDur to 0.
        local halfDur to 0.
        local burnEta to 0.
        lock dvRemaining to abs(dv).

        if dv <= 0.1 
        {
            OutMsg("No burn necessary").
        }
        else
        {
            set burnDur to CalcBurnDur(dv).
            set fullDur to burnDur[0].
            set halfDur to burnDur[3].
            
            set burnEta to _inNode:time - halfDur.
            
            set g_ActiveEngines to GetActiveEngines().
            set g_ActiveEngines_Spec to GetEnginesSpecs(g_ActiveEngines).

            local useNext to False.
            if g_ActiveEngines_Spec:AllowRestart
            {
                if g_ActiveEngines_Spec:Ignitions = 0
                {
                    set useNext to True.
                }
                //else if g_ActiveEngines_Spec:EstBurnTime <= g_ActiveEngines_Spec:SpoolTime + 0.25 
                else if g_ActiveEngines_Spec:BurnTimeRemaining <= g_ActiveEngines_Spec:SpoolTime + 0.25 
                {
                    set useNext to True.
                }
            }
            else
            {
                set useNext to True.
            }
            if useNext 
            {
                set burnEngs to GetNextEngines(Stage:Number).
                set burnEngsSpec to GetEnginesSpecs(burnEngs).
            }
            else
            {
                set burnEngs to g_ActiveEngines.
                set burnEngsSpec to g_ActiveEngines_Spec.
            }

            set burnEta to burnEta - burnEngsSpec:SpoolTime - (fullDur * 0.08). // This allows for spool time + adds a bit of buffer
            set g_MECO    to burnEta + fullDur.

            local rollUpVector to choose { return Body:Position.} if Ship:Crew:Length > 0 else { return -Body:Position.}.
            if Ship:CrewCapacity > 0
            {
                set rollUpVector to { return Body:Position. }.
            }
            else if Ship:ModulesNamed("ModuleROSolar"):Length > 0
            {
                set rollUpVector to { return Sun:Position. }.
            }

            set s_Val to lookDirUp(_inNode:burnvector, rollUpVector:Call()).
            set t_Val to 0.
            wait 0.01.
            lock steering to s_Val.
            
            local preSpin to 0.
            local spinArmed to False.
            local spinETA to -1.
            for p in Ship:PartsTaggedPattern("SpinDC")
            {
                OutInfo(fullDur + " | " + burnEngsSpec:BurnTimeRemaining, 2).
                if p:Stage = Stage:Number - 1 
                {
                    if fullDur > burnEngsSpec:EstBurnTime
                    {
                        local pSplit to p:Tag:Split("|").
                        set preSpin to choose pSplit[1]:ToNumber(10) if pSplit:Length > 1 else 10.
                        set spinETA to burnETA - preSpin.
                    }
                }
                set spinArmed to preSpin > 0.
            }

            local burnLeadTime to Max(preSpin * 1.125, UpdateTermScalar(15, list(1, 5, 15, 30))).
            local warpFlag to False.

            until Time:Seconds >= burnEta
            {
                if warp = 0 set warpFlag to False.
                if not warpFlag 
                {
                    OutMsg("Press Shift+W to warp to [maneuver - {0}s]":Format(burnLeadTime)).
                }
                else
                {
                    if Time:Seconds > burnETA - burnLeadTime
                    {
                        set warp to 0.
                    }
                }
                
                GetTermChar().

                wait 0.01.
                if g_TermChar = ""
                {
                }
                else if g_TermChar = Char(87) // 'W'
                {
                    if _inNode:ETA > burnLeadTime 
                    {
                        set warpFlag to True. 
                        OutMsg("Warping to maneuver").
                        clr(cr()).
                        if Kuniverse:TimeWarp:Mode = "PHYSICS"
                        {
                            set Warp to 0.
                            wait until KUniverse:TimeWarp:IsSettled.
                            set KUniverse:Timewarp:Mode to "RAILS".
                        }
                        WarpTo(burnEta - Min(15, burnLeadTime * 1.25)).
                    }
                    else
                    {
                        OutMsg("Maneuver <= {0}s, skipping warp":Format(burnLeadTime)).
                    }
                    set g_TermChar to "".
                }
                else if g_TermChar = Char(82) // 'R'
                {
                    OutInfo("Recalculating burn parameters").
                    OutInfo("", 1).
                    OutInfo("", 2).
                    wait 0.1.
                    set burnDur to CalcBurnDur(_inNode:deltaV:mag).
                    set fullDur to burnDur[0].
                    set halfDur to burnDur[3].

                    set burnEta to _inNode:time - halfDur. 
                    set g_MECO    to burnEta + fullDur.
                    set g_TermChar to "".
                }
                else if g_TermChar = Char(101) // 'e'
                {
                    set Ship:Control:Roll to Min(1, Max(-1, Ship:Control:Roll + 0.25)).
                    OutInfo("Spin Right: " + Ship:Control:Roll).
                }
                else if g_TermChar = Char(69) // 'E'
                {
                    set Ship:Control:Roll to 1.
                    OutInfo("Spin Right: " + Ship:Control:Roll).
                }
                else if g_TermChar = Char(113) // 'q'
                {
                    set Ship:Control:Roll to Min(1, Max(-1, Ship:Control:Roll - 0.25)).
                    OutInfo("Spin Left: " + Ship:Control:Roll).
                }
                else if g_TermChar = Char(81) // 'Q'
                {
                    set Ship:Control:Roll to -1.
                    OutInfo("Spin Left: " + Ship:Control:Roll).
                }
                else if g_TermChar = Char(115) // s
                {
                    set SteeringManager:RollTorqueFactor to choose 0 if SteeringManager:RollTorqueFactor > 0 else 1.
                }
                else if g_TermChar = Char(83) // S
                {
                    set Ship:Control:Roll to 0.
                }
                
                if not warpFlag 
                {
                    set burnLeadTime to Max(preSpin * 1.125, UpdateTermScalar(burnLeadTime, list(1, 5, 15, 30))).
                }

                if burnEngsSpec:Ullage
                {
                    set g_UllageTS to burnETA - g_UllageDefault.
                    // OutDebug("Ullage Armed (ETA: {0}s)":Format(Round(g_UllageTS - Time:Seconds, 2)), 4).
                    if Time:Seconds >= g_UllageTS
                    {
                        // OutDebug("Ullage Active", 4).
                        set Ship:Control:Fore to 1.
                    }
                }
                set s_Val to lookDirUp(_inNode:burnvector, rollUpVector:Call()).
                DispBurnNodeData(dv, burnEta - Time:Seconds, burnDur[0]).
                // OutInfo("Time Remaining: {0}s  ":Format(round(burnEta - Time:Seconds, 2)), 2).

                local settleProgress to 0.
                
                // Spin
                if preSpin > 0 
                {
                    set spinETA to burnETA - preSpin.
                    set preSpin to 0.
                }
                if spinArmed
                {
                    if Time:Seconds >= spinETA
                    {
                        set Ship:Control:Roll to 1.
                        set s_Val to _inNode:burnvector.
                    }
                    else if Time:Seconds >= burnETA - 0.01
                    {
                        set Ship:Control:Roll to 0.
                        set spinArmed to false.
                    }
                    else 
                    {
                        OutInfo("Spin Armed (T-{0}) ":Format(Round(spinETA - Time:Seconds, 2))).
                        set s_Val to lookDirUp(_inNode:burnvector, rollUpVector:Call()).
                    }
                }
                else
                {
                    set s_Val to lookDirUp(_inNode:burnvector, rollUpVector:Call()).
                    if settleProgress > 3
                    {
                        if VAng(Ship:Facing:Vector, _inNode:BurnVector) < 0.25
                        {
                            set settleProgress to settleProgress + 1.
                            wait 1.
                        }
                        else
                        {
                            set settleProgress to 0.
                        }
                        OutInfo("Settle Progress: [{0}] (3 needed)":Format(settleProgress)).
                    }
                }
                
                set g_TermChar to "".
            }

            local dv0 to _inNode:deltav.
            lock maxAcc to max(0.00001, ship:maxThrust) / ship:mass.

            OutMsg("Executing burn").
            OutInfo().
            OutInfo("", 1).
            OutInfo("", 2).
            ClearDispBlock().

            set g_ActiveEngines to GetActiveEngines().
            set g_ActiveEngines_Spec to GetEnginesSpecs(g_ActiveEngines).
            set g_ActiveEngines_Data to GetEnginesPerformanceData(g_ActiveEngines).
            
            local burnTimer         to Time:Seconds + burnDur[0].
            local burnTimeRemaining to burnDur[0].
            set t_Val to 1.
            lock throttle to t_Val.
            set s_Val to lookDirUp(_inNode:burnVector, rollUpVector:Call()).
            set Ship:Control:Fore to 0.
            
            local autoStageResult to ArmAutoStagingNext(g_StageLimit, 1, 1).
            if autoStageResult = 1 
            {
                set g_AutoStageArmed to True.
            }
            else
            {
                set g_AutoStageArmed to False.
            }
            OutInfo("AutoStage Armed; {0}":Format(g_AutoStageArmed)).
            SetupSpinStabilizationEventHandler().
            wait 0.01.
            set g_TS0 to Time:Seconds.
            set lastDV to _inNode:DeltaV.
            set dvRate to 0.
            
            local softShutdownDV to max(0.01, dvRate * (g_ActiveEngines_Spec:SpoolTime * 0.2)).
            until vdot(dv0, _inNode:DeltaV) <= softShutdownDV // 0.0025
            {   
                GetTermChar().
                set g_ActiveEngines to GetActiveEngines().
                set g_ActiveEngines_Spec to GetEnginesSpecs(g_ActiveEngines).
                set g_ActiveEngines_Data to GetEnginesPerformanceData(g_ActiveEngines).

                if g_ActiveEngines_Spec:SpoolTime > 0.1
                {
                    set softShutdownDV to dvRate * (g_ActiveEngines_Spec:SpoolTime * 0.1).
                }
                set burnTimeRemaining to burnTimer - Time:Seconds.
                
                set t_Val to max(0.02, min(_inNode:deltaV:mag / maxAcc, 1)).

                DispBurnNodeData(dv, burnEta - Time:Seconds, burnTimeRemaining).
                DispBurnPerfData().

                if g_AutoStageArmed
                {
                    if g_LoopDelegates:HasKey("Staging")
                    {
                        // OutInfo("Checking staging delegate", 2).
                        local stagingCheckResult to g_LoopDelegates:Staging:Check:Call().
                        if stagingCheckResult = 1
                        {
                            OutInfo("Staging", 2).
                            g_LoopDelegates:Staging["Action"]:Call().
                        }
                    }
                }
                
                if Stage:Number <= g_StageLimit
                {
                    OutInfo("AutoStaging disabled", 2).
                    DisableAutoStaging().
                }

                if g_LoopDelegates["Events"]:Keys:Length > 0 
                {
                    ExecGLoopEvents().
                }
                set g_TermChar to "".
            }
            set t_Val to 0.

            OutInfo("Maneuver Complete!").
            wait 1.
            ClearDispBlock().

            unlock steering.
        }

        remove _inNode.
    }

    // ExecNodeBurn_Next :: _inNode<node> -> <none>
    // Given a node object, executes it
    global function ExecNodeBurn_Next
    {
        parameter _inNode is node(),
                  _stageLimit is 0.

        local dv to _inNode:deltaV:mag.

        local burnUllageTime to 0.

        local curEngs to list().
        local curEngsSpecs to lexicon().
        local dvRateList to list().
        local dvRate to 0.
        local dvStagingArmed to false.
        local dvStagingPresent to false.
        local lastDv    to 0.
        local burnDur to list(0, 0).
        local burnEngs to list().
        local burnEngsSpec to lexicon().
        local fullDur to 0.
        local halfDur to 0.
        local preSpin to 0.
        local settleProgress to 0.
        local ullageExecTS to 0.
        local ullageFlag to false.
        local warpFlag to False.
        local warpAble to False.
        local ReacquireBurnVector to True.
        
        lock dvRemaining to abs(dv).

        local burnLeadTime   to 0.
        local burnLeadTS     to 0.
        local burnTS         to 0.
        local spinTS         to Time:Seconds + 999999.
        local ullageLeadSecs to 18.
        local ullageTS       to 0.
        local warpLeadSecs   to 3.
        local warpTS         to 0.

        if dv <= 0.1 
        {
            OutMsg("No burn necessary").
        }
        else
        {
            // Calculate Burn Times
            set burnDur to CalcBurnDur(dv).
            set fullDur to burnDur[0].
            set halfDur to burnDur[3].
            
            set burnTS to _inNode:Time - halfDur.
            
            set g_ActiveEngines to GetActiveEngines().
            set g_ActiveEngines_Spec to GetEnginesSpecs(g_ActiveEngines).

            local g_ActiveSpecs to lex("ALLOWRESTART", True, "IGNITIONS", 0, "BURNTIMEREMAINING", 0, "SPOOLTIME", 0, "ULLAGE", False).

            for eng in g_ActiveEngines
            {
                local engSpec to g_ShipEngines_Spec[eng:Stage]:EngSpecs[eng:UID].
                g_ActiveSpecs:Add(eng:UID, engSpec).

                if eng:AllowRestart
                {
                    set g_ActiveSpecs:IGNITIONS to eng:Ignitions.
                    if not g_ActiveSpecs:ULLAGE
                    {
                        set g_ActiveSpecs:ULLAGE to eng:Ullage.
                    }
                    // OutDebug("{0}: {1} | {2} | {3}":Format(eng:name, eng:AllowRestart, eng:Ignitions, eng:Ullage), 5).
                }
                else
                {
                    set g_ActiveSpecs:AllowRestart to False.
                    // OutDebug("{0}: {1} |":Format(eng:name, eng:AllowRestart), 5).
                }
            }
            set g_ActiveSpecs:BurnTimeRemaining to choose g_ActiveEngines_Spec:BurnTimeRemaining if g_ActiveEngines_Spec:BurnTimeRemaining > 0 else 0.
            
            local useNext to False.
            if g_ActiveSpecs:AllowRestart
            {
                if g_ActiveSpecs:Ignitions = 0
                {
                    // OutDebug("UseNext Reason: Ignitions = 0").
                    set useNext to True.
                }
                else if g_ActiveSpecs:BurnTimeRemaining <= g_ActiveSpecs:SpoolTime + 0.25 
                {
                    // OutDebug("UseNext Reason: ratedBurnTime <= SpoolTime + 0.25").
                    set useNext to True.
                }
            }
            else
            {
                // OutDebug("UseNext Reason: NoRestart Capability").
                set useNext to True.
            }

            if useNext 
            {
                set burnEngs to GetNextEngines().
                set burnEngsSpec to GetEnginesSpecs(burnEngs).
            }
            else
            {
                set burnEngs to g_ActiveEngines.
                set burnEngsSpec to g_ActiveSpecs.
            }
            // Initiate the burn with enough time for engine spoolup to occur.
            set burnTS to burnTS - (burnEngsSpec:spooltime * 1.06). // This allows for spool time + adds a bit of buffer

            // If ullage is needed, calcualate that TS here
            if burnEngsSpec:ULLAGE
            {
                set ullageFlag to true.
                set burnUllageTime to Max(6, ullageLeadSecs * (1 - burnEngs[0]:FuelStability)).
                set ullageTS to burnTS - burnUllageTime.
            }
            
            // Setup control
            local rollUpVector to { return -Body:Position.}.
            if Ship:CrewCapacity > 0
            {
                set rollUpVector to { return Body:Position. }.
            }
            else if Ship:ModulesNamed("ModuleROSolar"):Length > 0
            {
                set rollUpVector to { return Sun:Position. }.
            }

            set s_Val to lookDirUp(_inNode:burnvector, rollUpVector:Call()).
            set t_Val to 0.
            wait 0.01.
            lock steering to s_Val.
            
            // Determine which engines will be used to start the burn
            local ignitionsRemaining to 0.
            local nextBurnEngines to list().
            local predictedEngBurnTime to 0.

            if g_ActiveEngines:Length > 0
            {
                local engIgnsMax to { parameter _engs. local igns to 0. for eng in _engs { set igns to max(igns, eng:ignitions).} return igns. }.
                set nextBurnEngines to g_ActiveEngines.

                from { local _stg to Stage:Number. } until ignitionsRemaining > 0 or _stg < 0 step { set _stg to _stg - 1. } do
                {
                    set ignitionsRemaining to engIgnsMax:Call(nextBurnEngines).
                    if ignitionsRemaining = 0 
                    {
                        set g_NextEngines to GetNextEngines(_stg).
                        set nextBurnEngines to g_NextEngines.
                    }
                }
            } 
            else 
            {
                set g_NextEngines to GetNextEngines(Stage:Number).
                set nextBurnEngines to g_NextEngines.
            }
            set predictedEngBurnTime to GetPredictedBurnTime2(nextBurnEngines).
            OutDebug("PredictedEngBurnTime: {0}":Format(predictedEngBurnTime)).
            
            // Do we need to initiate spin stabilization prior to the burn?
            // if useNext
            // {

            // }
            
            
            for p in Ship:PartsTaggedPattern("SpinDC\|\d+")
            {
                OutInfo("SpinDC Found").
                local pSplit to p:Tag:Split("|").
                OutDebug(fullDur + " | " + burnEngsSpec:BurnTimeRemaining, 2).

                if p:Stage = Stage:Number - 1
                {
                    // if g_ActiveEngines:Length = 0 or ignitionsRemaining = 0
                    // {
                    //     OutInfo("Stage Correct").
                    //     set preSpin to choose pSplit[1]:ToNumber(18) if pSplit:Length > 1 else 12.
                    // }
                    // else
                    // {
                    //     local spinDur to choose pSplit[1]:ToNumber(18) if pSplit:Length > 1 else 12.
                    //     if fullDur - spinDur > predictedEngBurnTime
                    //     {
                    //         set preSpin to fullDur - spinDur.
                    //     }
                    // }
                    if g_ActiveEngines:Length = 0
                    {
                        OutInfo("Stage Correct").
                        if ignitionsRemaining = 0 
                        {
                            OutInfo("Setting preSpin").
                            set preSpin to choose pSplit[1]:ToNumber(12) if pSplit:Length > 1 else 12.
                        }
                    }
                    else
                    {
                        local spinDur to choose pSplit[1]:ToNumber(12) if pSplit:Length > 1 else 12.
                        if fullDur - spinDur >= predictedEngBurnTime
                        {
                            set preSpin to spinDur.
                        }
                    }
                }
                set spinTS to burnTS - preSpin.
                set g_SpinArmed to preSpin > 0.
            }
            
            // Determine the overall lead time required to be ready at burnTS
            set burnLeadTime   to 12 + Max(burnUllageTime, preSpin).
            set burnLeadTS     to burnTS - burnLeadTime.

            // Do we have any solid kick stages that 
            // require cutoff at a certain dV remaining? 
            if Ship:PartsTaggedPattern("dvst(g|age|aging)\|(dv|stg)\|\d*"):Length > 0
            {
                set dvStagingArmed to ArmDVStaging().
                OutInfo("dvStagingArmed: {0}":Format(dvStagingArmed), 2).
            }
            
            // Wait until the burn
            // Contains ullage and spin checks and actions
            local _line to 2.
            until time:seconds >= burnTS
            {
                set g_line to _line - 1.

                GetTermChar().

                // Recalculate burn ullage time based on current fuel stability
                if ullageFlag
                {
                    if Time:Seconds < ullageTS
                    {
                        set burnUllageTime to Max(1, 15 - (burnEngs[0]:FuelStability * 30)).
                        set ullageTS to burnTS - burnUllageTime.
                        set burnLeadTime to Max(burnLeadTime, burnUllageTime).
                        set burnLeadTS to ullageTS.
                    }
                    else 
                    {
                        set Ship:Control:Fore to 1.
                        if ullageExecTS = 0
                        {
                            set ullageExecTS to Time:Seconds.
                        }
                        else
                        {
                            if Time:Seconds <= burnTS - 1
                            {
                                set Ship:Control:Fore to Min(1, 0.2 + (1 - burnEngs[0]:FuelStability)).
                            }
                            else if Time:Seconds <= burnTS
                            {
                                set Ship:Control:Fore to 1.
                            }
                            else
                            {
                                set Ship:Control:Fore to 0.
                                set ullageExecTS to 0.
                            }
                        }
                    }
                }
                OutInfo("Burn ETA: Lead: {0}s | Ignition: {1} ":Format(burnLeadTime, TimeSpan(burnTS - Time:Seconds):Full)).

                if g_SpinArmed
                {
                    if Time:Seconds >= spinTS
                    {
                        set Ship:Control:Roll to 1.
                        OutInfo("Spin Started (T{0}) ":Format(Round(spinTS - Time:Seconds, 2)), 2).
                        set s_Val to _inNode:burnvector.
                    }
                    else if Time:Seconds >= burnTS
                    {
                        set Ship:Control:Roll to 0.
                        OutInfo("Spin Stopped                       ", 2).
                        set g_SpinArmed to false.
                    }
                    else if preSpin > 0
                    {
                        OutInfo("Spin Armed [{0}] (T-{1}) ":Format(Round(preSpin, 2), Round(spinTS - Time:Seconds, 2)), 2).
                        set s_Val to lookDirUp(_inNode:burnvector, rollUpVector:Call()).
                    }
                    else
                    {
                        OutInfo("", 2).
                        set s_Val to lookDirUp(_inNode:burnvector, rollUpVector:Call()).
                    }
                }
                else
                {
                    set s_Val to lookDirUp(_inNode:burnvector, rollUpVector:Call()).
                    if settleProgress > 3
                    {
                        if VAng(Ship:Facing:Vector, _inNode:BurnVector) < 0.25
                        {
                            set settleProgress to settleProgress + 1.
                            wait 1.
                        }
                        else
                        {
                            set settleProgress to 0.
                        }
                        OutInfo("Settle Progress: [{0}] (3 needed)":Format(settleProgress), 2).
                    }
                }

                local burnFlags to list().
                if ullageFlag burnFlags:Add("UL").
                if g_SpinArmed burnFlags:Add("SP").
                OutInfo("Burn Flags: [{0}] ":Format(burnFlags:Join("|")), 1).

                if warp = 0 
                {
                    wait until KUniverse:TimeWarp:IsSettled.
                    set warpFlag to False.
                }
                else if warp >= 1 and Time:Seconds > burnLeadTS - 15
                {
                    set warp to 0.
                }
                else if warp >= 2 and Time:Seconds > burnLeadTS - 45
                {
                    set warp to 1.
                }
                else if warp >= 3 and Time:Seconds > burnLeadTS - 120
                {
                    set warp to 2.
                }

                if not warpFlag 
                {
                    set warpAble to Time:Seconds < burnLeadTS - 15.
                    if warpAble 
                    {
                        OutMsg("Press Shift+W to warp to warpZone [maneuver - {0}s]":Format(Round(burnLeadTime + warpLeadSecs, 2))).
                    }
                    else
                    {
                        OutMsg("Warp Disallowed").
                    }
                }
                else
                {
                    if warpTS > burnLeadTS
                    {
                        OutInfo("warpTS > burnLeadTS, cancelling").
                        set KUniverse:TimeWarp:Rate to 0.
                        wait until KUniverse:TimeWarp:IsSettled.
                        set warpFlag to false.
                        if Time:Seconds < warpTS
                        {

                            set burnLeadTime   to 12 + Max(burnUllageTime, preSpin).
                            set burnLeadTS     to burnTS - burnLeadTime.
                            set warpTS to burnLeadTS - warpLeadSecs.
                            OutInfo("Reinitiating warp based on new burnLeadTS").
                            set warpFlag to true.
                            WarpTo(warpTS).
                        }
                    }
                    set warpAble to Time:Seconds < burnLeadTS - 15.
                }


                if g_TermChar = ""
                {
                }
                else
                {
                    if g_TermChar = Char(87) // 'W'
                    {
                        if warpAble
                        {
                            set warpFlag to True. 
                            OutMsg("Warping to maneuver").
                            clr(cr()).
                            if Kuniverse:TimeWarp:Mode = "PHYSICS"
                            {
                                set Warp to 0.
                                wait until KUniverse:TimeWarp:IsSettled.
                                set Kuniverse:Timewarp:Mode to "RAILS".
                            }
                            set warpTS to burnLeadTS - warpLeadSecs.
                            WarpTo(warpTS).
                        }
                        set g_TermChar to "".
                    }
                    else if g_TermChar = Char(82) // 'R'
                    {
                        OutInfo("Recalculating burn parameters").
                        clr(cr()).
                        clr(cr()).
                        wait 0.1.
                        set burnDur to CalcBurnDur(_inNode:deltaV:mag).
                        set fullDur to burnDur[0].
                        set halfDur to burnDur[3].

                        set burnTS to _inNode:time - halfDur. 
                        set g_TermChar to "".
                    }
                    else if g_TermChar = Char(101) // 'e'
                    {
                        set Ship:Control:Roll to Min(1, Max(-1, Ship:Control:Roll + 0.25)).
                        OutInfo("Spin Right: " + Ship:Control:Roll).
                    }
                    else if g_TermChar = Char(69) // 'E'
                    {
                        set Ship:Control:Roll to 1.
                        OutInfo("Spin Right: " + Ship:Control:Roll).
                    }
                    else if g_TermChar = Char(113) // 'q'
                    {
                        set Ship:Control:Roll to Min(1, Max(-1, Ship:Control:Roll - 0.25)).
                        OutInfo("Spin Left: " + Ship:Control:Roll).
                    }
                    else if g_TermChar = Char(81) // 'Q'
                    {
                        set Ship:Control:Roll to -1.
                        OutInfo("Spin Left: " + Ship:Control:Roll).
                    }
                    else if g_TermChar = Char(115) // s
                    {
                        set SteeringManager:RollTorqueFactor to choose 0 if SteeringManager:RollTorqueFactor > 0 else 1.
                    }
                    else if g_TermChar = Char(83) // S
                    {
                        set Ship:Control:Roll to 0.
                    }
                    else if g_TermChar = "="
                    {
                        set burnLeadTime to burnLeadTime + 5.
                    }
                    else if g_TermChar = "-"
                    {
                        set burnLeadTime to burnLeadTime - 5.
                    }
                    else if g_TermChar = "+"
                    {
                        set burnLeadTime to burnLeadTime + 5.
                    }
                    else if g_TermChar = "_"
                    {
                        set burnLeadTime to burnLeadTime - 5.
                    }
                    set g_TermChar to "".
                }
                // OutInfo("Mnv | Eng Time : {0} | {1}":Format(Round(burnDur[0], 2), Round(g_ActiveSpecs:RATEDBURNTIME, 2)), 2).
            }

            local dv0 to _inNode:deltav.
            lock maxAcc to max(0.00001, ship:maxThrust) / ship:mass.
            
            // ClearScreen.
            OutMsg("Executing burn").
            
            set g_ActiveEngines to GetActiveEngines().
            set g_ActiveSpecs to lex("ALLOWRESTART", false, "IGNITIONS", 0, "BURNTIMEREMAINING", 0, "SPOOLTIME", 0).
            for eng in g_ActiveEngines
            {
                local engSpec to g_ShipEngines_Spec[eng:Stage]:EngSpecs[eng:UID].
                if not g_ActiveSpecs:ALLOWRESTART set g_ActiveSpecs:ALLOWRESTART to eng:ALLOWRESTART.
                set g_ActiveSpecs:IGNITIONS to max(g_ActiveSpecs:IGNITIONS, eng:IGNITIONS).
                set g_ActiveSpecs:SPOOLTIME to max(g_ActiveSpecs:SPOOLTIME, g_ShipEngines_Spec[eng:Stage]:EngSpecs[eng:UID]:SPOOLTIME).
                g_ActiveSpecs:Add(eng:UID, engSpec).
            }
            set g_ActiveEngines_Data to GetEnginesPerformanceData(g_ActiveEngines).

            local burnTimeRemaining to burnDur[0].
            set t_Val to 1.
            lock throttle to t_Val.
            set s_Val to lookDirUp(_inNode:burnVector, rollUpVector:Call()).
            set Ship:Control:Fore to 0.
            set Ship:Control:Roll to 0.
            
            local autoStageResult to ArmAutoStagingNext(_stageLimit, 1, 2).
            if autoStageResult = 1 
            {
                set g_AutostageArmed to True.
                OutInfo("AutoStage Armed", 1).
            }
            else
            {
                set g_AutostageArmed to False.
            }

            set g_HotStagingArmed to ArmHotStaging().
            set g_SpinArmed to SetupSpinStabilizationEventHandler().
            
            wait 0.01.
            set burnLeadTS to Time:Seconds.
            set lastDV to _inNode:DeltaV.
            set dvRate to 0.
            
            // ClearScreen.

            local burnNode to _inNode.

            local breakFlag to false.
            local softShutdownDV to max(0.05, dvRate * (g_ActiveSpecs:SpoolTime * 0.2)).
            until vdot(dv0, burnNode:DeltaV) <= softShutdownDV or breakFlag// 0.0025
            {   
                if HasNode
                {    
                    set g_line to _line - 1.
                    GetTermChar().
                    
                    set g_ActiveEngines to GetActiveEngines().
                    set g_ActiveSpecs to GetEnginesSpecs(g_ActiveEngines).
                    set g_ActiveEngines_Data to GetEnginesPerformanceData(g_ActiveEngines).
                    if g_ActiveSpecs:Keys:Length > 0
                    {
                        // set g_ActiveSpecs to g_ActiveSpecs:Values[0].
                        set g_ActiveEngines_Data to GetEnginesPerformanceData(g_ActiveEngines).

                        if g_ActiveSpecs:SpoolTime > 0.1
                        {
                            set softShutdownDV to dvRate * (g_ActiveSpecs:SpoolTime * 0.1).
                        }
                    }
                    
                    // set burnTimeRemaining to GetEnginesBurnTimeRemaining_Next(g_ActiveEngines). //CalcBurnDur(NextNode:DeltaV:Mag)[0].
                    // set burnTimeRemaining to GetEnginesBurnTimeRemaining(g_ActiveEngines). //CalcBurnDur(NextNode:DeltaV:Mag)[0].
                    // set burnTimeRemaining to CalcBurnDur(NextNode:DeltaV:Mag)[0].
                    set burnTimeRemaining to CalcBurnDur(NextNode:DeltaV:Mag)[0].
                    
                    set t_Val to max(0.01, min(burnNode:deltaV:mag / maxAcc, 1)).

                    DispBurnNodeData(dv, burnTS - time:seconds, burnTimeRemaining).
                    DispBurnPerfData().

                    if ReacquireBurnVector
                    {
                        set burnNode to nextNode.
                        set s_Val to lookDirUp(burnNode:burnVector, rollUpVector:Call()).
                        OutInfo("BurnVector Acquired", 2).
                        set ReacquireBurnVector to False.
                        OutInfo("", 2).
                    }

                    if g_LoopDelegates:HasKey("Staging")
                    {
                        if dvStagingArmed
                        {
                            if g_LoopDelegates:Staging:HasKey("DVStaging")
                            {
                                if g_LoopDelegates:Staging:DVStaging:Check:Call()
                                {
                                    g_LoopDelegates:Staging:DVStaging:Action:Call().
                                    set dvStagingArmed to False.
                                }
                            }
                        }
                        
                        if g_HotStagingArmed and g_NextHotStageID = Stage:Number - 1
                        { 
                            if g_LoopDelegates:Staging:HotStaging:HasKey(g_NextHotStageID)
                            {
                                if g_LoopDelegates:Staging:HotStaging[g_NextHotStageID]:Check:Call()
                                {
                                    g_LoopDelegates:Staging:HotStaging[g_NextHotStageID]:Action:Call().
                                }
                            }
                        }
                        else
                        {
                            local stagingCheckResult to g_LoopDelegates:Staging:Check:Call().
                            // OutInfo("Checking staging delegate {0}":Format(stagingCheckResult), 2).
                            if stagingCheckResult = 1
                            {
                                OutInfo("Staging", 2).
                                g_LoopDelegates:Staging:Action:Call().
                            }
                        }
                    }

                    if not HomeConnection:IsConnected() and Time:Seconds > g_TS2
                    {
                        if Ship:ModulesNamed("ModuleDeployableAntenna"):Length > 0
                        {
                            local commModules to Ship:ModulesNamed("ModuleDeployableAntenna").
                            from { local i to commModules:Length - 1. local doneFlag to False.} until doneFlag step { set i to i - 1.} do
                            {
                                if DoEvent(commModules[i], "extend antenna")
                                {
                                    set doneFlag to true.
                                    set g_TS2 to Time:Seconds + 5.
                                }
                            }
                        }
                    }
                    else
                    {
                        set g_TS2 to Time:Seconds + 15.
                    }
                    
                    if Stage:Number <= _stageLimit and g_AutoStageArmed
                    {
                        DisableAutoStaging().
                        OutInfo("AutoStaging disabled", 2).
                    }

                    if g_TermChar = Char(101) // 'e'
                    {
                        set Ship:Control:Roll to Min(1, Max(-1, Ship:Control:Roll + 0.25)).
                        OutInfo("Spin Right: " + Ship:Control:Roll, 2).
                    }
                    else if g_TermChar = Char(69) // 'E'
                    {
                        set Ship:Control:Roll to 1.
                        OutInfo("Spin Right: " + Ship:Control:Roll, 2).
                    }
                    else if g_TermChar = Char(113) // 'q'
                    {
                        set Ship:Control:Roll to Min(1, Max(-1, Ship:Control:Roll - 0.25)).
                        OutInfo("Spin Left: " + Ship:Control:Roll, 2).
                    }
                    else if g_TermChar = Char(81) // 'Q'
                    {
                        set Ship:Control:Roll to -1.
                        OutInfo("Spin Left: " + Ship:Control:Roll, 2).
                    }
                    else if g_TermChar = Char(115) // s
                    {
                        set SteeringManager:RollTorqueFactor to choose 0 if SteeringManager:RollTorqueFactor > 0 else 1.
                        OutInfo("SpinTorque: {0}":Format(SteeringManager:RollTorqueFactor), 2).
                    }
                    else if g_TermChar = Char(83) // S
                    {
                        set Ship:Control:Roll to 0.
                        OutInfo("", 2).
                    }
                    else if g_TermChar = Terminal:Input:DeleteRight
                    {
                        set breakFlag to true.
                        OutInfo("User cancelled node burn", 2).
                    }
                    else if g_TermChar = Terminal:Input:HomeCursor
                    {
                        set ReacquireBurnVector to True.
                        OutInfo("Reacquiring BurnVector", 2).
                    }

                    OutInfo("BurnTime Remaining: {0} ":Format(Round(burnTimeRemaining, 1))).

                    if Stage:Number <= g_StageLimit
                    {
                        OutInfo("AutoStaging disabled", 2).
                        DisableAutoStaging().
                    }
                    
                    if g_LoopDelegates["Events"]:Keys:Length > 0 
                    {
                        ExecGLoopEvents().
                    }
                    set g_TermChar to "".

                    if Ship:AvailableThrust = 0 and not g_AutoStageArmed
                    {
                        set breakFlag to true.
                    }
                }
                else
                {
                    set breakFlag to true.
                }
            }
            set Ship:Control:Roll to 0.
            unlock steering.

            set t_Val to 0.
            set Ship:Control:MainThrottle to 0.
            set Ship:Control:PilotMainThrottle to 0.
            unlock throttle.
            
            ClearDispBlock().
            OutMsg("Maneuver Complete!").
            OutInfo().
            OutInfo("", 1).
            OutInfo("", 2).
        }

        remove _inNode.
    }

    // MatchIncBurn :: <ship>, <orbit>, <orbit>, [<bool>] -> <list>
    // Return an object containing all parameters needed for a maneuver
    // to change inclination from orbit 0 to orbit 1. Returns a list:
    // - [0] (nodeAt)     - center of burn node
    // - [1] (burnVector) - dV vector including direction and mag
    // - [2] (nodeStruc)  - A maneuver node structure for this burn
    global function MatchTargetInclination
    {
        parameter burnVes,      // Vessel that will perform the burn
                  burnVesObt,   // The orbit where the burn will take place. This may not be the current orbit
                  tgtObt,       // target orbit to match
                  nearestNode is false. // If true, choose the nearest of AN / DN, not the cheapest

        // Variables
        local burn_utc to 0.

        // Normals
        local ves_nrm to kslib_nav_obt_normal(burnVesObt).
        local tgt_nrm to kslib_nav_obt_normal(tgtObt).

        // Total inclination change
        local d_inc to vang(ves_nrm, tgt_nrm).

        // True anomaly of ascending node
        local node_ta to GetAscNodeTA(burnVesObt, tgtObt).

        // ** IMPORTANT ** - Below is the "right" code, I am testing picking the soonest vs most efficient
        // Pick whichever node of AN or DN is higher in altitude,
        // and thus more efficient. node_ta is AN, so if it's 
        // closest to Pe, then use DN 
        // if node_ta < 90 or node_ta > 270 
        // {
        //     set node_ta to mod(node_ta + 180, 360).
        // }

        // Get the burn eta. If nearestNode flag is set, choose the node with 
        // soonest ETA. Else, choose the cheapest node.
        if nearestNode 
        {
            set burn_utc to Time:Seconds + ETAtoTA(burnVesObt, node_ta).
            if burn_utc > Time:Seconds + ship:orbit:period / 2 
            {
                set node_ta to mod(node_ta + 180, 360).
                set burn_utc to Time:Seconds + ETAtoTA(burnVes:obt, node_ta).
            }
        }
        else 
        {
            if node_ta < 90 or node_ta > 270 
            {
                set node_ta to mod(node_ta + 180, 360).
            }
            set burn_utc to Time:Seconds + ETAtoTA(burnVesObt, node_ta).
        }

        // Get the burn unit direction (burnvector direction)
        local burn_unit to (ves_nrm + tgt_nrm):normalized.

        // Get deltav / burnvector magnitude
        local vel_at_eta to velocityAt(burnVes, burn_utc):orbit.
        local burn_mag to -2 * vel_at_eta:mag * cos(vang(vel_at_eta, burn_unit)).

        // Get the dV components for creating the node structure
        local burn_nrm to burn_mag * cos(d_inc / 2).
        local burn_pro to 0 - abs(burn_mag * sin( d_inc / 2)).

        // Create the node struct
        local mnv_node to node(burn_utc, 0, burn_nrm, burn_pro).

        return list(burn_utc, burn_mag * burn_unit, mnv_node, burn_mag, burn_unit).
    }
  // #endregion

    // *- Retro Manuevers
    // #region

    // ExecRetroBurn :: <none> -> _peInAtmo<bool>
    global function ExecStagedRetro
    {
        clearScreen.
        print "Executing staged retro burn".
        print "Current Periapsis: {0}m":Format(Round(Ship:Periapsis)).
        print "---".

        local burnDir           to "Retrograde".
        local retroMotors       to Ship:PartsTaggedPattern("RetroMotor").
        local retroMotorSpecs   to lexicon().
        local retrosArmed       to False.

        if retroMotors:Length > 0
        {
            if core:tag:contains("Pro") or vAng(retroMotors[0]:Facing:Vector, Ship:Facing:Vector) < 90
            {
                set burnDir to "Prograde".
            }
            set retroMotorSpecs to GetShipEnginesSpecs(retroMotors).
            set retrosArmed to True.
        }

        print "Aligning to {0}} for retro fire":Format(burnDir).
        local proDel to { return Ship:Prograde.}.
        local retDel to { return Ship:Retrograde.}.

        RCS On.
        For m in Ship:ModulesNamed("ModuleRCSFX")
        {
            m:SetField("RCS", True).
        }

        local s_ValDelegate to choose retDel@ if burnDir = "Retrograde" else proDel@.
        set s_Val to s_ValDelegate:Call().
        lock steering to s_Val.

        until vAng(Ship:Facing:Vector, s_Val:Vector) <= 15
        {
            set s_Val to s_ValDelegate:Call().
            wait 0.25.
        }

        print "Retro fire alignment complete".
        wait 0.25.

        print "Ignition sequence start".
        local retros to ship:PartsTaggedPattern("RetroMotor").

        if retrosArmed
        {
            for eng in retros 
            { 
                if not eng:Ignition eng:Activate.
            }
            wait 0.01.
            if Ship:AvailableThrust > 0
            {
                print "Ignition sequence success".
                until Ship:AvailableThrust <= 0.1
                {
                    set s_Val to s_ValDelegate:Call().
                }
            }
        }
        else
        {
            set Ship:Control:Fore to choose (1) if burnDir = "Retrograde" else -1.
            // set t_Val to 1.
            
            // wait 0.01.
            // for eng in Ship:Engines
            // {
            //     if not eng:Ignition { eng:Activate.}
            // }
            // wait 0.01.
        }

        local doneFlag to False.
        set g_TS to Time:Seconds + 60.
        until doneFlag or Time:Seconds >= g_TS
        {
            if retrosArmed
            {
                if Ship:AvailableThrust < 0.01 set doneFlag to True.
            }
            wait 0.1.
        }
        print "-".
        print "Retro burn complete!".
        print "New Periapsis: {0}m":Format(Round(Ship:Periapsis)).
        if Ship:Periapsis <= Body:Atm:Height
        {
            return True.
        }
        else
        {
            return False.
        }
    }
    // #endregion
// #endregion