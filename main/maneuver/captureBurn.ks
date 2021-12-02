@lazyGlobal off.
clearScreen.

// Parameter
parameter param is list().

// Dependencies
runOncePath("0:/lib/burnCalc").
runOncePath("0:/lib/disp").
runOncePath("0:/lib/globals").
runOncePath("0:/lib/mnv").
runOncePath("0:/lib/nav").
runOncePath("0:/lib/util").
runOncePath("0:/lib/vessel").
runOncePath("0:/kslib/lib_navball").

// Variables
local curAp to ship:body:soiradius + ship:body:body:soiradius - (ship:apoapsis + ship:body:radius).
local magicVal to 1.25. 
local tgtAp to ship:periapsis.

local rVal to 0 - ship:facing:roll.
local sVal to ship:facing.
local tVal to 0.

if param:length > 0 
{
    set tgtAp to param[0].
}

// Main
DispMain(scriptPath()).

lock steering to sVal.
lock throttle to tVal.

// Arm staging
ArmAutoStaging(0).

// Calculations
OutMsg("Calculating Burn Parameters").
local dv        to CalcDvBE(ship:periapsis, curAp, ship:periapsis, tgtAp, curAp)[2].
print "Calculated dV: " + round(dv, 2) at (2, 25).
set dv to dv * magicVal.
print "Adjusted dV  : " + round(dv, 2) at (2, 26).

local burnDur   to CalcBurnDur(dv).

local mnvTime   to time:seconds + eta:periapsis. // Since this is a simple circularization, we are just burning at apoapsis.
local burnEta   to mnvTime - burnDur[3].        // Uses the value of halfDur - totalStaging time over the half duration
local fullDur   to burnDur[0].                  // Full duration, no staging time included (for display only)
set g_MECO        to burnEta + burnDur[1].      // Expected cutoff point with full duration + waiting for staging
local mnvNode to node(mnvTime, 0, 0, -dv).
add mnvNode.

ExecNodeBurn(nextNode).
ag9 on.
OutInfo().

OutMsg("Circularization phase complete").
wait 1.