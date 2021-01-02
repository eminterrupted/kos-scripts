@lazyGlobal off.

parameter _tgt is "Megfrid's Debris".
//parameter _tgt is "Mun".
//

clearscreen.

runOncePath("0:/lib/display/lib_display").
runOncePath("0:/lib/lib_core").
runOncePath("0:/lib/lib_util").
runOncePath("0:/lib/lib_warp").
runOncePath("0:/lib/nav/lib_calc_mnv").
runOncePath("0:/lib/nav/lib_deltav").
runOncePath("0:/lib/nav/lib_mnv").
runOncePath("0:/lib/nav/lib_nav").
runOncePath("0:/lib/nav/lib_node").
runOncePath("0:/lib/nav/lib_rendezvous").
runOncePath("0:/lib/part/lib_antenna").
runOncePath("0:/lib/part/lib_solar").

//Paths to other scripts used here
local incChangeScript to "local:/incChange". 
copyPath("0:/_main/adhoc/simple_inclination_change", incChangeScript).

//local stateObj to init_state_obj().
local runmode to init_rm(0).

disp_main().

local mnvNode is 0.
local mnvObj is lex().

local tStamp to 0.

local sVal is lookDirUp(ship:prograde:vector, sun:position).
lock steering to sVal.
local tVal is 0.
lock throttle to tVal.

//Staging trigger
when ship:availableThrust < 0.1 and tVal > 0 then {
    safe_stage().
    preserve.
}

main().

//Main
local function main {
    until runmode = 99 {

        //Get the list of science experiments
        if runmode = 0 {
            set runmode to set_rm(2).
        }
        
        //Activate the antenna
        else if runmode = 2 {
            for p in ship:partsTaggedPattern("comm.dish") {
                if not p:tag:matchesPattern("onDeploy") {
                    activate_dish(p).
                }
            }

            for p in ship:partsTaggedPattern("comm.omni") {
                if not p:tag:matchesPattern("onDeploy") {
                    activate_omni(p).
                }
            }
            
            set runmode to set_rm(3).
        }

        //Sets the transfer target
        else if runmode = 3 {
            out_msg("Set target").
            set target to orbitable(_tgt).
            set runmode to set_rm(7).
        }


        // Matches inclination
        else if runmode = 7 {
            out_msg("Checking inclination").
            if not check_value(ship:obt:inclination, target:obt:inclination, 1) {
                out_msg("Inclination out of range. Current[" + round(ship:obt:inclination, 3) + "] | Target[" + round(target:obt:inclination, 3) + "]").
                wait 5.
                runpath(incChangeScript, target:orbit:inclination, target:orbit:lan).
            }

            else if not check_value(ship:obt:lan, target:obt:lan, 5) {
                out_msg("LAN out of range. Current[" + round(ship:obt:LAN, 3) + "] | Target[" + round(target:obt:LAN, 3) + "]").
                wait 5.
                runpath(incChangeScript, target:orbit:inclination, target:orbit:lan).
            }
            set runmode to set_rm(15).
        }


        // Matches argPe
        else if runmode = 10 {
            out_msg("Checking argPe").
            if not check_value(ship:obt:argumentofperiapsis, target:orbit:argumentofperiapsis, 10) {
                out_msg("argPe out of range, identifying maneuver").
                runpath("0:/_main/adhoc/simple_argpe_change", target:orbit:argumentofperiapsis, target:orbit:lan).
                out_msg().
            }
            set runmode to set_rm(15).
        }


        //Returns needed parameters for the transfer burn
        else if runmode = 15 {
            out_msg("Getting transfer object").
            set mnvObj to get_transfer_obj().
            set runmode to set_rm(25).
        }

        //Adds the transfer burn node to the flight plan
        else if runmode = 25 {
            out_msg("Setting up the maneuver node").
            set mnvNode to node(mnvObj["nodeAt"], 0, 0, mnvObj["dv"]).
            add mnvNode. 

            //local accuracy is 0.001.
            //set mnvNode to optimize_existing_node(mnvNode, target:orbit:periapsis, "pe", target, accuracy).
            
            set runmode to set_rm(30).
        }

        //Warps to the burn node
        else if runmode = 30 {
            out_msg("Manuever added, warping to burn eta").
            warp_to_burn_node(mnvObj).
            set runmode to set_rm(35).
        }

        //Executes the transfer burn
        else if runmode = 35 {
            out_msg("Executing node").
            exec_node(nextNode).
            set runmode to set_rm(37).
        }

        //Add a circ node at Pe.
        else if runmode = 37 {
            out_msg("Executing circularization burn").
            exec_circ_burn(time:seconds + eta:periapsis, target:altitude).
            set runmode to set_rm(40).
        }

        else if runmode = 40 {
            if target:distance > 5000 {
                runPath("0:/_main/adhoc/rendezvous_phased_approach", _tgt).
            }

            set runmode to set_rm(45).
        }

        else if runmode = 45 {
            out_msg("Awaiting closest approach").
            await_closest_approach.
            set runmode to set_rm(50).
        }

        else if runmode = 50 {
            out_msg("Cancelling relative velocity").
            cancel_relative_velocity().
            set runmode to set_rm(55).
        }

        else if runmode = 55 {
            out_msg("Approaching target").
            approach_target().
            set runmode to set_rm(60).
        }

        else if runmode = 60 {
            if target:distance <= 1000 {
                set runmode to set_rm(70). 
            } else {
                set runmode to set_rm(45).
            }
        }

        else if runmode = 70 {
            out_msg("Final approach, cancelling velocity").
            cancel_relative_velocity().
            set runmode to set_rm(75).
        }

        else if runmode = 75{
            out_msg("Rendezvous complete").
            set runmode to set_rm(99).
        }

        update_display().
    }
}

// Loop until distance from target starts increasing
local function await_closest_approach {
    
    until false {
        local lastDistance to target:distance.
        wait 1.
        if target:distance > lastDistance {
            break.
        } else {
            out_msg("Awaiting closest approach. Distance: " + round(target:distance)).
            update_display().
        }
    }
}


// Throttle against our relative velocity vector until we're increasing it
local function cancel_relative_velocity {
    lock steering to lookDirUp(target:velocity:orbit - ship:velocity:orbit, sun:position).
    wait until shipSettled().

    lock throttle to 0.25.

    until false {
        local lastDiff to (target:velocity:orbit - ship:velocity:orbit):mag.
        wait 0.01.
        if (target:velocity:orbit - ship:velocity:orbit):mag > lastDiff {
            lock throttle to 0. 
            out_msg().
            break.
        } else {
            update_display().
            out_msg("Cancelling relative velocity. Current: " + round(lastDiff)).
        }
    }
}

local function approach_target {
    lock steering to target:position.
    wait until shipSettled().
    
    set tStamp to time:seconds + 2.5.

    lock throttle to 0.25.
    until time:seconds >= tStamp {
        update_display().
        disp_timer(tStamp, "Approach Burn").
        out_msg("Approaching target. Current distance: " + round(target:distance)).
    }

    lock throttle to 0.

    disp_clear_block("timer").
}