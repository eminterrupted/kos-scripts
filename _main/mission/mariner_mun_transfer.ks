@lazyGlobal off.

parameter tgtBody is "Minmus",
          tgtInc is 60,
          tgtLan is 90,
          pkgAlt is 250000,
          tgtAp1 is 25000,
          tgtPe1 is 25000.
//

clearscreen.

runOncePath("0:/lib/lib_display").
runOncePath("0:/lib/lib_core").
runOncePath("0:/lib/lib_util").
runOncePath("0:/lib/lib_warp").
runOncePath("0:/lib/nav/lib_calc_mnv").
runOncePath("0:/lib/nav/lib_deltav").
runOncePath("0:/lib/nav/lib_mnv").
runOncePath("0:/lib/nav/lib_nav").
runOncePath("0:/lib/nav/lib_node").
runOncePath("0:/lib/part/lib_antenna").
runOncePath("0:/lib/part/lib_solar").

//Paths to other scripts used here
local incChangeScript to "local:/incChange". 
copyPath("0:/_adhoc/simple_inclination_change", incChangeScript).

//local stateObj to init_state_obj().
local runmode to stateObj["runmode"].
if runmode = 99 set runmode to 0.

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
            set runmode to 2.
        }
        
        //Activate the antenna
        else if runmode = 2 {
            out_msg("Deploying antenna").

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
            
            set runmode to 3.
        }

        //Sets the transfer target
        else if runmode = 3 {
            out_msg("Setting target to " + tgtBody).
            set target to tgtBody.
            set runmode to 7.
        }

        else if runmode = 7 {
            out_msg("Checking inclination").
            if ship:orbit:inclination < target:orbit:inclination - 2.5 or ship:orbit:inclination > target:orbit:inclination + 2.5 {
                out_msg("Inclination not within range: Current [" + ship:obt:inclination + "] / Target [" + target:obt:inclination + "]").
                runpath(incChangeScript, target:orbit:inclination, target:orbit:lan).
            }
            set runmode to 15.
        }

        //Returns needed parameters for the transfer burn
        else if runmode = 15 {
            out_msg("Getting transfer object").
            if not hasTarget set target to tgtBody.
            set mnvObj to get_transfer_obj().
            set runmode to 25.
        }

        // Adds the transfer burn node to the flight plan
        // Center the node at 60s earlier than predicted to ensure we have the 
        // proper orbit direction on arrival
        else if runmode = 25 {
            out_msg("Adding transfer node").

            set mnvNode to node(mnvObj["nodeAt"], 0, 0, mnvObj["dv"]).
            add mnvNode. 

            local accuracy is 0.001.
            set mnvNode to optimize_existing_node(mnvNode, pkgAlt, "pe", target, accuracy).
            set mnvObj to get_burn_obj_from_node(mnvNode).

            set runmode to 30.
        }

        //Warps to the burn node
        else if runmode = 30 {
            out_msg("Warping to burn node").
            warp_to_burn_node(mnvObj).
            set runmode to 35.
        }

        //Executes the transfer burn
        else if runmode = 35 {
            out_msg("Executing burn node").
            exec_node(nextNode).
            set runmode to 37.
        }

        else if runmode = 37 {
            out_msg("Setting onDeploy triggers").
            when stage:number <= 1 then {
                for p in ship:partsTaggedPattern("solar.array.*.onDeploy") {
                    activate_solar(p).
                }

                for p in ship:partsTaggedPattern("comm.dish.*.onDeploy") {
                    activate_dish(p).
                }

                for p in ship:partsTaggedPattern("comm.omni.*.onDeploy") {
                    activate_omni(p).
                }
            }

            set runmode to 40.
        }

        //Then warps to the SOI change
        else if runmode = 40 {
            
            out_msg("SOI Warp").

            set tStamp to time:seconds + 30.
            until time:seconds >= tStamp {
                update_display().
                disp_timer(tStamp, "soi warp").
            }

            disp_clear_block("timer").

            if ship:body:name <> tgtBody {
                warp_to_next_soi().
            }
            
            until ship:body:name = tgtBody {
                update_display().
            }
                
            set runmode to 45.
        }

// Circularization node
        // Adds a 60s timer for player to do anything needed before warp
        else if runmode = 45 {

            out_msg("Circ burn countdown").
            set tStamp to time:seconds + 60.
            until time:seconds >= tStamp {
                update_display().
                disp_timer(tStamp, "circ node").
            }

            disp_clear_block("timer").

            if warp > 0 kuniverse:timewarp:cancelwarp().
            wait until kuniverse:timewarp:issettled.
            set runmode to 47.
        }

        //Adds a circularization node to the flight plan to capture into orbit around target, using desired tPe0
        else if runmode = 47 {
            out_msg("Adding capture node").
            set mnvNode to add_capture_node(tgtAp1).
            set runmode to 55.
        }

        //Gets burn data from the node
        else if runmode = 55 {
            out_msg("Getting burn object from existing node").
            set mnvObj to get_burn_obj_from_node(mnvNode).
            set mnvObj["mnv"] to mnvNode. 
            set runmode to 60.
        }

        //Warps to the burn node
        else if runmode = 60 {
            out_msg("Warping to burn node").
            warp_to_burn_node(mnvObj).
            set runmode to 65.
        }

        //Executes the circ burn
        else if runmode = 65 {
            out_msg("Executing burn node").
            exec_node(nextNode).
            wait 2.
            set runmode to 70.
        }

        else if runmode = 70 {
            out_msg("Checking orbit inclination").
            if (ship:orbit:inclination < tgtInc - 2 or ship:orbit:inclination > tgtInc + 2) {
                out_msg("Inclination not within range: Current [" + ship:obt:inclination + "] / Target [" + tgtInc + "]").
                runpath(incChangeScript, tgtInc, tgtLan).
            }

            set runmode to 75.
        }

        //Adds a hohmann burn top lower to final altitude
        else if runmode = 75 {
            out_msg("Lowering to final altitude").
            exec_circ_burn("ap", tgtPe1).
            set runmode to 80.
        }

        //
        else if runmode = 80 {
            out_msg("Final alt circ burn").
            exec_circ_burn("pe", tgtAp1).
            set runmode to 98.
        }

        //Preps the vessel for long-term orbit
        else if runmode = 98 {
            end_main().
            set runmode to 99.
        }

        //Logs the runmode change and writes to disk in case we need to resume the script later
        set stateObj["runmode"] to runmode.
        log_state(stateObj).

        update_display().
    }
}


//Functions
local function end_main {
    unlock steering.
    unlock throttle.

    disp_clear_block_all().

    logStr("Mission completed").
}