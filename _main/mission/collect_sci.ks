@lazyGlobal off. 

parameter rVal is 0.

clearScreen.
runOncePath("0:/lib/lib_init.ks").
runOncePath("0:/lib/lib_core.ks").
runOncePath("0:/lib/lib_display.ks").
runOncePath("0:/lib/lib_dmag_sci.ks").
runOncePath("0:/lib/lib_launch.ks").
runOncePath("0:/lib/lib_sci.ks").
runOncePath("0:/lib/lib_warp.ks").
runOncePath("0:/lib/data/engine/lib_engine.ks").
runOncePath("0:/lib/data/engine/lib_isp.ks").
runOncePath("0:/lib/data/engine/lib_thrust.ks").
runOncePath("0:/lib/data/engine/lib_twr.ks").
runOncePath("0:/lib/data/ship/lib_mass.ks").
runOncePath("0:/lib/part/lib_heatshield.ks").

//
//** Main

//Vars
local stateObj to init_state_obj().
local runmode to stateObj["runmode"].

local biome is "".
local sVal to ship:prograde.
local tStamp is 0.
local tVal to 0.

set runmode to 0. 
lock steering to sVal.
lock throttle to tVal.

clearscreen.

until runmode = 99 {

    local sciMod is get_sci_mod().
    local dmagMod is get_dmag_mod().
    
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
        deploy_sci_list(sciMod).

        wait 1.

        set runmode to 3.
    }

    else if runmode = 3 {
        set sVal to ship:prograde + r(0, 0, rval). 
        set biome to addons:scansat:currentBiome.

        log_sci_list(sciMod).
        log_dmag_list(dmagMod).
        
        set runmode to 4.
    }

    else if runmode = 4 {
        set sVal to ship:prograde + r(0, 0, rval). 
        
        recover_sci_list(sciMod).
        recover_sci_list(dmagMod).

        reset_sci_list(sciMod).
        reset_sci_list(dmagMod).
        
        set runmode to 12.
    }

    if runmode = 12 {
        set sVal to ship:prograde + r(0, 0, rVal).
        if biome <> addons:scansat:currentbiome set runmode to 3.
        if time:seconds > tStamp {
            kuniverse:timewarp:cancelwarp().
            if kuniverse:timewarp:issettled set runmode to 99.
        } else {
            if warp = 0 {
                if steeringManager:angleerror < 0.1 and steeringManager:angleerror > -0.1 {
                    set warp to 5.
                }
            }
            disp_timer(tStamp).
        }
    }
    
    disp_launch_main().
    disp_tel().
    disp_obt_data().

    if stateObj["runmode"] <> runmode {
        set stateObj["runmode"] to runmode.
        log_state(stateObj).
    }
}

clearScreen.

//** End Main
//
