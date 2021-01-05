@lazyGlobal off. 

parameter waitTime is 21600, 
          rVal is 0.

clearScreen.
runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/display/lib_display").
runOncePath("0:/lib/lib_core").

//Vars
//local stateObj to init_state_obj().
local runmode to stateObj["runmode"].
if runmode = 99 set runmode to 0. 

local tStamp to time:seconds + waitTime.

lock steering to lookDirUp(ship:prograde:vector, sun:position) + r(0, 0, rVal).

clearscreen.

until time:seconds >= tStamp {

    if runmode = 0 set runmode to 90.

    update_display().
    //disp_timer(tStamp, "Simple Orbit").

    wait 1.
}

clearScreen.

//** End Main
//
