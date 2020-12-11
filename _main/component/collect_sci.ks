@lazyGlobal off. 

parameter rVal is 0.

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

local sVal to ship:prograde.
lock steering to sVal.

local tVal to 0.
lock throttle to tVal.

local sciMod is get_sci_mod_for_parts(ship:parts).

set runmode to 0. 

clearscreen.

until runmode = 99 {
   
    if runmode = 0 {
        set sVal to ship:prograde + r(0, 0, rval). 
        bays on.
        set runmode to 1.
    }

    else if runmode = 1 {
        set sVal to ship:prograde + r(0, 0, rval). 
        log_sci_list(sciMod).
        recover_sci_list(sciMod, true).
        wait 1.

        set runmode to 99.
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
