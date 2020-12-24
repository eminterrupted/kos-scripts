@lazyGlobal off.

parameter tgtBody is "Mun",
          tgtInc is 35,
          tgtPe0 is 250000,
          tgtAp1 is 50000,
          tgtPe1 is 50000.
//

clearscreen.

runOncePath("0:/lib/lib_display").
runOncePath("0:/lib/lib_core").
runOncePath("0:/lib/lib_util").
runOncePath("0:/lib/lib_warp").
runOncePath("0:/lib/nav/lib_calc_mnv").
runOncePath("0:/lib/nav/lib_deltav").
runOncePath("0:/lib/nav/lib_nav").
runOncePath("0:/lib/nav/lib_node").
runOncePath("0:/lib/nav/lib_circ_burn").
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
            local p to ship:partsTaggedPattern("comm.dish").
            if p:length > 0 activate_dish(p[0]).

            for o in ship:partsTaggedPattern("comm.omni") {
                activate_omni(o).
            }
            
            set runmode to 5.
        }

        //Sets the transfer target
        else if runmode = 5 {
            set target to tgtBody.
            update_display().
            set runmode to 7.
        }

        else if runmode = 7 {
            if ship:orbit:inclination < target:orbit:inclination - 2.5 or ship:orbit:inclination > target:orbit:inclination + 2.5 {
                runpath(incChangeScript, target:orbit:inclination, target:orbit:lan).
            }
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

            local accuracy is 0.0005.
            set mnvNode to optimize_existing_node(mnvNode, tgtPe0, "pe", target, accuracy).
            
            set runmode to 30.
        }

        //Warps to the burn node
        else if runmode = 30 {
            warp_to_burn_node(mnvObj).
            set runmode to 35.
        }

        //Executes the transfer burn
        else if runmode = 35 {
            exec_node(nextNode).
            set runmode to 40.
        }

        //Clears the target data so we don't have weird behaviors when we reach its SOI
        //Then warps to the SOI change
        else if runmode = 40 {
            
            set tStamp to time:seconds + 30.
            until time:seconds >= tStamp {
                update_display().
                disp_timer(tStamp, "soi warp").
            }

            disp_clear_block("timer").

            warp_to_next_soi().
            
            until ship:body:name = tgtBody {
                update_display().
            }
                
            set runmode to 45.
        }

// Circularization node
        // Adds a 60s timer for player to do anything needed before warp
        else if runmode = 45 {
            set tStamp to time:seconds + 60.
            until time:seconds >= tStamp {
                update_display().
                disp_timer(tStamp, "circ node").
            }

            disp_clear_block("timer").

            if warp > 0 kuniverse:timewarp:cancelwarp().
            wait until kuniverse:timewarp:issettled.
            set runmode to 50.
        }

        //Adds a circularization node to the flight plan to capture into orbit around target, using desired tPe0
        else if runmode = 50 {
            set mnvNode to add_capture_node(tgtAp1).
            set runmode to 55.
        }

        //Gets burn data from the node
        else if runmode = 55 {
            set mnvObj to get_burn_obj_from_node(mnvNode).
            set mnvObj["mnv"] to mnvNode. 
            set runmode to 60.
        }

        //Warps to the burn node
        else if runmode = 60 {
            warp_to_burn_node(mnvObj).
            set runmode to 65.
        }

        //Executes the circ burn
        else if runmode = 65 {
            exec_node(nextNode).
            wait 2.
            set runmode to 70.
        }

        else if runmode = 70 {
            if (ship:orbit:inclination < tgtInc - 2 or ship:orbit:inclination > tgtInc + 2) {
                runpath(incChangeScript, tgtInc).
            }

            set runmode to 75.
        }

        //Adds a hohmann burn to lower Pe
        else if runmode = 75 {
            set mnvNode to add_simple_circ_node("ap", tgtPe1).
            set runmode to 80.
        }

        //Gets burn data from the node
        else if runmode = 80 {
            set mnvObj to get_burn_obj_from_node(mnvNode).
            set mnvObj["mnv"] to mnvNode. 
            set runmode to 85.
        }

        //Warps to the burn node
        else if runmode = 85 {
            warp_to_burn_node(mnvObj).
            set runmode to 90.
        }

        //Executes the circ burn
        else if runmode = 90 {
            exec_node(nextNode).
            set runmode to 95.
        }

        else if runmode = 95 {
            
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
    }
}


//Functions
local function end_main {
    unlock steering.
    unlock throttle.

    disp_clear_block_all().

    logStr("Mission completed").
}