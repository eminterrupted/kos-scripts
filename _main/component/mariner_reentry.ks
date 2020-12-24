@lazyGlobal off. 

parameter rVal is 180.

clearScreen.
runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/lib_display").
runOncePath("0:/lib/lib_core").
runOncePath("0:/lib/lib_warp").
runOncePath("0:/lib/lib_reentry").
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

local sVal to lookDirUp(ship:facing:forevector, sun:position) + r(0, 0, rVal).
lock steering to sVal.

local tVal to 0.
lock throttle to tVal.

local tPe to 35000.

if runmode = 99 set runmode to 0. 

if ship:periapsis >= 70000 do_kerbin_reentry_burn(tPe, rVal).

do_kerbin_reentry().

clearscreen.