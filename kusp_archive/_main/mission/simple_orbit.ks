@lazyGlobal off. 

parameter waitTime is 21600, 
          rVal is 0.

clearScreen.
runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/lib_display").
runOncePath("0:/lib/lib_core").

//Vars
//local stateObj to init_state_obj().
local runmode to stateObj["runmode"].
if runmode = 99 set runmode to 0. 

local tStamp to time:seconds + waitTime.

lock steering to lookDirUp(ship:prograde:vector, sun:position) + r(0, 0, rVal).

clearscreen.

print "*** Press any key to continue ***" at (2, 25).

until time:seconds >= tStamp or terminal:input:haschar {

    if runmode = 0 set runmode to 90.

    update_display().
    disp_timer(tStamp, "Simple Orbit").

    wait 1.
}

print "                                  " at (2, 25).

if terminal:input:haschar {
    terminal:input:clear.
}

clearScreen.

//** End Main
//
