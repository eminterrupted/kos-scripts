@lazyGlobal off.

parameter tgt is "Mun",
          rVal is 0.

clearscreen.

runOncePath("0:/lib/lib_display").
runOncePath("0:/lib/lib_core").
runOncePath("0:/lib/data/nav/lib_deltav").
runOncePath("0:/lib/data/nav/lib_nav").
runOncePath("0:/lib/lib_util").
runOncePath("0:/lib/data/nav/lib_node").
runOncePath("0:/lib/part/lib_antenna").
runOncePath("0:/lib/lib_dmag_sci").
runOncePath("0:/lib/lib_sci").

local stateObj to init_state_obj().
local runmode to stateObj["runmode"].
if runmode = 99 set runmode to 0.

disp_obt_main().

wait 5.

local finalAlt is 30000.
local waitTime is 0 + time:seconds.

local sciMod is list().
local dmagMod is list().

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
        if runmode = 0 {
            set_target(tgt).
            set runmode to 5.
        }
        
        else if runmode = 5 {
            get_sci_modules().
            set runmode to 10.
        }

        else if runmode = 10 {
            log_sci_exp(dmagMod).
            set runmode to 15.
        }

        else if runmode = 15 {
            get_transfer_obj().
            set runmode to 20.
        }

        else if runmode = 20 {
            warp_to_waittime(waitTime).
            set runmode to 25.
        }

        else if runmode = 25 {
            add_burn_node(mnvObj, finalAlt).
            set runmode to 30.
        }

        else if runmode = 30 {
            warp_to_burn_node(mnvNode).
            set runmode to 35.
        }

        else if runmode = 35 {
            exec_burn(mnvNode).
            set runmode to 40.
        }

        else if runmode = 40 {
            deploy_dish().
            set runmode to 45.
        }

        else if runmode = 45 {
            set runmode to 50.
        }

        else if runmode = 50 {
            set_target("").
            warp_to_next_soi().
            set runmode to 55.
        }

        else if runmode = 55 {
            log_sci_exp(dmagMod).
            set runmode to 60.
        }

        else if runmode = 60 {
            set mnvNode to add_simple_circ_node("pe").
            set runmode to 65.
        }

        else if runmode = 65 {
            set mnvObj to get_burn_obj_from_node(mnvNode).
            set runmode to 70.
        }

        else if runmode = 70 {
            warp_to_burn_node(mnvNode).
            set runmode to 75.
        }

        else if runmode = 75 {
            exec_burn(mnvNode).
            set runmode to 80.
        }

        else if runmode = 80 {
            log_sci_exp(sciMod).
            set runmode to 85.
        }

        else if runmode = 85 {
            end_main().
            set runmode to 99.
        }

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

    update_disp().
}


local function get_sci_modules {
    set sVal to ship:prograde + r(0, 0, rVal).
    lock steering to sVal.

    set tVal to 0.
    lock throttle to tVal.
    
    set sciMod to get_sci_mod().
    set dmagMod to get_dmag_mod().

    update_disp().
}


local function log_sci_exp {
    parameter modList.
    
    set sVal to ship:prograde + r(0, 0, rVal).
    lock steering to sVal.

    set tVal to 0.
    lock throttle to tVal.
    
    if modList:length > 0 {
        if modlist[0]:name = ("ModuleScienceExperiment") log_sci_list(modList).
        else if modList[0]:name = ("DMModuleScienceAnimate") log_dmag_list(modList).
    }
    recover_sci_list(modList, true).

    update_disp().
}


local function get_transfer_obj {
    set sVal to ship:prograde + r(0, 0, rVal).
    lock steering to sVal.

    set tVal to 0.
    lock throttle to tVal.
    
    local window to get_mun_xfr_window().
    local burn to get_mun_xfr_burn_data(window["nodeAt"]).

    set mnvObj["tgt"] to target.

    for key in window:keys {
        set mnvObj[key] to window[key].
    }

    update_phase().

    for key in burn:keys {
        set mnvObj[key] to burn[key].
    }
    
    update_disp().
}


