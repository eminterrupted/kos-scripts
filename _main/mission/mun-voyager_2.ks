@lazyGlobal off.

parameter tgt is "Mun",
          rVal is 0.

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

disp_main().

wait 5.

local tgtAp0 is 306000.
//local tgtPe0 is 306000.

local tgtAp1 is 50000.
local tgtPe1 is 50000.


local sciList to get_sci_mod_for_parts(ship:parts).

local mnvNode is 0.
local mnvObj is lex().

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
            log_sci_list(sciList).
            recover_sci_list(sciList).
            update_display().
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
            set mnvObj to add_burn_node(mnvObj, tgtAp0, "pe").
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
            when ship:altitude > 250000 then {
                log_sci_list(sciList).
                recover_sci_list(scilist).
            }
            set runmode to 50.
        }

        //Clears the target data so we don't have weird behaviors when we reach its SOI
        //Then warps to the SOI change
        else if runmode = 50 {
            set_target("").
            warp_to_next_soi().
            set runmode to 55.
            update_display().
        }

        //Sets up triggers for science experiments
        else if runmode = 55 {
            when ship:altitude > 30000 then {
                log_sci_list(sciList).
                recover_sci_list(sciList).
            }
            when ship:altitude < 30000 then {
                log_sci_list(sciList).
                recover_sci_list(sciList).
            }
            set runmode to 60.
            update_display().
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
            exec_burn(mnvNode).
            wait 2.
            set runmode to 68.
        }

        //Adds a hohmann burn to lower Pe
        else if runmode = 68 {
            set mnvNode to add_simple_circ_node("ap", tgtPe1).
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
            set runmode to 76.
        }

        //Adds a circularization node to finish circ in lower orbit
        else if runmode = 76 {
            set mnvNode to add_simple_circ_node("pe", tgtAp1).
            set runmode to 78.
        }

        //Gets burn data from the node
        else if runmode = 78{
            set mnvObj to get_burn_obj_from_node(mnvNode).
            set mnvObj["mnv"] to mnvNode. 
            set runmode to 80.
        }

        //Warps to the burn node
        else if runmode = 80 {
            warp_to_burn_node(mnvObj).
            set runmode to 82.
        }

        //Executes the circ burn
        else if runmode = 82 {
            exec_burn(mnvNode).
            wait 2.
            set runmode to 84.
        }

        //Preps the vessel for long-term orbit
        else if runmode = 84 {
            end_main().
            set runmode to 99.
        }

        //Logs the runmode change and writes to disk in case we need to resume the script later
        set stateObj["runmode"] to runmode.
        log_state(stateObj).
    }
}


//Functions
local function set_target {
    parameter pTgt.

    set sVal to ship:prograde + r(0, 0, rVal).
    lock steering to sVal.

    set tVal to 0.
    lock throttle to tVal.

    set target to pTgt.

    update_display().
}


local function add_burn_node {
    parameter burnObj,
              tgtAlt,
              mode.
    
    local mnvList to list(burnObj["nodeAt"], 0, 0, burnObj["dv"]).
    set mnvNode to add_optimized_node(mnvList, tgtAlt, mode).

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
    set sVal to ship:prograde + r(0, 0, rVal).
    lock steering to sVal.

    set tVal to 0.
    lock throttle to tVal.

    logStr("Mission completed").
}


local function deploy_dish {
    for p in ship:partsTaggedPattern("comm.dish") {
        activate_antenna(p).
    }
}