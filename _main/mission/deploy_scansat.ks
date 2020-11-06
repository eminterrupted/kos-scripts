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
local scanSatList is ship:partsTaggedPattern("sci.scan").

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
        clear_disp_block("e").
        clear_disp_block("f").
        set runmode to 40.
    }

    else if runmode = 40 {
        if time:seconds >= tStamp set runmode to 50.
    }

    else if runmode = 50 {
        for sat in scanSatList {
            start_scansat(sat).
        }
        
        set runmode to 60.
    }

    else if runmode = 60 {
        local dispIdx is 5.
        for sat in scanSatList {
            if defined scanData unset scanData.
            local scanData is get_scansat_data(sat).
            local pos is choose "posE" if dispIdx = 5 else "posF".
            disp_scan_status(scanData, pos).
            set dispIdx to dispIdx + 1.
        }
    }

    if runmode < 99 {
        lock steering to sVal.
    }

    else {
        lock steering to ship:prograde.
    }

    set maxAlt to max(maxAlt, ship:altitude).
    
    disp_launch_main().
    disp_orbital_data().

    if stateObj["runmode"] <> runmode {
        set stateObj["runmode"] to runmode.
        log_state().
    }
}

//** End Main
//
