@lazyGlobal off. 

parameter rVal is 180.

clearScreen.
runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/display/lib_display").
runOncePath("0:/lib/lib_core").
runOncePath("0:/lib/lib_warp").
runOncePath("0:/lib/lib_reentry").
runOncePath("0:/lib/lib_engine").



runOncePath("0:/lib/lib_mass_data").

//
//** Main

//Vars
//local stateObj to init_state_obj().
local runmode to stateObj["runmode"].

local sVal to lookDirUp(ship:facing:forevector, sun:position) + r(0, 0, rVal).
lock steering to sVal.

local tVal to 0.
lock throttle to tVal.

local tPe to 35000.

if runmode = 99 set runmode to 0. 

out_msg("Trajectory does not enter atmosphere, performing reentry burn").
if ship:periapsis >= 70000 do_kerbin_reentry_burn(tPe, rVal).

sr("").

out_msg("Performing reentry").
do_kerbin_reentry().

clearscreen.