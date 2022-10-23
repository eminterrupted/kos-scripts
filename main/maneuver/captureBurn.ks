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
local tgtAp to ship:periapsis.

if param:length > 0 
{
    set tgtAp to param[0].
}

local sVal to Ship:Facing.
lock steering to sVal.

// Main
DispMain(scriptPath()).

// Arm staging
ArmAutoStaging(0).

// If there's already a captureBurn node, remove it
if HasNode 
{
    until not HasNode
    {
        remove NextNode.
        wait 0.01.
    }
}

// Calculations
OutMsg("Calculating Burn Parameters").
local dv to CalcDvHyperCapture(ship, ship:periapsis, tgtAp, ship:body).
print "Calculated dV: " + round(dv, 2) at (2, 25).

local burnDur   to CalcBurnDur(dv).

local mnvTime   to time:seconds + eta:periapsis. // Since this is a simple circularization, we are just burning at apoapsis.
local burnEta   to mnvTime - burnDur[3].        // Uses the value of halfDur - totalStaging time over the half duration
set g_MECO        to burnEta + burnDur[1].      // Expected cutoff point with full duration + waiting for staging
local mnvNode to node(mnvTime, 0, 0, dv).
add mnvNode.

ExecNodeBurn(nextNode).
ag9 on.
OutInfo().

OutMsg("Circularization phase complete").
wait 1.