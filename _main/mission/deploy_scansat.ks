@lazyGlobal off. 

set config:ipu to 300.

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
runOncePath("0:/lib/lib_misc_parts.ks").
runOncePath("0:/lib/part/lib_scansat.ks").


//
//** Main

//Vars
local dispState to lex().
local maxAlt to 0.
local scanSatList to ship:partsTaggedPattern("sci.scan").

local sVal to ship:prograde.
lock steering to sVal.

//Picks up the runmode in the state object. This should be 0 if first run, but this allows resume mid-flight.
local stateObj to init_state_obj().
local runmode to stateObj["runmode"].
if runmode = 99 or runmode = 0 set runmode to 100. 

wait 1.

until runmode = 199 {
    
    local tStamp to 0.

    if runmode = 100 {
        clearscreen.
        set sVal to ship:prograde. 
        disp_obt_data().

        local sunExp to get_solar_exp().
        if sunExp <= 0.01 set tStamp to time:seconds + 600.
        
        set runmode to 110.
    }

    else if runmode = 110 {
        if warp = 0 {
            set runmode to 120. 
            warpTo(tStamp).
        }
    }

    else if runmode = 120 {
        if time:seconds >= tStamp set runmode to 130.
        else disp_deploy(tStamp).
    }

    else if runmode = 130 {
        set tStamp to time:seconds + 130.
        deploy_payload().
        disp_clear_block("deploy").
        set runmode to 140.
    }

    else if runmode = 140 {
        if time:seconds >= tStamp set runmode to 150.
        disp_eta(tStamp).
    }

    else if runmode = 150 {
        set sVal to ship:prograde + r(-90,0,0).
        for sat in scanSatList {
            start_scansat(sat).
        }
        
        set runmode to 160.
    }

    else if runmode = 160 {
        local scanData to "".
        set sVal to ship:prograde + r(90,0,0).
        for sat in scanSatList {
            set scanData to get_scansat_data(sat).
            if dispState:haskey("scan_status") {
                disp_scan_status(scanData).
            } else {
                set dispState["scan_status"] to disp_scan_status(scanData).
            }
        }
    }

    if runmode < 199 {
        lock steering to sVal.
    }

    else {
        lock steering to ship:prograde.
    }

    set maxAlt to max(maxAlt, ship:altitude).
    
    disp_launch_main().
    disp_obt_data().

    if stateObj["runmode"] <> runmode {
        set stateObj["runmode"] to runmode.
        log_state(stateObj).
    }
}

//** End Main
//
