@lazyGlobal off. 

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
local scanSatList to ship:partsTaggedPattern("sci.scan").

//Picks up the runmode in the state object. This should be 0 if first run, but this allows resume mid-flight.
//local stateObj to init_state_obj().
local runmode to stateObj["runmode"].
if runmode = 99 or runmode = 0 set runmode to 100. 

wait 1.

until runmode = 199 {
    
    local tStamp to 0.

    if runmode = 100 {
        disp_obt_data().
        
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
        else disp_timer(tStamp).
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
        set runmode to 160.
    }

    else if runmode = 160 {
        local ec to ship:resources[0].
        if ec:amount >= ec:capacity * 0.15 {
            for s in scanSatList {
                start_scansat(s).
            }
            set runmode to 170.
        }

        update_scan_disp().
    }

    else if runmode = 170 {
        local ec to ship:resources[0].
        if ec:amount < ec:capacity * 0.15 {
            for s in scanSatList {
                stop_scansat(s).
            }
            clear_scan_disp().
            set runmode to 160.
        }

        update_scan_disp().
    }

    local sVal to lookDirUp(ship:prograde:vector, sun:position).
    lock steering to sVal.
    
    update_display().

    if stateObj["runmode"] <> runmode {
        set stateObj["runmode"] to runmode.
        log_state(stateObj).
    }
}

//** End Main
//

local function update_scan_disp {
    local scanData to "".
    local nScan to 0.
    for sat in scanSatList {
        set scanData to get_scansat_data(sat).
        disp_scan_status(scanData, nScan).
        set nScan to nScan + 1.
    }
}

local function clear_scan_disp {
    local nScan to 0.
    for sat in scanSatList {
        disp_clear_block("scan_" + nScan).
        set nScan to nScan + 1.
    }
}