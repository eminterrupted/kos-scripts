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
runOncePath("0:/lib/lib_display").
runOncePath("0:/lib/lib_launch").
runOncePath("0:/lib/lib_core").
runOncePath("0:/lib/lib_sci").
runOncePath("0:/lib/lib_warp").
runOncePath("0:/lib/lib_pid").
runOncePath("0:/lib/lib_misc_parts").
runOncePath("0:/lib/data/engine/lib_engine").
runOncePath("0:/lib/data/engine/lib_isp").
runOncePath("0:/lib/data/engine/lib_thrust").
runOncePath("0:/lib/data/engine/lib_twr").
runOncePath("0:/lib/data/nav/lib_nav").
runOncePath("0:/lib/data/ship/lib_mass").
runOncePath("0:/lib/part/lib_fairing").
runOncePath("0:/lib/part/lib_antenna").
runOncePath("0:/kslib/library/lib_l_az_calc").

//
//** Main

//Vars
local stateObj to init_state_obj().
local runmode to stateObj["runmode"].

local azObj to l_az_calc_init(tApo, tInc).
local burnObj is lex().
local dispState to lex().
local acc is ship:maxThrust / ship:mass.
local maxAcc is 35.
local maxQ is 0.10.
local qPid to setup_q_pid(maxQ).
local accPid to setup_acc_pid(maxAcc).

local sVal to heading(90, 90, -90).
lock steering to sVal.

local tVal to 0.
lock throttle to tVal.

local gtStart is 1250.

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

    print "MSG: Executing warp_to_circ_burn()           " at (2, 7).
    set runmode to warp_to_circ_burn().

    print "MSG: Executing exec_circularization_burn()   " at (2, 7).
    set runmode to exec_circularization_burn().

    print "MSG: Executing slow_burn_to_pe()             " at (2, 7).
    set runmode to slow_burn_to_pe().

    print "MSG: Executing prep_for_orbit()              " at (2, 7).
    set runmode to prep_for_orbit().
    
    print "MSG: Executing cleanup()                     " at (2, 7).
    set runmode to cleanup().

    print "MSG: Executing end_main()                    " at (2, 7).
    set runmode to end_main().

    clearScreen.
}


//Functions
local function update_display {
    disp_launch_main().
    disp_obt_data().
    disp_tel().
    disp_eng_perf_data().
}


local function preLaunch {
    logStr("Preparing for launch").
    
    disp_launch_main().

    set runmode to 2.
    set stateObj["runmode"] to runmode.
    log_state(stateObj).

    return runmode.
}


local function launch {
    logStr("Begin launch procedure").

    if ship:partsTaggedPattern("pl.st.fairing"):length > 0 {
        arm_stock_fairings(75000, ship:partsTaggedPattern("pl.st.fairing")[0]).
    } 
    else if ship:partsTaggedPattern("pl.pf.base"):length > 0 {
        arm_proc_fairings(75000, ship:partsTaggedPattern("pl.pf.base")[0]).
    }

    launch_vessel(30).
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
    until ship:verticalSpeed >= 100 or ship:altitude >= 1000 {
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
    
    when ship:q >= .125 then logStr("Approaching Max-Q").
    when acc >= 30 then logStr("Throttling back at maximum acceleration").

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

        set tval to 1 - max(0, min(1, (ship:apoapsis * 0.075 / tApo * 0.075 ))).
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
    
    set sVal to heading(l_az_calc(azObj), get_circ_burn_pitch(), rVal).
    lock steering to sVal.

    set tVal to 0. 
    lock throttle to tVal.

    set burnObj to get_circ_burn_data(tPe).
    if dispState:hasKey("burn_data") disp_burn_data(burnObj).
    else set dispState["burn_data"] to disp_burn_data(burnObj).

    logStr("Burn object created").

    set runmode to 20.
    set stateObj["runmode"] to runmode.
    log_state(stateObj).
    
    return runmode.
}

local function warp_to_circ_burn {
    logStr("Warping to circularization burn").

    set sVal to heading(l_az_calc(azObj), get_circ_burn_pitch(), rVal).
    lock steering to sVal.

    set tVal to 0.
    lock throttle to tVal.

    until steeringManager:angleerror >= -0.25 and steeringManager:angleError <= 0.25 {
        update_display().
        disp_burn_data(burnObj).
    }
    
    if burnObj["burnEta"] - time:seconds > 30 warpTo(burnObj["burnEta"] - 30).

    until time:seconds >= burnObj["burnEta"] - 5 {
        set sVal to heading(l_az_calc(azObj), get_circ_burn_pitch(), rVal).
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

    until ship:periapsis >= tPe * 0.925 {
        set sVal to heading(l_az_calc(azObj), get_circ_burn_pitch(), rVal).
        lock steering to sVal.
        
        set tVal to 1.
        lock throttle to tVal.

        update_display().
        disp_burn_data(burnObj).
    }

    set runmode to 24. 
    set stateObj["runmode"] to runmode.
    log_state(stateObj).
    
    return runmode.
}


local function slow_burn_to_pe {
    logStr("Throttling back at Pe target approach [CurAlt:" + round(ship:altitude) + "][Pe:" + round(ship:periapsis) + "]").

    until ship:periapsis >= tPe {
        set sVal to heading(l_az_calc(azObj), get_circ_burn_pitch(), rVal).
        lock steering to sVal.

        set tVal to 1 - max(0, min(1, (ship:periapsis * 0.075 / tPe * 0.075))).
        lock throttle to tVal.

        update_display().
        disp_burn_data(burnObj).
    }

    set sVal to ship:prograde + r(0, 0, rVal).
    lock steering to sVal.

    set tVal to 0.
    lock throttle to tVal.

    logStr("SECO").
    logStr("Circularized at [Apo: " + round(ship:apoapsis) + "][Pe: " + round(ship:periapsis) + "]").
    disp_clear_block("burn_data").

    set runmode to 26.
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
    
    from { local n is 10.} until n <= 0 step { set n to n - 1.} do {
        update_display().
        disp_timer(n).
    }

    disp_clear_block("timer").
    logStr("Ship ready for mission script").
    
    set runmode to 99.
    set stateObj["runmode"] to runmode.
    log_state(stateObj).
    
    return runmode.
}