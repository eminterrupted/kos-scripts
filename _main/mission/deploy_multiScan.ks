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
runOncePath("0:/lib/lib_misc_parts.ks").


//
//** Main

//Vars
local maxAlt is 0.

global sVal is ship:prograde.
lock steering to sVal.

//Picks up the runmode in the state object. This should be 0 if launching from scratch, but this allows resume mid-flight.
set runmode to stateObj["runmode"].
if runmode = 99 set runmode to 0. 

wait 1.

until runmode = 99 {
    
    set sVal to ship:prograde. 

    if runmode = 0 {
        clear_sec_data_fields().
        local sunExp is get_solar_exp().
        if sunExp <= 0.01 global tStamp is time:seconds + 600.
        else global tStamp is time:seconds + 30.

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
        set tStamp to time:seconds + 30.
        deploy_payload().

        set runmode to 40.
    }

    else if runmode = 40 {
        if time:seconds >= tStamp set runmode to 50.
    }

    else if runmode = 50 {
        local scanSat is ship:partsTagged("sci.scan.multi")[0].
        start_scansat_multi(scanSat).

        set runmode to 60.
    }

    else if runmode = 60 {
        if defined scanData unset scanData.
        local scanData is get_scansat_data(scanSat).
        disp_scan_status(scanData).
    }

    if runmode < 99 {
        lock steering to sVal.
    }

    else {
        lock steering to ship:prograde.
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
