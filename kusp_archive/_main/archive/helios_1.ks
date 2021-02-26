@lazyGlobal off. 

parameter rVal is 0.

clearScreen.
runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/lib_core").
runOncePath("0:/lib/lib_display").
runOncePath("0:/lib/lib_sci").
runOncePath("0:/lib/lib_warp").
runOncePath("0:/lib/lib_engine").



runOncePath("0:/lib/lib_mass_data").

//
//** Main

//Vars
//local stateObj to init_state_obj().
local runmode to stateObj["runmode"].

lock steering to lookDirUp(ship:prograde:vector, sun:position) + r(0, 0, rVal).

local tVal to 0.
lock throttle to tVal.

local sciList is get_sci_mod_for_parts(ship:parts).

clearscreen.

until runmode = 99 {

    if runmode = 0 {
        wait 1.

        // local tStamp is time:seconds + (ship:orbit:period / 2).
        
        // if warp = 0 kuniverse:timewarp:warpto(tStamp - 15).
        
        // until time:seconds >= tStamp {
        //     update_display().
        // }

        // if warp > 0 kuniverse:timewarp:cancelwarp().

        // wait 5.

        set runmode to 5.
    }

    else if runmode = 5 {
        set tVal to 1.

        until ship:obt:hasNextPatch {
            update_display().
        }
        
        set tVal to 0.

        set runmode to 10.
    }
        
    else if runmode = 10 {
        lock steering to ship:retrograde.
        local dish is ship:partsTaggedPattern("dish")[0].
        activate_antenna(dish).
        set_dish_target(dish, "Kerbin").
        set runmode to 15.
    }

    else if runmode = 15 {
        set runmode to 20.
    }

    else if runmode = 20 {

        when ship:body:name = "sun" then {
            log_sci_list(sciList).
            recover_sci_list(sciList).
        }

        warp_to_next_soi().

        set runmode to 25.
    }

    else if runmode = 25 {

        wait 90.

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
