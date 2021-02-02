@lazyGlobal off. 

parameter tAp to 50000,
          tPe to 50000,
          tInc to 0,
          tGTurnAlt to 12500,
          rVal to 0.

clearScreen.
runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/lib_log").
runOncePath("0:/lib/display/lib_display").
runOncePath("0:/lib/lib_launch").
runOncePath("0:/lib/lib_core").
runOncePath("0:/lib/lib_warp").
runOncePath("0:/lib/lib_pid").
runOncePath("0:/lib/lib_misc_parts").
runOncePath("0:/lib/lib_engine_data").
runOncePath("0:/lib/lib_mass_data").
runOncePath("0:/lib/nav/lib_mnv").
runOncePath("0:/lib/nav/lib_nav").
runOncePath("0:/lib/nav/lib_node").
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
    ,"azObj", l_az_calc_init(tAp, tInc)
    ,"gtStart", 750
    ,"maxAcc", maxAcc
    ,"maxQ", maxQ
    ,"qPid", setup_q_pid(maxQ)
    ,"runmode", runmode
    ,"rVal", rVal
    ,"tAp", tAp
    ,"tGTurnAlt", tGTurnAlt
    ,"tGEndPitch", 0
    ,"tInc", tInc
    ,"tPe",tPe
).

main().

//Main
local function main {
    
    clearScreen.
    out_msg("Executing launch sequence()").
    launch_sequence(launchObj).

    out_msg("Executing circularization_burn()").
    exec_circ_burn("ap", launchObj["tAp"]).

    out_msg("Executing prep_for_orbit()").
    prep_for_orbit().
    
    out_msg("Executing cleanup()").
    cleanup().

    out_msg("Executing end_main()").
    end_main().

    clearScreen.
}


local function prep_for_orbit {
    logStr("Preparing for orbit").

    //TODO - fix this so it doesn't open all bay doors, all the time
    logStr("Opening bay doors").
    bays on.

    wait 2.
    
    // Solar panel deployment
    logStr("Deploying launch vehicle solar panels").
    local sMod to "ModuleDeployableSolarPanel".
    for p in ship:partsTaggedPattern("solar.array") {
        if not p:tag:matchesPattern("onDeploy") and not p:tag:matchesPattern("onTouchdown") and not p:tag:matchespattern("onAscent") {
            do_event(p:getModule(sMod), "extend solar panel").
        }
    }

    // Omni antenna deployment
    logStr("Activating orbital antennae").
    local aMod to "ModuleRTAntenna".

    for p in ship:partsTaggedPattern("comm") {
        if not p:tag:matchesPattern("onDeploy") and not p:tag:matchesPattern("onTouchdown")  and not p:tag:matchespattern("onAscent") {
            do_event(p:getModule(aMod), "activate").
        }

        if p:tag:matchesPattern("dish") {
            if get_dish_target(p) = "No target" {
                set_dish_target(p, "kerbin").
            }
        }
    }

    logStr("Orbtial configuration set").

    update_display().

    set runmode to rm(28).
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
        
    from { local n is 5.} until n <= 0 step { set n to n - 1.} do {
        update_display().
        disp_timer(n + time:seconds).
        wait 1.
    }

    disp_clear_block_all().
    logStr("Ship ready for mission script").
    
    set runmode to 99.
    set stateObj["runmode"] to runmode.
    log_state(stateObj).
    
    return runmode.
}