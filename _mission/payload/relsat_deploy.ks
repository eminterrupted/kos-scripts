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
runOncePath("0:/lib/data/vessel/lib_mass.ks").


//
//** Main

//Vars
global sVal is ship:prograde.
global tVal is 0.
local maxAlt is 0.

setup_tpid(.15).
lock steering to sVal.
//Picks up the runmode in the state object. This should be 0 if launching from scratch, but this allows resume mid-flight.
set runmode to stateObj["runmode"].
if runmode = 99 set runmode to 0. 

wait 1.

until runmode = 99 {
    
    set sVal to ship:prograde. 

    if runmode = 0 {
        global tStamp is time:seconds + 600.    
        clear_sec_data_fields().
        set runmode to 10.
    }

    else if runmode = 10 {
        if warp = 0 {
            warpTo(tStamp - 10).
            set runmode to 20.
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

    set maxAlt to max(maxAlt, ship:altitude).
    
    disp_main().
    disp_launch_telemetry(maxAlt).
    disp_orbital_data().
    disp_engine_perf_data().

    if stateObj["runmode"] <> runmode {
        set stateObj["runmode"] to runmode.
        log_state().
    }
}

//** End Main
//
