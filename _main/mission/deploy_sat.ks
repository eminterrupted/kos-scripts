@lazyGlobal off. 

parameter rVal is 0.

clearScreen.
runOncePath("0:/lib/lib_init.ks").
runOncePath("0:/lib/lib_display.ks").
runOncePath("0:/lib/lib_core.ks").
runOncePath("0:/lib/lib_launch.ks").
runOncePath("0:/lib/lib_sci.ks").
runOncePath("0:/lib/lib_warp.ks").
runOncePath("0:/lib/data/engine/lib_engine.ks").
runOncePath("0:/lib/data/engine/lib_isp.ks").
runOncePath("0:/lib/data/engine/lib_thrust.ks").
runOncePath("0:/lib/data/engine/lib_twr.ks").
runOncePath("0:/lib/data/ship/lib_mass.ks").


//
//** Main
local stateObj to init_state_obj().
local runmode to stateObj["runmode"].

//Vars
global sVal is ship:prograde + r(0, 0, rval).
global tVal is 0.
lock steering to sVal.

if runmode = 99 set runmode to 0. 

clearscreen.

until runmode = 99 {
    
    if runmode = 0 {
        disp_clear_block("eng_perf").
        set sVal to ship:prograde. 
        local sunExp is get_solar_exp().
        global tStamp is choose time:seconds + 600 if sunExp <= 0.01 else time:seconds + 30.
        set runmode to 10.
    }

    else if runmode = 10 {
        set sVal to ship:prograde. 
        if warp = 0 {
            set runmode to 20. 
            warpTo(tStamp).
        }
    }

    else if runmode = 20 {
        set sVal to ship:prograde. 
        if time:seconds >= tStamp set runmode to 30.
        else disp_timer(tStamp).
    }

    else if runmode = 30 {
        set sVal to ship:prograde. 
        unset tStamp.
        deploy_payload().

        set runmode to 99.
    }


    if runmode < 99 {
        lock steering to sVal.
        lock throttle to tVal.
    }

    else {
        lock steering to ship:prograde.
        lock throttle to 0.
    }
    
    disp_launch_main().
    disp_tel().
    disp_obt_data().

    if stateObj["runmode"] <> runmode {
        set stateObj["runmode"] to runmode.
        log_state(stateObj).
    }
}

//** End Main
//
