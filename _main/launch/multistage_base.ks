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
runOncePath("0:/lib/lib_warp").
runOncePath("0:/lib/lib_pid").
runOncePath("0:/lib/lib_misc_parts").
runOncePath("0:/lib/nav/lib_circ_burn").
runOncePath("0:/lib/nav/lib_node").

runOncePath("0:/lib/data/engine/lib_engine").
runOncePath("0:/lib/data/engine/lib_isp").
runOncePath("0:/lib/data/engine/lib_thrust").
runOncePath("0:/lib/data/engine/lib_twr").
runOncePath("0:/lib/nav/lib_nav").
runOncePath("0:/lib/nav/lib_node").
runOncePath("0:/lib/data/ship/lib_mass").

runOncePath("0:/lib/part/lib_fairing").
runOncePath("0:/lib/part/lib_antenna").

runOncePath("0:/kslib/library/lib_l_az_calc").

//
//** Main

//Vars
local runmode to stateObj["runmode"].

local maxAcc to 30.
local maxQ to 0.10.

local launchObj to lex(
    "accPid", setup_acc_pid(maxAcc)
    ,"azObj", l_az_calc_init(tApo, tInc)
    ,"gtStart", 750
    ,"maxAcc", maxAcc
    ,"maxQ", maxQ
    ,"qPid", setup_q_pid(maxQ)
    ,"runmode", runmode
    ,"rVal", rVal
    ,"tApo", tApo
    ,"tGTurnAlt", tGTurnAlt
    ,"tGEndPitch", tGEndPitch
    ,"tInc", tInc
    ,"tPe",tPe
).

main().

//Main
local function main {
    
    clearScreen.
    print "MSG: Executing launch sequence()             " at (2, 7).
    launch_sequence(launchObj).

    print "MSG: Executing circularization_burn()        " at (2, 7).
    do_circ_burn(launchObj).

    print "MSG: Executing prep_for_orbit()              " at (2, 7).
    set runmode to prep_for_orbit().
    
    print "MSG: Executing cleanup()                     " at (2, 7).
    set runmode to cleanup().

    print "MSG: Executing end_main()                    " at (2, 7).
    set runmode to end_main().

    clearScreen.
}


local function prep_for_orbit {
    logStr("Preparing for orbit").

    logStr("Opening bay doors").
    bays on.

    wait 2.
    
    logStr("Deploying solar panels").
    panels on.

    logStr("Activating all omni antennae").
    for a in ship:partsTaggedPattern("comm.omni") {
        activate_omni(a).
    }
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

    disp_clear_block_all().
    logStr("Ship ready for mission script").
    
    set runmode to 99.
    set stateObj["runmode"] to runmode.
    log_state(stateObj).
    
    return runmode.
}