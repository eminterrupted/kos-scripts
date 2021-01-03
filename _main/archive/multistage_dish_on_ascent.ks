@lazyGlobal off. 

parameter tApo to 125000,
          tPe to 125000,
          tInc to 0,
          tGTurnAlt to 60000,
          tGEndPitch to 3,
          rVal to 0.

clearScreen.
runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/lib_log").
runOncePath("0:/lib/display/lib_display").
runOncePath("0:/lib/lib_launch").
runOncePath("0:/lib/lib_core").
runOncePath("0:/lib/lib_sci").
runOncePath("0:/lib/lib_warp").
runOncePath("0:/lib/lib_pid").
runOncePath("0:/lib/lib_misc_parts").
runOncePath("0:/lib/data/engine/lib_engine").
runOncePath("0:/lib/data/engine/lib_isp").
runOncePath("0:/lib/data/engine/lib_thrust").

runOncePath("0:/lib/nav/lib_nav").
runOncePath("0:/lib/nav/lib_node").
runOncePath("0:/lib/nav/lib_calc_mnv").
runOncePath("0:/lib/data/ship/lib_mass").
runOncePath("0:/lib/part/lib_fairing").
runOncePath("0:/lib/part/lib_antenna").
runOncePath("0:/kslib/library/lib_l_az_calc").

//
//** Main

//Vars
//local stateObj to init_state_obj().
local runmode to stateObj["runmode"].

local azObj to l_az_calc_init(tApo, tInc).
local burnObj is lex().
local burnNode is node(0, 0, 0, 0).
local dispState to lex().
local acc is ship:maxThrust / ship:mass.
local maxAcc is 30.
local maxQ is 0.10.
local qPid to setup_q_pid(maxQ).
local accPid to setup_acc_pid(maxAcc).

local sVal to heading(90, 90, -90).
lock steering to sVal.

local tVal to 0.
lock throttle to tVal.

local gtStart is 750.

main().

//Main
local function main {
    
    clearScreen.
    set runmode to preLaunch().

    print "MSG: Executing launch()                      " at (2, 7).
    set runmode to launch().

    print "MSG: Executing clear_tower()                 " at (2, 7).
    set runmode to clear_tower().

    print "MSG: Executing roll_program()                " at (2, 7).
    set runmode to roll_program().

    print "MSG: Executing vertical_ascent()             " at (2, 7).
    set runmode to vertical_ascent().

    print "MSG: Executing gravity turn()                " at (2, 7).
    set runmode to gravity_turn().

    print "MSG: Executing slow_burn_to_apo()            " at (2, 7).
    set runmode to slow_burn_to_apo().

    print "MSG: Executing meco()                        " at (2, 7).
    set runmode to meco().

    print "MSG: Executing coast_to_space()              " at (2, 7).
    set runmode to coast_to_space().

    print "MSG: Executing setup_circularization_burn()  " at (2, 7).
    set runmode to setup_circularization_burn().

    print "MSG: Executing deploy_dish()                 " at (2, 7).
    set runmode to deploy_dish_panels().

    print "MSG: Executing warp_to_circ_burn()           " at (2, 7).
    set runmode to warp_to_circ_burn().

    print "MSG: Executing exec_circularization_burn()   " at (2, 7).
    set runmode to exec_circularization_burn().

    print "MSG: Executing prep_for_orbit()              " at (2, 7).
    set runmode to prep_for_orbit().
    
    print "MSG: Executing cleanup()                     " at (2, 7).
    set runmode to cleanup().

    print "MSG: Executing end_main()                    " at (2, 7).
    set runmode to end_main().

    clearScreen.
}


//Functions
local function preLaunch {
    logStr("Preparing for launch").
    
    disp_main().

    set runmode to 2.
    set stateObj["runmode"] to runmode.
    log_state(stateObj).

    return runmode.
}


