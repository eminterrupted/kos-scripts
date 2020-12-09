@lazyGlobal off. 

parameter rVal is 0.

clearScreen.
runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/lib_core").
runOncePath("0:/lib/lib_display").
runOncePath("0:/lib/lib_sci").
runOncePath("0:/lib/lib_warp").
runOncePath("0:/lib/data/engine/lib_engine").
runOncePath("0:/lib/data/engine/lib_isp").
runOncePath("0:/lib/data/engine/lib_thrust").
runOncePath("0:/lib/data/engine/lib_twr").
runOncePath("0:/lib/data/ship/lib_mass").

//
//** Main

//Vars
//local stateObj to init_state_obj().
local runmode to stateObj["runmode"].

local sVal to lookDirUp(ship:facing:forevector, sun:position).
lock steering to sVal.

local tVal to 0.
lock throttle to tVal.

set runmode to 0. 

clearscreen.

until runmode = 99 {

    local sciList is get_sci_mod_for_parts(ship:parts).
    
    if runmode = 0 {
        set sVal to lookDirUp(ship:facing:forevector, sun:position).
        set tVal to 1.
        until ship:availablethrust < 0.1 {
            update_display().
        }
        set runmode to 1.
    }

    else if runmode = 1 {
        local dish is ship:partsTaggedPattern("dish")[0].
        activate_dish(dish).
        set_dish_target(dish, "Kerbin").
        set runmode to 2.
    }

    else if runmode = 2 {
        warp_to_next_soi().
        set runmode to 3.
    }

    else if runmode = 3 {
        until ship:body = "sun" {
            update_display().
        }
    }

    else if runmode = 3 {
        set sVal to lookDirUp(ship:facing:forevector, sun:position).
        log_sci_list(sciList).
        recover_sci_list(sciList).
        set runmode to 4.
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
