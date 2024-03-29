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
                    // OutInfo("Failed Ignitions test [{0}]":Format(g_ActiveEngines_Spec:Ignitions), 1).
                    set useNext to True.
                }
                else if g_ActiveEngines_Spec:EstBurnTime <= g_ActiveEngines_Spec:SpoolTime + 0.25 
                {
                    // OutInfo("Failed burnTimeTest [{0}|{1}]":Format(Round(g_ActiveEngines_Spec:EstBurnTime, 2), Round(g_ActiveEngines_Spec:SpoolTime + 0.25, 2)), 1).
                    set useNext to True.
                }
                // else
                // {
                //     OutInfo("Passed checks for active engines", 1).
                // }
            }
            else
            {
                // OutInfo("Failed AllowRestart test [{0}]":Format(g_ActiveEngines_Spec:AllowRestart), 1).
                set useNext to True.
            }
            if useNext 
            {
                // OutInfo("Using NextEngines").
                set burnEngs to GetNextEngines(Stage:Number).
                set burnEngsSpec to GetEnginesSpecs(burnEngs).
            }
            else
            {
                // OutInfo("Using active engines").
                set burnEngs to g_ActiveEngines.
                set burnEngsSpec to g_ActiveEngines_Spec.
            }
            // Breakpoint().
            // set f_BurnUllage to burnEngsSpec:Ullage.
            // OutInfo("Ullage check: {0}":Format(f_BurnUllage), 1).
            // OutDebug("Engines: {0}":Format(g_ActiveEngines:Join(";")), 1).
            // Breakpoint().

            set burnEta to burnEta - burnEngsSpec:SpoolTime - (fullDur * 0.08). // This allows for spool time + adds a bit of buffer
            set g_MECO    to burnEta + fullDur.

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
            
            local burnLeadTime to UpdateTermScalar(15, list(1, 5, 15, 30)).
            local warpFlag to False.

            until time:seconds >= burnEta
            {
                if Kuniverse:TimeWarp = 0 set warpFlag to False.
                if not warpFlag OutMsg("Press Shift+W to warp to [maneuver - {0}s]":Format(burnLeadTime)).
                
                GetTermChar().

                wait 0.01.
                if g_TermChar = ""
                {
                }
                else if g_TermChar = Char(87)
                {
                    if _inNode:ETA > burnLeadTime 
                    {
                        set warpFlag to True. 
                        OutMsg("Warping to maneuver").
                        OutInfo().
                        OutInfo("", 1).
                        OutInfo("", 2).
                        WarpTo(burnEta - burnLeadTime).
                    }
                    else
                    {
                        OutMsg("Maneuver <= {0}s, skipping warp":Format(burnLeadTime)).
                    }
                    set g_TermChar to "".
                }
                else if g_TermChar = Char(82)
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
                    set burnLeadTime to UpdateTermScalar(burnLeadTime, list(1, 5, 15, 30)).
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
            
            local autoStageResult to ArmAutoStagingNext(g_StageLimit, 0.01, 0).
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

                DispBurnNodeData(dv, burnEta - time:seconds, burnTimeRemaining).
                DispBurnPerfData().

                if g_AutoStageArmed
                {
                    if g_LoopDelegates:HasKey("Staging")
                    {
                        OutInfo("Checking staging delegate", 2).
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
        local node_ta to AscNodeTA(burnVesObt, tgtObt).

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
            set burn_utc to time:seconds + ETAtoTA(burnVesObt, node_ta).
            if burn_utc > time:seconds + ship:orbit:period / 2 
            {
                set node_ta to mod(node_ta + 180, 360).
                set burn_utc to time:seconds + ETAtoTA(burnVes:obt, node_ta).
            }
        }
        else 
        {
            if node_ta < 90 or node_ta > 270 
            {
                set node_ta to mod(node_ta + 180, 360).
            }
            set burn_utc to time:seconds + ETAtoTA(burnVesObt, node_ta).
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

        set g_SteeringDelegate to choose retDel@ if burnDir = "Retrograde" else proDel@.
        set s_Val to g_SteeringDelegate:Call().
        lock steering to s_Val.

        until vAng(Ship:Facing:Vector, s_Val:Vector) <= 15
        {
            set s_Val to g_SteeringDelegate:Call().
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
                    set s_Val to g_SteeringDelegate:Call().
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