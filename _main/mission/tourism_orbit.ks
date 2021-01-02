@lazyGlobal off. 

parameter rVal is 0.

clearScreen.
runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/display/lib_display").
runOncePath("0:/lib/lib_core").
runOncePath("0:/lib/lib_warp").


//
//** Main

//Vars
local tStamp to time:seconds + (3600 * 4).
lock steering to lookDirUp(ship:facing:forevector, sun:position) + r(0, 0, rVal).

//local stateObj to init_state_obj().
local runmode to stateObj["runmode"].
if runmode = 99 set runmode to 0. 

clearscreen.

until runmode = 99 {

    if runmode = 0 {
        set runmode to set_rm(2).
    }

    else if runmode = 2 {
        until time:seconds >= tStamp {
            update_display().
            disp_timer(tStamp).
        }
        
        set runmode to set_rm(4).
    }

    else if runmode = 4 {
        if warp > 0 set warp to 0.
        wait until kuniverse:timewarp:issettled.

        set runmode to set_rm(99).
    }    

    update_display().
}

clearScreen.

//** End Main
//