local function warp_to_waittime {
    parameter tstamp.

    set sVal to ship:prograde + r(0, 0, rVal).
    lock steering to sVal.

    set tVal to 0.
    lock throttle to tVal.

    until time:seconds >= tstamp {
        if warp = 0 and steeringmanager:angleerror >= -0.1 and steeringmanager:angleerror <= 0.1 set warp to 3. 
        update_disp().
    }

    kuniverse:timewarp:cancelwarp().
    wait until kuniverse:timewarp:issettled.

    update_disp().
}


local function add_burn_node {
    parameter burnObj,
              tgtAlt.

    set sVal to ship:prograde + r(0, 0, rVal).
    lock steering to sVal.

    set tVal to 0.
    lock throttle to tVal.
    
    local mnvList to list(burnObj["nodeAt"], 0, 0, burnObj["dv"]).
    set mnvNode to add_optimized_node(mnvList, tgtAlt).

    set mnvObj["nodeAt"] to time:seconds + mnvNode:eta.
    set mnvObj["burnEta"] to (mnvNode:eta + time:seconds) - (mnvObj["burnDur"] / 2).
    
    update_disp().
}


local function warp_to_burn_node {
    parameter burnNode.
    
    until time:seconds >= (mnvObj["burnEta"] - 30) {
        set sVal to burnNode:burnVector:direction + r(0, 0, rval - 90).
        lock steering to sVal.

        if warp = 0 and steeringmanager:angleerror >= -0.1 and steeringmanager:angleerror <= 0.1 warpTo(mnvObj["burnEta"] - 30).     
        update_disp().
    }

    if warp > 0 kuniverse:timewarp:cancelwarp().
    wait until kuniverse:timewarp:issettled.
    
    until time:seconds >= mnvObj["burnEta"] {
        update_disp().
        disp_burn_data(mnvObj).
    }

    update_disp().
}


local function exec_burn {
    parameter burnNode.

    until burnNode:burnvector:mag <= 5 {
        set sVal to burnNode:burnVector:direction + r(0, 0, rval - 90).
        lock steering to sVal.

        set tval to 1.
        lock throttle to tVal.
        
        update_disp().
    }

    until burnNode:burnvector:mag <= 0.1 {
        set sVal to burnNode:burnVector:direction + r(0, 0, rval - 90).
        lock steering to sVal.

        set tval to max(0, min(1, burnNode:burnVector:mag / 5)).
        lock throttle to tVal.

        update_disp().
    }

    set tVal to 0.
    lock throttle to tVal.

    remove burnNode.

    update_disp().
}


local function warp_to_next_soi {
    set sVal to ship:prograde + r(0, 0, rval). 
    lock steering to sval.

    if ship:obt:hasnextpatch {
        wait until steeringmanager:angleerror >= -0.1 and steeringmanager:angleerror <= 0.1. 
        warpTo(ship:obt:nextpatcheta + time:seconds - 30).
    }
        
    until ship:body:name = tgt {
        set sVal to ship:prograde + r(0, 0, rVal).
        lock steering to sVal.
        update_disp().
    }

    if warp > 0 kuniverse:timewarp:cancelwarp().
    wait until kuniverse:timewarp:issettled.

    update_disp().
}


local function end_main {
    set sVal to ship:prograde + r(0, 0, rVal).
    lock steering to sVal.

    set tVal to 0.
    lock throttle to tVal.

    logStr("Mission completed").
}


local function update_disp {
    disp_obt_main().
    disp_obt_data().
    disp_tel().
    disp_eng_perf_data().
}


local function update_phase {
    set mnvObj["curPhaseAng"] to get_phase_angle().
}


local function deploy_dish {
    for p in ship:partsTaggedPattern("comm.dish") {
        activate_dish(p).
    }
}