@lazyGlobal off.

parameter _tgt is "Mun",
          runmodeReset to false.

clearscreen.

runOncePath("0:/lib/lib_display").
runOncePath("0:/lib/lib_core").
runOncePath("0:/lib/lib_sci").
runOncePath("0:/lib/lib_util").
runOncePath("0:/lib/lib_warp").
runOncePath("0:/lib/lib_calc_mnv").
runOncePath("0:/lib/lib_deltav").
runOncePath("0:/lib/lib_nav").
runOncePath("0:/lib/lib_node").
runOncePath("0:/lib/lib_mnv").
runOncePath("0:/lib/lib_antenna").

//local stateObj to init_state_obj().
local runmode to stateObj["runmode"].
if runmode = 99 set runmode to 0.
if runmodeReset set runmode to 0.

disp_main().

wait 5.

local tgtAp0 is 85000.
local tgtPe0 is 25000.

local collectSci is "local:/collectSci".
local mnvCache is "local:/mnvCache.json".
local mnvNode is 0.
local mnvObj is lex().
local sciList to get_sci_mod_for_parts(ship:parts).

copyPath("0:/_main/component/sci_for_biome", collectSci).
if exists(mnvCache) set mnvObj to mnvCache.

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

        //Deploy dish if not already
        if runmode = 0 {
            set sVal to lookDirUp(ship:prograde:vector, sun:position).

            local dish is ship:partsTaggedPattern("comm.dish").
            for d in dish {
                activate_antenna(d).
                logStr("Comm object Dish activated").
                wait 1.
                set_dish_target(d, kerbin:name).
                logStr("Dish target: " + kerbin:name).
            }

            set runmode to rm(2).
        }
        
        //Test science experiments
        else if runmode = 2 {
            set sVal to lookDirUp(ship:prograde:vector, sun:position).

            log_sci_list(sciList).
            recover_sci_list(sciList).
            update_display().

            set runmode to rm(4).
        }

        //Sets the transfer target
        else if runmode = 4 {
            set sVal to lookDirUp(ship:prograde:vector, sun:position).

            set target to _tgt.
            update_display().

            set runmode to rm(15).
        }


        //Returns needed parameters for the transfer burn
        else if runmode = 15 {
            set sVal to lookDirUp(ship:prograde:vector, sun:position).

            set runmode to rm(25).
        }

        //Adds the transfer burn node to the flight plan
        else if runmode = 25 {
            set sVal to lookDirUp(ship:prograde:vector, sun:position).

            set mnvObj to get_transfer_obj().
            set mnvObj to add_transfer_node(mnvObj, tgtAp0).
            
            set runmode to rm(30).
        }

        //Warps to the burn node
        else if runmode = 30 {
            set sVal to lookDirUp(nextNode:burnvector, sun:position).

            warp_to_burn_node(mnvObj).

            set runmode to rm(35).
        }

        //Executes the transfer burn
        else if runmode = 35 {
            set sVal to lookDirUp(nextNode:burnvector, sun:position).

            exec_node(nextNode).

            set runmode to rm(45).
        }

        //Clears the target data so we don't have weird behaviors when we reach its SOI
        //Then warps to the SOI change
        else if runmode = 45 {
            set sVal to lookDirUp(ship:prograde:vector, sun:position).

            set target to "".
            //warp_to_next_soi().
            update_display().

            set runmode to rm(50).
        }

        //Sets up triggers for science experiments
        else if runmode = 50 {
            set sVal to lookDirUp(ship:prograde:vector, sun:position).

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

            set runmode to rm(55).
        }

        //Adds a circularization node to the flight plan to capture into orbit around target, using desired tPe0
        else if runmode = 55 {
            set sVal to lookDirUp(ship:prograde:vector, sun:position).

            set mnvNode to add_simple_circ_node("pe", tgtAp0).

            set runmode to rm(62).
        }

        //Gets burn data from the node
        else if runmode = 62 {
            set sVal to lookDirUp(nextNode:burnvector, sun:position).

            set mnvObj to get_burn_obj_from_node(mnvNode).
            writeJson(mnvObj, mnvCache).

            set mnvObj["mnv"] to mnvNode. 
            set runmode to rm(64).
        }

        //Warps to the burn node
        else if runmode = 64 {
            set sVal to lookDirUp(nextNode:burnvector, sun:position).

            warp_to_burn_node(mnvObj).

            set runmode to rm(66).
        }

        //Executes the circ burn
        else if runmode = 66 {
            set sVal to lookDirUp(nextNode:burnvector, sun:position).

            exec_node(nextNode).
            wait 2.

            set runmode to rm(76).
        }

        //Adds a circularization node to finish orbit placement
        else if runmode = 76 {
            set sVal to lookDirUp(ship:prograde:vector, sun:position).

            set mnvNode to add_simple_circ_node("ap", tgtPe0).

            set runmode to rm(78).
        }

        //Gets burn data from the node
        else if runmode = 78{
            set sVal to lookDirUp(nextNode:burnvector, sun:position).

            set mnvObj to get_burn_obj_from_node(mnvNode).
            set mnvObj["mnv"] to mnvNode. 
            writeJson(mnvObj, mnvCache).

            set runmode to rm(80).
        }

        //Warps to the burn node
        else if runmode = 80 {
            set sVal to lookDirUp(nextNode:burnvector, sun:position).

            warp_to_burn_node(mnvObj).

            set runmode to rm(82).
        }

        //Executes the circ burn
        else if runmode = 82 {
            exec_node(nextNode).
            wait 2.
            set runmode to rm(84).
        }

        //Make the inclination change
        else if runmode = 84 {
            set sVal to lookDirUp(ship:prograde:vector, sun:position).

            runPath("0:/_main/component/simple_inclination_change", 75, 90).

            set runmode to rm(86).
        }

        //Runmode 88MPH - You're going to see some seriously mild shit
        //Collect science for all biomes
        else if runmode = 86 {
            runPath(collectSci).

            set runmode to rm(88).
        }

        //End main
        else if runmode = 88 {
            set sVal to lookDirUp(ship:prograde:vector, sun:position).

            end_main().

            set runmode to rm(99).
        }

        update_display().
    }
}

local function end_main {
    set sVal to lookDirUp(ship:prograde:vector, sun:position).
    lock steering to sVal.

    set tVal to 0.
    lock throttle to tVal.

    logStr("Mission completed").
}