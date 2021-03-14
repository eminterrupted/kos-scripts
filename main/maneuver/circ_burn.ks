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
runOncePath("0:/kslib/lib_navball").

// Control locks

// Variables
local burnDur       to 0.
local burnEta       to 0.
local burnPro       to choose true if tgtAlt >= ship:altitude else false.
local dvNeeded      to list().
local halfDur       to 0.
local stAlt         to 0.

// Setup taging trigger
when ship:maxThrust <= 0.1 and throttle > 0 then 
{
    ves_safe_stage().
    preserve.
}

disp_main(scriptPath():name).
disp_msg("Calculating burn data").

// Calculate the starting altitude.
set stAlt to ship:periapsis.

// Get the amount of dv needed to raise from current to desired
set dvNeeded to mnv_dv_hohmann(tgtAlt, stAlt, ship:body).
disp_msg("dv1: " + round(dvNeeded[1], 2)).

// Calculate our burnEta for the circ burn
set burnDur to mnv_burn_dur(dvNeeded[1]).
set halfDur to mnv_burn_dur(dvNeeded[1] / 2).
disp_info("Burn duration: " + round(burnDur)).
set burnEta to burnAt - halfDur.

// Execute
mnv_exec_circ_burn(burnEta, burnDur, burnPro).
ag9 on.