@lazyGlobal off. 

set config:ipu to 150.

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
global sVal is ship:prograde.
global tVal is 0.

setup_pid(.15).
lock steering to sVal.

if runmode = 99 set runmode to 0. 

clearscreen.

until runmode = 99 {
    
    set sVal to ship:prograde. 

    if runmode = 0 {
        local sunExp is get_solar_exp().
        global tStamp is choose time:seconds + 600 if sunExp <= 0.01 else time:seconds + 30.
        set runmode to 10.
    }

    else if runmode = 10 {
        if warp = 0 {
            set runmode to 20. 
            warpTo(tStamp).
        }
    }

    else if runmode = 20 {
        if time:seconds >= tStamp set runmode to 30.
        else disp_deploy(tStamp).
    }

    else if runmode = 30 {
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
    disp_launch_tel().
    disp_obt_data().
    disp_eng_perf_data().

    if stateObj["runmode"] <> runmode {
        set stateObj["runmode"] to runmode.
        log_state(stateObj).
    }
}

//** End Main
//
