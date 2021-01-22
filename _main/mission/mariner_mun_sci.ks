@lazyGlobal off.

parameter tgt is "Mun",
          rVal is 0.

clearscreen.

runOncePath("0:/lib/display/lib_display").
runOncePath("0:/lib/lib_core").
runOncePath("0:/lib/lib_sci").
runOncePath("0:/lib/lib_util").
runOncePath("0:/lib/lib_warp").
runOncePath("0:/lib/nav/lib_calc_mnv").
runOncePath("0:/lib/nav/lib_deltav").
runOncePath("0:/lib/nav/lib_nav").
runOncePath("0:/lib/nav/lib_node").
runOncePath("0:/lib/nav/lib_mnv").
runOncePath("0:/lib/part/lib_antenna").

//Paths to other scripts used here
local sciScript to "local:/sciScript".
copyPath("0:/_main/component/deploy_scansat", sciScript).

local incChangeScript to "local:/incChange". 
copyPath("0:/_main/adhoc/simple_inclination_change", incChangeScript).

//local stateObj to init_state_obj().
local runmode to stateObj["runmode"].
if runmode = 99 set runmode to 0.

disp_main().

local tgtInc is 82.
local tgtAp0 is 375000.
local tgtPe0 is 375000.

local sciList to get_sci_mod_for_parts(ship:parts).

local mnvNode is 0.
local mnvObj is lex().

local tStamp to 0.

local sVal is ship:prograde + r(0, 0, rVal).
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
            set runmode to 5.
        }
        
        //Set up the triggers for science
        else if runmode = 5 {
            local p to ship:partsTaggedPattern("comm.dish").
            if p:length > 0 activate_dish(p[0]).

            for o in ship:partsTaggedPattern("comm.omni") {
                activate_omni(o).
            }
            
            set runmode to 8.
        }

        //Stages to remove the kick stage for better accuracy on the transfer burn
        else if runmode = 8 {
            //safe_stage().
            set runmode to 10.
        }

        //Sets the transfer target
        else if runmode = 10 {
            set target to tgt.
            update_display().
            set runmode to 15.
        }

        //Returns needed parameters for the transfer burn
        else if runmode = 15 {
            set mnvObj to get_transfer_obj().
            set runmode to 25.
        }

        //Adds the transfer burn node to the flight plan
        else if runmode = 25 {
            set mnvNode to node(mnvObj["nodeAt"], 0, 0, mnvObj["dv"]).
            add mnvNode. 

            local accuracy is 0.005.
            set mnvNode to OptimizeManeuverNode(mnvNode, tgtPe0, "pe", target, accuracy).
            
            set runmode to 30.
        }

        //Warps to the burn node
        else if runmode = 30 {
            warp_to_burn_node(mnvObj).
            set runmode to 35.
        }

        //Executes the transfer burn
        else if runmode = 35 {
            ExecuteNode(nextNode).
            set runmode to 40.
        }

        //If the dish antenna is not yet activated, does so
        else if runmode = 40 {
            deploy_dish().
            set runmode to 45.
        }

        //Sets up a trigger for logging science in high orbit
        else if runmode = 45 {
            // when ship:altitude > 250000 then {
            //     log_sci_list(sciList).
            //     recover_sci_list(scilist).
            // }
            set runmode to 50.
        }

        //Clears the target data so we don't have weird behaviors when we reach its SOI
        //Then warps to the SOI change
        else if runmode = 50 {
            
            set tStamp to time:seconds + 15.
            until time:seconds >= tStamp {
                update_display().
                disp_timer(tStamp, "soi warp").
            }

            disp_clear_block("timer").

            warp_to_next_soi().
            
            if ship:body:name = tgt {
                set runmode to 55.
            } else {
                update_display().
                wait 1.
            }
        }

        //Sets up triggers for science experiments
        else if runmode = 55 {
            when ship:altitude > 60000 then {
                log_sci_list(sciList).
                collect_sci_in_container().
            }
            set runmode to 57.
            update_display().
        }

        else if runmode = 57 {
            set tStamp to time:seconds + 60.
            until time:seconds >= tStamp {
                update_display().
                disp_timer(tStamp, "circ node").
            }

            disp_clear_block("timer").

            if warp > 0 kuniverse:timewarp:cancelwarp().
            wait until kuniverse:timewarp:issettled.
            set runmode to 60.
        }

        //Adds a circularization node to the flight plan to capture into orbit around target, using desired tPe0
        else if runmode = 60 {
            set mnvNode to AddCaptureNode(tgtAp0).
            set runmode to 62.
        }

        //Gets burn data from the node
        else if runmode = 62 {
            set mnvObj to get_burn_obj_from_node(mnvNode).
            set mnvObj["mnv"] to mnvNode. 
            set runmode to 64.
        }

        //Warps to the burn node
        else if runmode = 64 {
            warp_to_burn_node(mnvObj).
            set runmode to 66.
        }

        //Executes the circ burn
        else if runmode = 66 {
            exec_burn(nextNode).
            wait 2.
            set runmode to 68.
        }

        else if runmode = 68 {
            log_sci_list(sciList).
            recover_sci_list(sciList).
            set runmode to 69.
        }

        //Adds a hohmann burn to lower Pe
        else if runmode = 69 {
            set mnvNode to AddCircularizationNode("ap", tgtPe0).
            set runmode to 70.
        }

        //Gets burn data from the node
        else if runmode = 70 {
            set mnvObj to get_burn_obj_from_node(mnvNode).
            set mnvObj["mnv"] to mnvNode. 
            set runmode to 72.
        }

        //Warps to the burn node
        else if runmode = 72 {
            warp_to_burn_node(mnvObj).
            set runmode to 74.
        }

        //Executes the circ burn
        else if runmode = 74 {
            ExecuteNode(nextNode).
            set runmode to 75.
        }

        else if runmode = 75 {
            set tStamp to time:seconds + 21600.
            set runmode to 76.
        }

        else if runmode = 76 {
            if ship:orbit:inclination < tgtInc * 0.85 or ship:orbit:inclination > tgtInc * 1.15 {
                runPath(incChangeScript, tgtInc).
            }
            set runmode to 78.
        }

        // Runs the science experiment script
        else if runmode = 78 {
        
            runPath(sciScript).
           
            set runmode to 80.
        }

        else if runmode = 255 {
            update_display().
        }

        //Just lets the mission run until the end of tStamp. 
        else if runmode = 80 {
            until time:seconds >= tStamp {
                update_display().
                disp_timer(tStamp, "SCRIPT END").
            } 

            disp_clear_block("timer").

            set runmode to 82.
        }

        //Preps the vessel for long-term orbit
        else if runmode = 82 {
            end_main().
            set runmode to 99.
        }

        //Logs the runmode change and writes to disk in case we need to resume the script later
        set stateObj["runmode"] to runmode.
        log_state(stateObj).
    }
}


//Functions
local function exec_burn {
    parameter burnNode.

    ExecuteNode(burnNode).

    update_display().
}


local function end_main {
    unlock steering.
    unlock throttle.

    disp_clear_block_all().

    logStr("Mission completed").
}


local function deploy_dish {
    for p in ship:partsTaggedPattern("comm.dish") {
        activate_dish(p).
    }
}