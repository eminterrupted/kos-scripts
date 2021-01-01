@lazyGlobal off.

runOncePath("0:/lib/nav/lib_calc_mnv").
runOncePath("0:/lib/nav/lib_nav").
runOncePath("0:/lib/nav/lib_node").
runOncePath("0:/lib/lib_warp").


// Circularization burns
    global function exec_circ_burn {
        parameter _nodeAt,
                _tgtAlt.

        local burnNode to node(0, 0, 0, 0).
        local burnObj to lex().
    
        out_msg("Executing exec_circ_burn").

        if not hasNode {
            out_info("Executing add_simple_circ_node()").
            set burnNode to add_simple_circ_node(_nodeAt, _tgtAlt).
        }

        out_info("Executing get_burn_obj_from_node(burnNode)").
        set burnObj to get_burn_obj_from_node(burnNode).
            
        out_info("Executing warp_to_circ_burn()").
        warp_to_circ_burn(burnObj["burnEta"]).

        out_info("Executing exec_circ_burn()").
        do_circ_burn(burnObj).

        out_info().
        out_msg().
    }

    local function warp_to_circ_burn {
        parameter _burnEta.
        
        logStr("[warp_to_circ_burn] Warping to _burnEta[" + _burnEta  + "]").

        lock steering to choose lookdirup(nextnode:burnvector, sun:position) if hasNode else lookdirup(ship:prograde:vector, sun:position).
        warp_to_timestamp(_burnEta).
    }


    local function do_circ_burn {
        parameter _burnObj.
        
        logStr("Executing circularization burn").

        until time:seconds >= _burnObj["burnEta"] {
            update_display().
            disp_timer(_burnObj["burnEta"]).
        }

        disp_clear_block("timer").
        exec_node(_burnObj["mnv"]).
    }


// Hohmann transfer
    // Does a complete simple hohmann transfer to new ap / pe
    global function exec_hohmann_burn {
        parameter _tgtAp,
                _tgtPe.

        // Mode 0 to raise orbit, 1 to lower orbit
        local raiseObt to choose true if _tgtAp >= ship:apoapsis else false.
        local rVal is ship:facing:roll - lookDirUp(ship:prograde:vector, sun:position):roll.

        local burnAt is "".
        local isCircBurn is false.
        local mnvCache is "local:/mnvCache.json".
        local mnvNode is node(0, 0, 0, 0).
        local mnvObj is lex().
        local subroutine is choose 0 if stateObj["subroutine"] = "" else stateObj["subroutine"].

        if exists(mnvCache) set mnvObj to mnvCache.
        lock steering to lookDirUp(ship:prograde:vector, sun:position) + r(0, 0, rVal).
        
        until subroutine = 10 {
            
            if subroutine = 0 {
                if raiseObt {
                    set subroutine to set_sr(1).    // Subroutine 1 handles raised orbits
                } else {
                    set subroutine to set_sr(2).    // Subroutine 2 handles lowered orbits
                }
            }

            else if subroutine = 1 {
                set burnAt to choose "pe" if not isCircBurn else "ap".
                local tgtAlt to choose _tgtAp if not isCircBurn else _tgtPe.
                set mnvNode to add_simple_circ_node(burnAt, tgtAlt).
                set subroutine to set_sr(3).
            }

            else if subroutine = 2 {
                set burnAt to choose "ap" if not isCircBurn else "pe".
                local tgtAlt to choose _tgtPe if not isCircBurn else _tgtAp.
                set mnvNode to add_simple_circ_node(burnAt, tgtAlt).
                set subroutine to set_sr(3).
            }

            //Gets burn data from the node, write to cache in case needed later
            else if subroutine = 3 {
                set mnvObj to get_burn_obj_from_node(mnvNode).
                writeJson(mnvObj, mnvCache).
                set mnvObj["mnv"] to mnvNode. 
                set subroutine to set_sr(4).
            }

            //Warps to the burn node
            else if subroutine = 4 {
                warp_to_burn_node(mnvObj).
                wait until warp = 0 and kuniverse:timewarp:issettled.
                set subroutine to set_sr(5).
            }

            //Executes the circ burn
            else if subroutine = 5 {
                exec_node(nextNode).
                wait 1.
                if not isCircBurn {
                    set isCircBurn to true.
                    set subroutine to set_sr(0).
                } else {
                    set subroutine to set_sr(10).
                }
            }

            update_display().
        }

        set_sr("").
    }


