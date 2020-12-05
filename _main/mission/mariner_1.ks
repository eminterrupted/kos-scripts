@lazyGlobal off.

parameter tgt is "Mun",
          rVal is 0.

clearscreen.

runOncePath("0:/lib/lib_display").
runOncePath("0:/lib/lib_core").
runOncePath("0:/lib/lib_sci_next").
runOncePath("0:/lib/lib_util").
runOncePath("0:/lib/lib_warp").
runOncePath("0:/lib/nav/lib_calc_mnv").
runOncePath("0:/lib/nav/lib_deltav").
runOncePath("0:/lib/nav/lib_nav").
runOncePath("0:/lib/nav/lib_node").
runOncePath("0:/lib/nav/lib_circ_burn").
runOncePath("0:/lib/part/lib_antenna").

//local stateObj to init_state_obj().
local runmode to stateObj["runmode"].
if runmode = 99 set runmode to 0.

disp_main().

wait 5.

local tgtAp0 is 50000.
local tgtPe0 is 50000.
local retPe is 100000.

local sciList to get_sci_mod_for_parts(ship:parts).

local mnvNode is 0.
local mnvObj is lex().

local sciStamp to 0.
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
            activate_dish(p[0]).

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
            set mnvObj to add_burn_node(mnvObj, tgtPe0, "pe").
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
            set_target("").
            warp_to_next_soi().
            update_display().
            set runmode to 55.
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
            set tStamp to time:seconds + 600.
            until time:seconds >= tStamp {
                update_display().
            }
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
            exec_burn(mnvNode).
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
            set sciStamp to time:seconds + 60.
            log_sci_list(sciList).
            collect_sci_in_container().
            reset_sci_list(sciList).
            
            set runmode to 77.
        }
            
        if runmode = 77 {
            until time:seconds >= tStamp {
                if time:seconds >= sciStamp set runmode to 76.
                update_display().
            }

            set target to Body("Kerbin").
            set runmode to 78.
        }

        else if runmode = 78 {
            set mnvObj to get_transfer_obj().
            set mnvObj to add_burn_node(mnvObj, retPe, "pe").
            update_display().
            set runmode to 80.
        }

        else if runmode = 80 {
            warp_to_burn_node(mnvObj).
            set runmode to 82.
        }

        else if runmode = 82 {
            exec_node(mnvObj["mnv"]).
            set runmode to 84.
        }

        else if runmode = 84 {
            set target to "".
            warp_to_next_soi().
            set runmode to 86.
        }

        else if runmode = 86 {
            update_display().
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


local function get_transfer_obj {
    set sVal to lookdirup(ship:prograde:vector, sun:position).
    lock steering to sVal.

    set tVal to 0.
    lock throttle to tVal.
    
    local window to get_mun_xfr_window().
    local burn to get_mun_xfr_burn_data(window["nodeAt"]).
    local xfrObj to lex("tgt", target).

    for key in window:keys {
        set xfrObj[key] to window[key].
    }

    update_phase().

    for key in burn:keys {
        set xfrObj[key] to burn[key].
    }
    
    update_display().

    return xfrObj.
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


local function warp_to_burn_node {
    parameter burnObj.
    
    until time:seconds >= (mnvObj["burnEta"] - 30) {
        set sVal to lookdirup(burnObj["mnv"]:burnVector, sun:position).
        lock steering to sVal.

        warp_to_timestamp(mnvObj["burnEta"]).

        update_display().
    }

    if warp > 0 kuniverse:timewarp:cancelwarp().
    wait until kuniverse:timewarp:issettled.
    
    until time:seconds >= mnvObj["burnEta"] {
        update_display().
        disp_burn_data().
    }

    update_display().
}


local function exec_burn {
    parameter burnNode.

    exec_node(burnNode).

    update_display().
}


local function warp_to_next_soi {
    set sVal to ship:prograde + r(0, 0, rval). 
    lock steering to sval.

    if ship:obt:hasnextpatch {
        wait until steeringmanager:angleerror >= -0.1 and steeringmanager:angleerror <= 0.1. 
        warpTo(ship:obt:nextpatcheta + time:seconds - 15).
    }
        
    until ship:body:name = tgt {
        set sVal to ship:prograde + r(0, 0, rVal).
        lock steering to sVal.
        update_display().
    }

    if warp > 0 kuniverse:timewarp:cancelwarp().
    wait until kuniverse:timewarp:issettled.

    update_display().
}


local function end_main {
    set sVal to ship:prograde + r(0, 0, rVal).
    lock steering to sVal.

    set tVal to 0.
    lock throttle to tVal.

    logStr("Mission completed").
}


local function update_phase {
    set mnvObj["curPhaseAng"] to get_phase_angle().
}


local function deploy_dish {
    for p in ship:partsTaggedPattern("comm.dish") {
        activate_dish(p).
    }
}