local function launch {
    logStr("Begin launch procedure").

    if ship:partsTaggedPattern("pl.st.fairing"):length > 0 {
        arm_stock_fairings(72500, ship:partsTaggedPattern("pl.st.fairing")[0]).
    } 
    else if ship:partsTaggedPattern("pl.pf.base"):length > 0 {
        arm_proc_fairings(72500, ship:partsTaggedPattern("pl.pf.base")[0]).
    }

    launch_vessel(10).
    set tVal to 1.

    update_display().

    set runmode to 4.
    set stateObj["runmode"] to runmode.
    log_state(stateObj).
    
    return runmode.
}    


local function clear_tower {
    logStr("Liftoff!").
    
    //Wait until tower is effectively cleared
    until alt:radar >= 100 {
        set sVal to heading(90, 90, -90).
        lock steering to sVal.
        set tVal to 1.
        update_display().
    }
    
    logStr("Tower cleared").
    update_display().

    set runmode to 6.
    set stateObj["runmode"] to runmode.
    log_state(stateObj).

    return runmode.
}
    

local function roll_program {
    logStr("Roll program").

    set tVal to 1.
    set sVal to heading(l_az_calc(azObj), 90, rVal).
    lock steering to sVal.
    
    update_display().

    set runmode to 8.
    set stateObj["runmode"] to runmode.
    log_state(stateObj).

    return runmode.
}


local function vertical_ascent {
    logStr("Vertical ascent").
    
    set tVal to 1.

    //Setup staging trigger
    when ship:availableThrust < 0.1 and tVal > 0 then {
        safe_stage().
        preserve.
    }

    //Ascent loop
    until ship:verticalSpeed >= 100 or ship:altitude >= 750 {
        set sVal to heading(l_az_calc(azObj), 90, rVal).
        lock steering to sVal.

        update_display().
    }
    
    set gtStart to ship:altitude.
    
    set runmode to 10.
    set stateObj["runmode"] to runmode.
    log_state(stateObj).
    
    return runmode.
}

local function gravity_turn {
    logStr("Pitch program").
    
    when ship:q >= maxQ then logStr("Approaching Max-Q").
    when acc >= maxAcc then logStr("Throttling back at maximum acceleration").

    //Gravity turn loop
    until ship:apoapsis >= tApo * 0.925 {
        set sVal to heading(l_az_calc(azObj), get_la_for_alt(tGEndPitch, tGTurnAlt, gtStart), rVal).
        lock steering to sVal.

        set acc to ship:maxThrust / ship:mass.

        //Check for throttle conditions, otherwise keep it at 100%
        if ship:q >= maxQ {
            set tVal to max(0, min(1, 1 + qPid:update(time:seconds, ship:q))). 
        } else if acc >= maxAcc - 5 {
            set tVal to max(0, min(1, 1 + accPid:update(time:seconds, acc))).
        } else {
            set tVal to 1.
        }
        lock throttle to tVal.

        update_display().
    }
    
    set runmode to 12.
    set stateObj["runmode"] to runmode.
    log_state(stateObj).
    
    return runmode.   
}

local function slow_burn_to_apo {
    logStr("Throttling back near apoapsis. [CurAlt:" + round(ship:altitude) + "][Apo:" + round(ship:apoapsis) + "]").

    until ship:apoapsis >= tApo {
        set sVal to heading(l_az_calc(azObj), get_la_for_alt(tGEndPitch, tGTurnAlt, gtStart), rVal).
        lock steering to sVal.

        set tval to 0.25.
        lock throttle to tVal.

        update_display().
    }
    
    set runmode to 14. 
    set stateObj["runmode"] to runmode.
    log_state(stateObj).
    
    return runmode.
}

local function meco {
    logStr("MECO").

    set sVal to heading(l_az_calc(azObj), get_la_for_alt(tGEndPitch, tGTurnAlt, gtStart), rVal).
    lock steering to sVal.

    set tVal to 0.
    lock throttle to tVal.

    update_display().

    set runmode to 16.
    set stateObj["runmode"] to runmode.
    log_state(stateObj).
    
    return runmode.
}

local function coast_to_space {
    logStr("Coast phase").

    until ship:altitude >= body:atm:height {
        set sVal to ship:prograde + r(0, 0, rVal).
        lock steering to sVal.

        if ship:apoapsis >= tApo {
            set tVal to 0.
        } else {
            set tVal to 0.25.
        }
        lock throttle to tVal.

        update_display().
    }

    logStr("Reached space").

    set runmode to 18.
    set stateObj["runmode"] to runmode.
    log_state(stateObj).
    
    return runmode.
}