// Argument of Peripasis

    // Matches an ArgPe within the given tolerance range in degrees
    global function exec_match_arg_pe {
        parameter _tgtObt.

        // First get the difference in target degrees vs. current degrees
        local taDiff to mod(_tgtObt:argumentOfPeriapsis + _tgtObt:lan + ( 360 - ship:orbit:argumentOfPeriapsis - ship:orbit:lan), 360).

        // Subtract the diff from 360 to get our desured true anomaly
        local taTgt to mod(360 - taDiff, 360).

        // Get the num of seconds until desired true anomaly.
        local nodeAt to time:seconds + eta_to_ta(ship:orbit, taTgt).

        // Add the burn node        
        local burnNode to node(nodeAt, 0, 0, 1).
        add burnNode.

        // Get the burn object from the node
        local burnObj to get_burn_obj_from_node(burnNode).
        
        // Warp ahead
        warp_to_burn_node(burnObj).
        
        // Exec when settled
        wait until warp = 0 and kuniverse:timewarp:issettled.
        exec_node(nextNode).
    }



// Inclination
    // Given an orbit, match the inclination of that orbit from 
    // the current vessel's orbit
    global function exec_match_obt_inclination {

        parameter _tgtOrbit.

        local subroutine to choose 0 if stateObj["subroutine"] = "" else stateObj["subroutine"].

        // Inclination match burn data
        local burn to get_inc_match_burn(ship, _tgtOrbit).
        local burnVector to burn[1].
        local dur to get_burn_dur(burnVector:mag).
        local utime to burn[0].
        local leadTime to utime - get_burn_dur(burnVector:mag / 2).

        //Maneuver node structures
        local mnvNode is burn[2].

        //Vec draw vars
        local burnDone to false.
        local burnVDTail to 0.
        local burnVD to 0.

        //Steering
        local rVal is ship:facing:roll - lookDirUp(ship:facing:forevector, sun:position):roll.

        local sVal is lookDirUp(ship:facing:forevector, sun:position) + r(0, 0, rVal).
        lock steering to sVal.

        local tVal is 0.
        lock throttle to tVal.

        //Staging trigger
        when ship:availableThrust < 0.1 and throttle > 0 then {
            safe_stage().
            preserve.
        }
        
        until subroutine = 10 {

            // Vecdraw to show the maneuver
            if subroutine = 0 {

                set burnVDTail to positionAt(ship, utime).
                set burnVD to 
                    vecDraw(
                        burnVDTail,
                        500 * burnVector,
                        magenta,
                        "dV:" + round(burnVector:mag, 1) + " m/s, dur:" + round(dur, 1) + "s",
                        1,
                        true).

                // Keep the draw updating the start position until the burn is done.
                set burnVD:startUpdater to { return positionAt(ship, utime). }.
                set subroutine to 1.
            }

            if subroutine = 1 {
                add mnvNode.
                set subroutine to 2.
            }

            // Warpable wait until burn
            else if subroutine = 2 {
                until time:seconds >= leadTime  - 30 {
                    set sVal to lookDirUp(nextNode:burnVector, sun:position) + r(0, 0, rVal).
                    update_display().
                    disp_burn_data().
                    wait 0.01.
                }
                set subroutine to 3.
            }

            // Stop warping
            else if subroutine = 3 {
                until time:seconds >= leadTime {
                    if warp > 0 kuniverse:timewarp:cancelwarp().
                    update_display().
                    disp_burn_data().
                    wait 0.01.
                }
                set subroutine to 4.
            }

            // Exec burn.
            else if subroutine = 4 {
                //Start burn
                set tVal to 1.
                local startVel to ship:velocity:orbit.
                local dvToGo to 9999999.
                until dvToGo <= 0.1 {
                    set sVal to burnVector.
                    set dvToGo to burnVector:mag - sqrt(abs(vdot(burnVector, (ship:velocity:orbit - startVel)))).
                    update_display().
                    disp_burn_data().
                    wait 0.01.
                }

                //End burn
                set tVal to 0.
                set subroutine to 5.
            }

            // Removes the node, ends routine
            else if subroutine = 5 {
                remove mnvNode.
                set subroutine to 10.
            }

            update_display().

            if stateObj:subroutine <> subroutine {
                set stateObj["subroutine"] to subroutine.
                log_state(stateObj).
            }
        }
    }