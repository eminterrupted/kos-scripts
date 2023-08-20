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
  
    // *- Maneuver Exec
    // #region

    // ExecNodeBurn :: _inNode<node> -> <none>
    // Given a node object, executes it
    global function ExecNodeBurn
    {
        parameter _inNode is node().

        local dv to _inNode:deltaV:mag.
        local burnDur to list(0, 0).
        local fullDur to 0.
        local halfDur to 0.
        local burnEta to 0.
        lock dvRemaining to abs(_inNode:burnVector:mag).
        //Breakpoint("pre DV eval").

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
            set g_MECO    to burnEta + fullDur.

            set s_Val to lookDirUp(_inNode:burnvector, Sun:Position).
            set t_Val to 0.
            lock steering to s_Val.
            lock throttle to t_Val.

            local burnLeadTime to UpdateTermScalar(60, list(1, 5, 15, 30)).
            local warpFlag to False.

            until time:seconds >= burnEta
            {
                if Kuniverse:TimeWarp = 0 set warpFlag to False.
                if not warpFlag OutMsg("Press Enter to warp to [maneuver - {0}s]":Format(burnLeadTime)).
                GetTermChar().
                wait 0.01.
                if g_termChar = ""
                {
                }
                else if g_termChar = Char(87)
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
                    set g_termChar to "".
                }
                else if g_termChar = Char(82)
                {
                    OutInfo("Recalculating burn parameters").
                    OutInfo("", 1).
                    OutInfo("", 2).
                    wait 0.25.
                    set burnDur to CalcBurnDur(_inNode:deltaV:mag).
                    set fullDur to burnDur[0].
                    set halfDur to burnDur[3].

                    set burnEta to _inNode:time - halfDur. 
                    set g_MECO    to burnEta + fullDur.
                    set g_termChar to "".
                }
                
                if not warpFlag 
                {
                    set burnLeadTime to UpdateTermScalar(burnLeadTime, list(1, 5, 15, 30)).
                }

                if Time:Seconds >= burnETA - 5
                {
                    set Ship:Control:Fore to 1.
                }
                set s_Val to lookDirUp(_inNode:burnvector, Sun:Position).
                // DispBurn(dvRemaining, burnEta - time:seconds, g_MECO - burnEta).
                DispBurnData(dvRemaining, burnEta - Time:Seconds, burnDur[0]).
            }

            local dv0 to _inNode:deltav.
            lock maxAcc to max(0.00001, ship:maxThrust) / ship:mass.

            OutMsg("Executing burn").
            OutInfo().
            OutInfo("", 1).
            
            local burnTimer         to Time:Seconds + burnDur[0].
            local burnTimeRemaining to burnDur[0].
            set t_Val to 1.
            set s_Val to lookDirUp(_inNode:burnVector, Sun:Position).
            set Ship:Control:Fore to 0.
            
            local g_AutoStageArmed to choose True if ArmAutoStagingNext(g_StageLimit) = 1 else False.
            
            until vdot(dv0, _inNode:deltaV) <= 0.01
            {
                set burnTimeRemaining to burnTimer - Time:Seconds.
                set t_Val to max(0.02, min(_inNode:deltaV:mag / maxAcc, 1)).
                DispBurnData(dvRemaining, burnEta - time:seconds, burnTimeRemaining).
                DispBurnPerfData().
                wait 0.01.
                
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