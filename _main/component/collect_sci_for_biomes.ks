@lazyGlobal off. 

parameter rVal is 180.

clearScreen.
runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/lib_core").
runOncePath("0:/lib/lib_display").
runOncePath("0:/lib/lib_dmag_sci").
runOncePath("0:/lib/lib_launch").
runOncePath("0:/lib/lib_sci").
runOncePath("0:/lib/lib_warp").
runOncePath("0:/lib/data/engine/lib_engine").
runOncePath("0:/lib/data/engine/lib_isp").
runOncePath("0:/lib/data/engine/lib_thrust").
runOncePath("0:/lib/data/engine/lib_twr").
runOncePath("0:/lib/data/ship/lib_mass").
runOncePath("0:/lib/part/lib_heatshield").

//
//** Main

//Vars
//local stateObj to init_state_obj().
local runmode to stateObj["runmode"].

local biome is "".
local sVal to ship:prograde + r(0, 0, rVal).
local tStamp is 0.
local tVal to 0.

set runmode to 0. 
lock steering to sVal.
lock throttle to tVal.

clearscreen.

until runmode = 99 {

    local sciMod is get_sci_mod_for_parts(ship:parts).
    
    if runmode = 0 {
        set sVal to ship:prograde + r(0, 0, rval). 
        bays on.
        set runmode to 1.
    }

    else if runmode = 1 {
        set sVal to ship:prograde + r(0, 0, rval). 
        wait 2.
        panels on.
        set tStamp to time:seconds + 21600.
        set runmode to 2.
    }

    else if runmode = 2 {
        set sVal to ship:prograde + r(0, 0, rval). 
        set biome to addons:scansat:currentBiome.
        wait 1.

        set runmode to 3.
    }

    else if runmode = 3 {
        set sVal to ship:prograde + r(0, 0, rval). 
        set biome to addons:scansat:currentBiome.
        log_sci_list(sciMod).
        
        set runmode to 4.
    }

    else if runmode = 4 {
        set sVal to ship:prograde + r(0, 0, rval). 
        recover_sci_list(sciMod).
        
        set runmode to 12.
    }

    if runmode = 12 {
        set sVal to ship:prograde + r(0, 0, rVal).
        if biome <> addons:scansat:currentbiome {
            kuniverse:timewarp:cancelwarp().
            set runmode to 3.
        }
        
        if time:seconds > tStamp {
            kuniverse:timewarp:cancelwarp().
            if kuniverse:timewarp:issettled set runmode to 99.
        } else {
            if warp = 0 {
                if steeringManager:angleerror < 0.1 and steeringManager:angleerror > -0.1 {
                    set warp to 1.
                }
            }
            disp_timer(tStamp).
        }
    }
    
    update_display().

    if stateObj["runmode"] <> runmode {
        set stateObj["runmode"] to runmode.
        log_state(stateObj).
    }
}

clearScreen.

//** End Main
//
