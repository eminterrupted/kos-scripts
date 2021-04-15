@lazyGlobal off.
clearScreen.

// This script does a hohmann transfer to a given altitude. 
// Accepts a target altitude and a time to start the burn at.

parameter tgtAp,
          tgtPe,       
          mnvTime       is time:seconds + eta:periapsis, // Center point of mnv
          circularize   is true.  // circularize the orbit after raising it

runOncePath("0:/lib/lib_file").
runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_mnv").
runOncePath("0:/lib/lib_vessel").

local burnTime  to list().
local dvNeeded  to list().

// Control locks
local sVal      to lookDirUp(ship:prograde:vector, sun:position).
local tVal      to 0.
lock  steering  to sVal.
lock  throttle  to tVal.

// Setup taging trigger
when ship:maxThrust <= 0.1 and throttle > 0 then 
{
    ves_safe_stage().
    preserve.
}

disp_main(scriptPath():name).
disp_msg("Calculating burn data").

// Get the amount of dv needed to raise from current to desired
set dvNeeded to mnv_dv_hohmann_velocity(ship:periapsis, tgtPe, tgtAp, ship:body).
disp_msg("dv0: " + round(dvNeeded[0], 2) + " | dv1: " + round(dvNeeded[1], 2)).

// Transfer burn
set burnTime to mnv_burn_times(dvNeeded[0], mnvTime).
disp_info("Burn duration: " + round(burnTime[1], 1)).
mnv_exec_circ_burn(dvNeeded[0], mnvTime, burnTime[0]).

if circularize
{
    // Circularization burn
    // Calculate our burnEta for the circ burn
    set mnvTime  to time:seconds + (ship:orbit:period / 2).
    set burnTime to mnv_burn_times(dvNeeded[1], mnvTime).
    disp_info("Burn duration: " + round(burnTime[1] / 2)).
    mnv_exec_circ_burn(dvNeeded[1], mnvTime, burnTime[0]).
}