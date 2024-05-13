// #include "0:/lib/depLoader.ks"
@LazyGlobal off.

// ***~~~ Dependencies ~~~*** //
// #region
// #endregion


// ***~~~ Variables ~~~*** //
// #region
    
    // *- Local
    // #region
    // #endregion

    // *- Global
    // #region
    // #endregion
// #endregion

// ***~~~ Delegate Objects ~~~*** //
    // *- Local Anonymous Delegates
    // #region
    // #endregion

    // *- Global Anonymous Delegates
    // #region
    // #endregion
// #endregion


// ***~~~ Functions ~~~*** //
// #region

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
        local preSpin to 0.
        local ullageFlag to false.
        local ullageSafe to false.
        
        lock dvRemaining to abs(dv).

        local ts0 to 0.
        local ts1 to Time:Seconds * 1.25.

        if dv <= 0.1 
        {
            OutMsg("No burn necessary", cr()).
        }
        else
        {
            set burnDur to CalcBurnDur(dv).
            set fullDur to burnDur[0].
            set halfDur to burnDur[3].
            
            set burnEta to _inNode:Time - halfDur.
            
            set g_ActiveEngines to GetActiveEngines().
            local g_ActiveSpecs to lex("ALLOWRESTART", false, "IGNITIONS", 0, "RATEDBURNTIME", 0, "SPOOLTIME", 0).

            for eng in g_ActiveEngines
            {
                local engSpec to g_ShipEngines:ENGUID[eng:UID].
                
                g_ActiveSpecs:Add(eng:UID, engSpec).
            }
            
            local useNext to False.
            if g_ActiveSpecs:AllowRestart
            {
                if g_ActiveSpecs:Ignitions = 0
                {
                    set useNext to True.
                }
                else if g_ActiveSpecs:RatedBurnTime <= g_ActiveSpecs:SpoolTime + 0.25 
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
                set burnEngs to GetNextEngines("1100").
                set burnEngsSpec to GetEnginesSpecs(burnEngs):IGNSTG[burnEngs[0]:Stage].
            }
            else
            {
                set burnEngs to g_ActiveEngines.
                set burnEngsSpec to g_ActiveSpecs.
            }

            
            set burnEta to burnEta - (burnEngsSpec:STGMAXSPOOL * 1.1). // This allows for spool time + adds a bit of buffer

            if burnEngsSpec:ULLAGE
            {
                set ullageFlag to true.
                set ts0 to burnETA - 8.
            }
            // local MECO    to burnEta + halfDur.

            local rollUpVector to { return -Body:Position.}.
            if Ship:CrewCapacity > 0
            {
                set rollUpVector to { return Body:Position. }.
            }
            else if Ship:ModulesNamed("ModuleROSolar"):Length > 0
            {
                set rollUpVector to { return Sun:Position. }.
            }

            set g_Steer to lookDirUp(_inNode:burnvector, rollUpVector:Call()).
            set g_Throt to 0.
            wait 0.01.
            lock steering to g_Steer.
            
            set g_NextEngines to GetNextEngines("1100").

            for p in Ship:PartsTaggedPattern("SpinDC")
            {
                if p:Stage = Stage:Number - 1
                {
                    if fullDur > GetPredictedBurnTime(g_NextEngines)
                    {
                        local pSplit to p:Tag:Split("|").
                        set preSpin to choose pSplit[1]:ToNumber(12) if pSplit:Length > 1 else 12.
                    }
                }
                set g_Spin_Armed to preSpin > 0.
            }

            local burnPreLead to 12.
            local burnLeadTime to Max(burnPreLead, preSpin + 10).

            local warpFlag to False.


            local _line to 2.
            until time:seconds >= burnEta
            {
                set g_line to _line - 1.

                if Kuniverse:TimeWarp = 0 
                {
                    set warpFlag to False.
                }
                
                if not warpFlag OutMsg("Press Shift+W to warp to [maneuver - {0}s]":Format(burnLeadTime), cr()).
                
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
                        OutMsg("Warping to maneuver", cr()).
                        clr(cr()).
                        if Kuniverse:TimeWarp:Mode = "PHYSICS"
                        {
                            set Warp to 0.
                            wait until KUniverse:TimeWarp:IsSettled.
                            Set KUniverse:Timewarp:Mode to "RAILS".
                        }
                        WarpTo(burnEta - Max(burnLeadTime * 1.1, preSpin * 1.1)).
                    }
                    else
                    {
                        OutMsg("Maneuver <= {0}s, skipping warp":Format(burnLeadTime), cr()).
                    }
                    set g_TermChar to "".
                }
                else if g_TermChar = Char(82)
                {
                    OutInfo("Recalculating burn parameters").
                    clr(cr()).
                    clr(cr()).
                    wait 0.1.
                    set burnDur to CalcBurnDur(_inNode:deltaV:mag).
                    set fullDur to burnDur[0].
                    set halfDur to burnDur[3].

                    set burnEta to _inNode:time - halfDur. 
                    set MECO    to burnEta + fullDur.
                    set g_TermChar to "".
                }
                else if g_TermChar = Char(101) // 'e'
                {
                    set Ship:Control:Roll to Min(1, Max(-1, Ship:Control:Roll + 0.25)).
                    OutInfo("Spin Right: " + Ship:Control:Roll, cr()).
                }
                else if g_TermChar = Char(69) // 'E'
                {
                    set Ship:Control:Roll to 1.
                    OutInfo("Spin Right: " + Ship:Control:Roll, cr()).
                }
                else if g_TermChar = Char(113) // 'q'
                {
                    set Ship:Control:Roll to Min(1, Max(-1, Ship:Control:Roll - 0.25)).
                    OutInfo("Spin Left: " + Ship:Control:Roll, cr()).
                }
                else if g_TermChar = Char(81) // 'Q'
                {
                    set Ship:Control:Roll to -1.
                    OutInfo("Spin Left: " + Ship:Control:Roll, cr()).
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
                    set burnPreLead to burnPreLead + 5.
                }
                else if g_TermChar = "-"
                {
                    set burnPreLead to burnPreLead - 5.
                }
                else if g_TermChar = "+"
                {
                    set burnPreLead to burnPreLead + 5.
                }
                else if g_TermChar = "_"
                {
                    set burnPreLead to burnPreLead - 5.
                }
                
                if not warpFlag 
                {
                    set burnLeadTime to Max(burnPreLead, preSpin + 10).
                }

                local timeDelta to TimeSpan(burnEta - Time:Seconds):Full.
                OutInfo("Burn Actual ETA: {0} ":Format(timeDelta), cr()).
                
                local leadTime to choose TimeSpan(timeDelta - burnLeadTime):Full if timeDelta > burnLeadTime else "N/A".
                OutInfo("Burn Lead Time : {0} ":Format(leadTime), cr()).

                if ullageFlag
                {
                    if Time:Seconds >= ts0
                    {
                        set Ship:Control:Fore to 1.
                    }
                }

                if preSpin > 0 
                {
                    set ts1 to burnETA - preSpin.
                    set preSpin to 0.
                }
                if g_Spin_Armed
                {
                    if Time:Seconds >= ts1
                    {
                        set Ship:Control:Roll to 1.
                        set g_Steer to _inNode:burnvector.
                    }
                    else if Time:Seconds >= burnETA
                    {
                        set Ship:Control:Roll to 0.
                        set g_Spin_Armed to false.
                    }
                    else 
                    {
                        OutInfo("Spin Armed (T-{0}) ":Format(Round(ts1 - Time:Seconds, 2))).
                        set g_Steer to lookDirUp(_inNode:burnvector, rollUpVector:Call()).
                    }
                }
                else
                {
                    set g_Steer to lookDirUp(_inNode:burnvector, rollUpVector:Call()).
                }

                set g_TermChar to "".
            }

            
            local dv0 to _inNode:deltav.
            lock maxAcc to max(0.00001, ship:maxThrust) / ship:mass.

            ClearScreen.

            OutMsg("Executing burn", cr()).
            
            set g_ActiveEngines to GetActiveEngines().
            set g_ActiveSpecs to lex("ALLOWRESTART", false, "IGNITIONS", 0, "RATEDBURNTIME", 0, "SPOOLTIME", 0).
            for eng in g_ActiveEngines
            {
                local engSpec to g_ShipEngines:ENGUID[eng:UID].
                if not g_ActiveSpecs:ALLOWRESTART set g_ActiveSpecs:ALLOWRESTART to eng:ALLOWRESTART.
                set g_ActiveSpecs:IGNITIONS to max(g_ActiveSpecs:IGNITIONS, eng:IGNITIONS).
                set g_ActiveSpecs:RATEDBURNTIME to choose max(g_ActiveSpecs:RATEDBURNTIME, g_EngineConfigs[eng:Config][0]) if g_EngineConfigs:HasKey(eng:Config) else -1.
                set g_ActiveSpecs:SPOOLTIME to max(g_ActiveSpecs:SPOOLTIME, g_ShipEngines:ENGUID[eng:UID]:SPOOLTIME).
                g_ActiveSpecs:Add(eng:UID, engSpec).
            }
            set g_ActiveEngines_PerfData to GetEnginesPerformanceData(g_ActiveEngines).

            local burnTimer         to Time:Seconds + burnDur[0].
            local burnTimeRemaining to burnDur[0].
            set g_Throt to 1.
            lock throttle to g_Throt.
            set g_Steer to lookDirUp(_inNode:burnVector, rollUpVector:Call()).
            set Ship:Control:Fore to 0.
            set Ship:Control:Roll to 0.
            
            local autoStageResult to ArmAutoStaging(g_StageLimit).
            if autoStageResult = 1 
            {
                set g_AS_Armed to True.
            }
            else
            {
                set g_AS_Armed to False.
            }
            OutInfo("AutoStage Armed; {0}":Format(g_AS_Armed), cr()).

            set g_Spin_Armed to ArmSpinStabilization().

            wait 0.01.
            set ts0 to Time:Seconds.
            set lastDV to _inNode:DeltaV.
            set dvRate to 0.
            
            ClearScreen.

            local breakFlag to false.
            local softShutdownDV to max(0.01, dvRate * (g_ActiveSpecs:SpoolTime * 0.2)).
            until vdot(dv0, _inNode:DeltaV) <= softShutdownDV or breakFlag// 0.0025
            {   
                set g_line to _line - 1.
                GetTermChar().
                set g_ActiveEngines to GetActiveEngines().
                set g_ActiveSpecs to GetEnginesSpecs(g_ActiveEngines).
                if g_ActiveSpecs:IGNSTG:Keys:Length > 0
                {
                    set g_ActiveSpecs to g_ActiveSpecs:IGNSTG:Values[0].
                    set g_ActiveEngines_PerfData to GetEnginesPerformanceData(g_ActiveEngines).

                    if g_ActiveSpecs:STGMAXSPOOL > 0.1
                    {
                        set softShutdownDV to dvRate * (g_ActiveSpecs:STGMAXSPOOL * 0.1).
                    }
                }
                set burnTimeRemaining to burnTimer - Time:Seconds.
                
                set g_Throt to max(0.02, min(_inNode:deltaV:mag / maxAcc, 1)).

                // DispBurnNodeData(dv, burnEta - time:seconds, burnTimeRemaining).
                // DispBurnPerfData().

                local btRem to GetActiveBurnTimeRemaining(GetActiveEngines(Ship, False)).
                if g_HS_Armed 
                {
                    // if g_HS_Check:Call(GetActiveBurnTimeRemaining(g_ActiveEngines))
                    // local btrem to choose g_ActiveEngines_PerfData:BURNTIMEREMAINING if g_ActiveEngines_PerfData:HasKey("BURNTIMEREMAINING") else GetActiveBurnTimeRemaining(g_ActiveEngines).
                    if g_HS_Check:Call(btrem)
                    {
                        g_HS_Action:Call().
                        ClearScreen.
                    }
                    else
                    {
                        print "HotStaging [Armed] {0}":Format(Round(btRem, 2)) at (0, cr()).
                    }
                }
                if g_AS_Armed 
                {
                    if g_AS_Check:Call()
                    {
                        g_AS_Action:Call().
                        ClearScreen.
                    }
                    else
                    {
                        OutMsg("Autostaging: Armed", cr()).
                    }
                }
                if g_Spin_Armed
                {
                    print "SpinStabilization [Armed] {0}":Format(Round(btRem, 2)) at (0, cr()).
                    if g_Spin_Check:Call(btrem)
                    {
                        g_Spin_Action:Call().
                    }
                }
                if g_BoosterArmed
                {
                    if g_BoosterCheckDel:Call()
                    {
                        set g_BoosterResult to g_BoosterActionDel:Call().
                        set g_BoosterArmed to g_BoosterResult[0].
                        if g_BoosterArmed
                        {
                            set g_BoosterCheckDel  to g_BoosterResult[1].
                            set g_BoosterActionDel to g_BoosterResult[2].
                        }
                        else
                        {
                            set g_BoosterResult to list(false, g_NulCheckDel, g_NulActionDel).
                            ClearScreen.
                        }
                    }
                    else
                    {
                        OutMsg("Booster staging: Armed", cr()).
                    }
                }
                if g_Spin_Armed
                {
                    if g_Spin_Check:Call(btRem)
                    {
                        g_Spin_Action:Call().
                        ClearScreen.
                    }
                    else
                    {
                        print "SpinStabilization [Armed] {0}":Format(Round(btRem, 2)) at (0, cr()).
                    }
                }
                if g_FairingsArmed
                {
                    if g_FairingsCheckDel:Call()
                    {
                        if g_FairingsActionDel:Call()
                        {
                            set g_FairingsArmed to Ship:PartsTaggedPattern("Ascent\|Fairings.*").
                        }
                        else 
                        { 
                            ClearScreen.
                        }
                    }
                    else
                    {
                        OutMsg("Fairing jettison: Armed", cr()).
                    }
                }
                if not HomeConnection:IsConnected()
                {
                    if Ship:ModulesNamed("ModuleDeployableAntenna"):Length > 0
                    {
                        for m in Ship:ModulesNamed("ModuleDeployableAntenna")
                        {
                            DoEvent(m, "extend antenna").
                        }
                    }
                }
                
                if Stage:Number <= g_StageLimit and g_AS_Armed
                {
                    OutInfo("AutoStaging disabled", 2).
                    DisableAutoStaging().
                }

                if g_TermChar = Char(101) // 'e'
                {
                    set Ship:Control:Roll to Min(1, Max(-1, Ship:Control:Roll + 0.25)).
                    OutInfo("Spin Right: " + Ship:Control:Roll, cr()).
                }
                else if g_TermChar = Char(69) // 'E'
                {
                    set Ship:Control:Roll to 1.
                    OutInfo("Spin Right: " + Ship:Control:Roll, cr()).
                }
                else if g_TermChar = Char(113) // 'q'
                {
                    set Ship:Control:Roll to Min(1, Max(-1, Ship:Control:Roll - 0.25)).
                    OutInfo("Spin Left: " + Ship:Control:Roll, cr()).
                }
                else if g_TermChar = Char(81) // 'Q'
                {
                    set Ship:Control:Roll to -1.
                    OutInfo("Spin Left: " + Ship:Control:Roll, cr()).
                }
                else if g_TermChar = Char(115) // s
                {
                    set SteeringManager:RollTorqueFactor to choose 0 if SteeringManager:RollTorqueFactor > 0 else 1.
                }
                else if g_TermChar = Char(83) // S
                {
                    set Ship:Control:Roll to 0.
                }

                OutInfo("BurnTime Remaining: {0} ":Format(Round(burnTimeRemaining, 2)), cr()).

                // if g_LoopDelegates["Events"]:Keys:Length > 0 
                // {
                //     ExecGLoopEvents().
                // }
                set g_TermChar to "".

                if Ship:AvailableThrust = 0 and not g_AS_Armed
                {
                    set breakFlag to true.
                }
            }
            set g_Throt to 0.
            set Ship:Control:Roll to 0.
            
            ClearScreen.
            OutInfo("Maneuver Complete!", cr()).
            
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
// #endregion