local function setup_circularization_burn {
    logStr("Setting up circularization burn object").
    
    set sVal to ship:prograde + r(0, 0, rVal).
    lock steering to sVal.

    set tVal to 0. 
    lock throttle to tVal.

    //Add the circ node
    set burnNode to add_simple_circ_node("ap", tPe).
    set burnObj to get_burn_obj_from_node(burnNode).

    if dispState:hasKey("burn_data") disp_burn_data(burnObj).
    else set dispState["burn_data"] to disp_burn_data(burnObj).

    logStr("Burn object created").

    set runmode to 20.
    set stateObj["runmode"] to runmode.
    log_state(stateObj).
    
    return runmode.
}

local function deploy_dish_panels {
    logStr("Deploying dish antenna").

    set sVal to lookdirup(burnNode:burnvector, sun:position).
    lock steering to sVal.

    local idx to 0.
    for d in ship:partstaggedpattern("dish") {
        if idx = 0 set_dish_target(d, "kerbin").
        else set_dish_target(d, "mun").

        activate_dish(d).
    }

    panels on.

    set runmode to 21.
    set stateObj["runmode"] to runmode.
    log_state(stateObj).

    return runmode.
}

local function warp_to_circ_burn {
    logStr("Warping to circularization burn").

    set sVal to lookdirup(burnNode:burnvector, sun:position).
    lock steering to sVal.

    set tVal to 0.
    lock throttle to tVal.

    until steeringManager:angleerror >= -0.1 and steeringManager:angleError <= 0.1 {
        update_display().
        disp_burn_data(burnObj).
    }
    
    if burnObj["burnEta"] - time:seconds > 30 warpTo(burnObj["burnEta"] - 15).

    until time:seconds >= burnObj["burnEta"] {
        set sVal to burnNode.
        lock steering to sVal.

        update_display().
        disp_burn_data(burnObj).
    }

    set runmode to 22.
    set stateObj["runmode"] to runmode.
    log_state(stateObj).
    
    return runmode.
}


local function exec_circularization_burn {
    logStr("Executing circularization burn").

    until burnNode:burnvector:mag <= 10 {
        set sVal to lookDirUp(burnNode:burnvector, sun:position).
        //set sVal to burnNode.
        lock steering to sVal.

        set tval to 1.
        lock throttle to tVal.
        
        update_display().
    }

    until ship:apoapsis >= tPe {
        set sVal to lookDirUp(burnNode:burnVector, sun:position). 
        //set sVal to burnNode.
        lock steering to sVal.

        set tval to max(0, min(0.125, burnNode:burnVector:mag / 10)).
        lock throttle to tVal.

        update_display().
    }
    set tVal to 0.
    lock throttle to tVal.

    remove burnNode.

    set runmode to 24. 
    set stateObj["runmode"] to runmode.
    log_state(stateObj).

    return runmode.
}


local function prep_for_orbit {
    logStr("Preparing for orbit").
    
    logStr("Deploying solar panels").
    panels on.

    logStr("Verifying connection to KSC").
    if not addons:rt:hasKscConnection(ship) activate_omni(ship:partsTaggedPattern("comm.omni")[0]).
    logStr("Orbtial configuration set").

    update_display().

    set runmode to 28.
    set stateObj["runmode"] to runmode.
    log_state(stateObj).
    
    return runmode.
}

local function cleanup {
    logStr("Unlocking controls").
    unlock steering.
    unlock throttle.

    update_display().

    set runmode to 30.
    set stateObj["runmode"] to runmode.
    log_state(stateObj).
    
    return runmode.
}

local function end_main {
    logStr("Preparing for mission script handoff").
    
    panels on.

    disp_clear_block_all().
    logStr("Ship ready for mission script").
    
    set runmode to 99.
    set stateObj["runmode"] to runmode.
    log_state(stateObj).
    
    return runmode.
}