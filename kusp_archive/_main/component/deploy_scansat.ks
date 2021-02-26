@lazyGlobal off. 

clearScreen.
runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/lib_display").
runOncePath("0:/lib/lib_core").
runOncePath("0:/lib/lib_launch").
runOncePath("0:/lib/lib_sci").
runOncePath("0:/lib/lib_warp").
runOncePath("0:/lib/lib_engine").



runOncePath("0:/lib/lib_mass_data").
runOncePath("0:/lib/lib_misc_parts").
runOncePath("0:/lib/lib_scansat").


//
//** Main

//Vars
local scanSatList to ship:partsTaggedPattern("sci.scan").

//This is not a long-running script or one that needs runmode persistence, so hardcode it here
local runmode to 100. 

lock steering to lookDirUp(ship:prograde:vector, sun:position).

until runmode = 199 {

    if runmode = 100 {
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