@lazyGlobal off.
clearScreen.

// This script does a hohmann transfer to a given altitude. 
// Accepts a target altitude and a time to start the burn at.

parameter tgtAlt,   // Altitude we wish to raise our orbit to
          burnAt is time:seconds + eta:apoapsis. // Default to burning at Pe

runOncePath("0:/lib/lib_file").
runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_mnv").
runOncePath("0:/lib/lib_vessel").

local burnDur   to 0.
local burnEta   to 0.
local burnFacing to choose "prograde" if tgtAlt > ship:altitude else "retrograde".
local dvNeeded  to list().
local halfDur   to 0.
local stAlt     to 0.

// Control locks
local sVal      to lookDirUp(ship:prograde:vector, body("sun"):position).
local tVal      to 0.
lock  steering  to sVal.
lock  throttle  to tVal.

// Setup taging trigger
ves_staging_trigger().


disp_main().
disp_msg("Calculating burn data").

// Calculate the starting altitude. This is 180 degrees from the 
// burnAt time. If we don't have the flight path prediction capability
// unlocked, use Pe / Ap as predictions
set stAlt to ship:periapsis.

// Get the amount of dv needed to raise from current to desired
set dvNeeded to mnv_dv_hohmann(tgtAlt, stAlt, ship:body).
disp_msg("dv1: " + round(dvNeeded[1], 2)).

// Circularization burn
// Calculate our burnEta for the circ burn
set burnDur to mnv_burn_dur(dvNeeded[1]).
set halfDur to mnv_burn_dur(dvNeeded[1] / 2).
disp_info("Burn duration: " + round(burnDur)).
set burnEta to burnAt - halfDur.
mnv_exec(burnEta, burnDur, burnFacing).