@lazyGlobal off.

parameter tgt is "Minmus".

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
local biomeSciPath to "local:/biomeSci".
copyPath("0:/_main/component/sci_for_biome", biomeSciPath).

local matchOrbitInc to "local:/matchOrbit".
copyPath("0:/_main/component/match_orbit_inclination", matchOrbitInc).

//local stateObj to init_state_obj().
local runmode to stateObj["runmode"].
if runmode = 99 set runmode to 0.

disp_main().


local mnvNode is 0.
local mnvObj is lex().
local sciList to get_sci_mod_for_parts(ship:parts).
local tgtAp0 is 150000.
local tgtPe0 is 150000.
local tStamp to 0.

local sVal is lookdirup(ship:prograde:vector, sun:position).
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
            if p:length > 0 activate_antenna(p[0]).

            for o in ship:partsTaggedPattern("comm.omni") {
                activate_antenna(o).
            }
            
            set runmode to 8.
        }

        //Match the target inclination
        else if runmode = 8 {
            runPath(matchOrbitInc, body("minmus"):orbit).
            set runmode to 10.
        }

        //Sets the transfer target
        else if runmode = 10 {
            set target to body(tgt).
            set runmode to 15.
            update_display().
        }

        //Returns needed parameters for the transfer burn
        else if runmode = 15 {
            set mnvObj to get_transfer_obj().
            set runmode to 25.
        }

        //Adds the transfer burn node to the flight plan
        else if runmode = 25 {
            local accuracy to list(0.85, 1.15).
            set mnvObj to add_burn_node(mnvObj, tgtPe0, "pe", accuracy).
            set runmode to 30.
        }

        //Warps to the burn node
        else if runmode = 30 {
            warp_to_burn_node(mnvObj).
            set runmode to 35.
        }

        //Executes the transfer burn
        else if runmode = 35 {
            exec_node(mnvObj["mnv"]).
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
                disp_timer(tStamp).
            }

            disp_clear_block("timer").

            if warp > 0 kuniverse:timewarp:cancelwarp().
            wait until kuniverse:timewarp:issettled.
            set runmode to 60.
        }

        //Adds a circularization node to the flight plan to capture into orbit around target, using desired tPe0
        else if runmode = 60 {
            set mnvNode to add_simple_circ_node("pe", tgtAp0).
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
            set mnvNode to add_simple_circ_node("ap", tgtPe0).
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
            exec_burn(mnvNode).
            set runmode to 75.
        }

        else if runmode = 75 {
            set tStamp to time:seconds + 21600.
            set runmode to 76.
        }

        else if runmode = 76 {
            runPath("0:/a/simple_inclination_change", 75).
            set runmode to 78.
        }

        else if runmode = 78 {
        
            runPath(biomeSciPath).
           
            set runmode to 80.
        }

        else if runmode = 255 {
            update_display().
        }

        //Preps the vessel for long-term orbit
        else if runmode = 80 {
            end_main().
            set runmode to 99.
        }

        //Logs the runmode change and writes to disk in case we need to resume the script later
        set stateObj["runmode"] to runmode.
        log_state(stateObj).
    }
}


//Functions
local function add_burn_node {
    parameter burnObj,
              tgtAlt,
              mode,
              accuracy.
    
    local mnvList to list(burnObj["nodeAt"], 0, 0, burnObj["dv"]).
    set mnvNode to add_optimized_node(mnvList, tgtAlt, mode, accuracy).

    set mnvObj["nodeAt"] to time:seconds + mnvNode:eta.
    set mnvObj["burnEta"] to (mnvNode:eta + time:seconds) - (mnvObj["burnDur"] / 2).
    set mnvObj["mnv"] to mnvNode.
    
    update_display().

    return mnvObj.
}


local function exec_burn {
    parameter burnNode.

    exec_node(burnNode).

    update_display().
}


local function end_main {
    lock steering to lookdirup(ship:prograde:vector, sun:position).
    unlock throttle.

    logStr("Mission completed").
}


local function deploy_dish {
    for p in ship:partsTaggedPattern("comm.dish") {
        activate_antenna(p).
    }
}