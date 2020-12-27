@lazyGlobal off.

parameter _tgt is "Minmus",
          _rVal is 0.

clearscreen.

runOncePath("0:/lib/lib_display").
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

//local stateObj to init_state_obj().
local runmode to stateObj["runmode"].
if runmode = 99 set runmode to 0.

disp_main().

wait 5.

local tgtAp0 is 235000.
local tgtPe0 is 235000.
local tgtInc is 82.


local sciList to get_sci_mod_for_parts(ship:parts).

local mnvNode is 0.
local mnvObj is lex().

local sVal is lookDirUp(ship:prograde:vector, sun:position) + r(0, 0, _rVal).
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

        //Deploy dish if not already
        if runmode = 0 {
            set sVal to lookDirUp(ship:prograde:vector, sun:position) + r(0, 0, _rVal).

            local dish is ship:partsTaggedPattern("comm.dish").
            for d in dish {
                activate_dish(d).
                logStr("Comm object Dish activated").
                wait 1.
                set_dish_target(d, kerbin:name).
                logStr("Dish target: " + kerbin:name).
            }

            set runmode to 2.
        }
        
        //
        else if runmode = 2 {
            set sVal to lookDirUp(ship:prograde:vector, sun:position) + r(0, 0, _rVal).

            update_display().

            set runmode to 4.
        }

        //Sets the transfer target
        else if runmode = 4 {
            set sVal to lookDirUp(ship:prograde:vector, sun:position) + r(0, 0, _rVal).

            set target to _tgt.
            update_display().

            set runmode to 6.
        }

        //Match the inclination with the target
        else if runmode = 6 {
            set sVal to lookDirUp(ship:prograde:vector, sun:position) + r(0, 0, _rVal).

            runPath("0:/_main/component/match_orbit_inclination", target:orbit).

            set runmode to 15.
        }


        //Returns needed parameters for the transfer burn
        else if runmode = 15 {
            set sVal to lookDirUp(ship:prograde:vector, sun:position) + r(0, 0, _rVal).

            set mnvObj to get_transfer_obj().

            set runmode to 25.
        }

        //Adds the transfer burn node to the flight plan
        else if runmode = 25 {
            set sVal to lookDirUp(ship:prograde:vector, sun:position) + r(0, 0, _rVal).

            set mnvObj to add_transfer_node(mnvObj, tgtAp0).

            set runmode to 30.
        }

        //Warps to the burn node
        else if runmode = 30 {
            set sVal to lookDirUp(nextNode:burnvector, sun:position) + r(0, 0, _rVal).

            warp_to_burn_node(mnvObj).

            set runmode to 35.
        }

        //Executes the transfer burn
        else if runmode = 35 {
            set sVal to lookDirUp(nextNode:burnvector, sun:position) + r(0, 0, _rVal).

            exec_node(nextNode).

            set runmode to 45.
        }

        //Clears the target data so we don't have weird behaviors when we reach its SOI
        //Then warps to the SOI change
        else if runmode = 45 {
            set sVal to lookDirUp(ship:prograde:vector, sun:position) + r(0, 0, _rVal).

            set target to "".
            //warp_to_next_soi().
            update_display().

            set runmode to 50.
        }

        else if runmode = 50 {
            //stage.

            set runmode to 55.
        }

        //Sets up triggers for science experiments
        else if runmode = 55 {
            set sVal to lookDirUp(ship:prograde:vector, sun:position) + r(0, 0, _rVal).

            until ship:body:name = _tgt {
                update_display().
            }

            if warp > 0 set warp to 0. 
            wait until kuniverse:timewarp:issettled.

            when ship:altitude > 30000 then {
                log_sci_list(sciList).
                recover_sci_list(sciList).
            }
            when ship:altitude < 30000 then {
                log_sci_list(sciList).
                recover_sci_list(sciList).
            }

            set runmode to 60.
        }

        //Adds a circularization node to the flight plan to capture into orbit around target, using desired tPe0
        else if runmode = 60 {
            set sVal to lookDirUp(ship:prograde:vector, sun:position) + r(0, 0, _rVal).

            set mnvNode to add_simple_circ_node("pe", tgtAp0).
            set mnvNode to optimize_existing_node(mnvNode, tgtAp0, "pe").

            set runmode to 62.
        }

        //Gets burn data from the node
        else if runmode = 62 {
            set sVal to lookDirUp(nextNode:burnvector, sun:position) + r(0, 0, _rVal).

            set mnvObj to get_burn_obj_from_node(mnvNode).

            set mnvObj["mnv"] to mnvNode. 
            set runmode to 64.
        }

        //Warps to the burn node
        else if runmode = 64 {
            set sVal to lookDirUp(nextNode:burnvector, sun:position) + r(0, 0, _rVal).

            warp_to_burn_node(mnvObj).

            set runmode to 66.
        }

        //Executes the circ burn
        else if runmode = 66 {
            set sVal to lookDirUp(nextNode:burnvector, sun:position) + r(0, 0, _rVal).

            exec_node(nextNode).
            wait 2.

            set runmode to 68.
        }

        else if  runmode = 68 {

            // Evaluates the results of the burn using semimajoraxis
            // If result * 0.990 < target > result * 1.010 then re-circularize 
            local tgtSMA to tgtAp0 + tgtPe0 + (ship:body:radius).
            local resultSMA to apoapsis + periapsis + (ship:body:radius).

            if resultSMA / tgtSMA < 0.985 or resultSMA / tgtSMA > 1.015 {
                set runmode to 76.
            } else {
                set runmode to 84.
            }
        }

        //Adds a circularization node to finish circ in lower orbit 
        else if runmode = 76 {
            set sVal to lookDirUp(ship:prograde:vector, sun:position) + r(0, 0, _rVal).

            set mnvNode to add_simple_circ_node("ap", tgtPe0).
            set mnvNode to optimize_existing_node(mnvNode, tgtPe0, "ap ").

            set runmode to 78.
        }

        //Gets burn data from the node
        else if runmode = 78{
            set sVal to lookDirUp(nextNode:burnvector, sun:position) + r(0, 0, _rVal).

            set mnvObj to get_burn_obj_from_node(mnvNode).
            set mnvObj["mnv"] to mnvNode. 

            set runmode to 80.
        }

        //Warps to the burn node
        else if runmode = 80 {
            set sVal to lookDirUp(nextNode:burnvector, sun:position) + r(0, 0, _rVal).

            warp_to_burn_node(mnvObj).

            set runmode to 82.
        }

        //Executes the circ burn
        else if runmode = 82 {
            exec_node(nextNode).
            wait 2.
            set runmode to 84.
        }

        // Set our inclination for scanning
        else if runmode = 84 {
            runPath("0:/_main/component/simple_inclination_change", tgtInc).
            set runmode to 86.
        }

        //Runs the biome science routine
        else if runmode = 86 {
            runPath("0:/_main/component/sci_for_biome").
            set runmode to 90.
        }

        //Preps the vessel for long-term orbit
        else if runmode = 90 {
            set sVal to lookDirUp(ship:prograde:vector, sun:position) + r(0, 0, _rVal).

            end_main().

            set runmode to 99.
        }

        //Logs the runmode change and writes to disk in case we need to resume the script later
        set stateObj["runmode"] to runmode.
        log_state(stateObj).
    }
}

local function end_main {
    set sVal to lookDirUp(ship:prograde:vector, sun:position) + r(0, 0, _rVal).
    lock steering to sVal.

    set tVal to 0.
    lock throttle to tVal.

    logStr("Mission completed").
}