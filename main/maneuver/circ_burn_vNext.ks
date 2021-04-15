@lazyGlobal off.
clearScreen.

// This script circularizes a launch to the desired Pe
// Accepts either a scalar or a lex with a tgtPe key

parameter launchPlan.

runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_mnv").
runOncePath("0:/lib/lib_vessel").
runOncePath("0:/kslib/lib_navball").

// Variables
local burnTime  to list().
local dvNeeded  to list().
local mnvTime   to time:seconds + eta:apoapsis.
local stAlt     to 0.
local tgtAlt    to choose launchPlan if launchPlan:typeName = "scalar" else launchPlan:tgtPe.

// Setup taging trigger
when ship:maxThrust <= 0.1 and throttle > 0 then 
{
    if ship:deltaV:current > 0 
    {
        ves_safe_stage().
        preserve.
    }
}

disp_terminal().
disp_main(scriptPath():name).
disp_msg("Calculating burn data").

// Calculate the starting altitude.
set stAlt to ship:periapsis.

// Get the amount of dv needed to raise from current to desired
set dvNeeded to mnv_dv_hohmann_velocity(stAlt, tgtAlt, tgtAlt, ship:body)[1].
disp_msg("dv1: " + round(dvNeeded, 2)).

// Burn timing
set burnTime to mnv_burn_times(dvNeeded, mnvTime).
disp_info("Burn duration: " + round(burnTime[1])).

// Execute
mnv_exec_circ_burn(dvNeeded, mnvTime, burnTime[0]).
ag9 on.