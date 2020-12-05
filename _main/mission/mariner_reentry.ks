@lazyGlobal off. 

parameter rVal is 180.

clearScreen.
runOncePath("0:/lib/lib_init.ks").
runOncePath("0:/lib/lib_display.ks").
runOncePath("0:/lib/lib_core.ks").
runOncePath("0:/lib/lib_warp.ks").
runOncePath("0:/lib/lib_reentry").
runOncePath("0:/lib/data/engine/lib_engine.ks").
runOncePath("0:/lib/data/engine/lib_isp.ks").
runOncePath("0:/lib/data/engine/lib_thrust.ks").
runOncePath("0:/lib/data/engine/lib_twr.ks").
runOncePath("0:/lib/data/ship/lib_mass.ks").

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

do_reentry(tPe, rVal).

clearscreen.