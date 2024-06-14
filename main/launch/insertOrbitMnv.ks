@LazyGlobal off.
ClearScreen.

parameter _params is list().

// Dependencies
RunOncePath("0:/lib/libLoader").
RunOncePath("0:/lib/launch").
RunOncePath("0:/lib/mnv").
RunOncePath("0:/kslib/lib_l_az_calc").

set g_MainProcess to ScriptPath().
DispMain().

// Declare Variables
local dvNeeded to list(0, 0, 0).
local stageLimit to 0.
local tgtAp to Ship:Apoapsis.
local tgtPe to Ship:Apoapsis.

// Parse Params
if _params:length > 0 
{
    set tgtPe to ParseStringScalar(_params[0], tgtPe).
    if _params:Length > 1 set stageLimit to _params[1].
}
if tgtPe > Ship:Apoapsis
{
    set tgtAp to tgtPe.
    set tgtPe to Ship:Apoapsis.
    set dvNeeded to CalcDvBE(Ship:Periapsis, Ship:Apoapsis, tgtPe, tgtAp, tgtPe, "ap").
}
else
{
    set dvNeeded to CalcDvBE(Ship:Periapsis, Ship:Apoapsis, tgtPe, Ship:Apoapsis, Ship:Apoapsis, "pe").
}
set s_Val to Ship:Facing.
lock steering to s_Val.
set t_Val to 0.

// Remove any existing node se we can recalculate
if HasNode 
{
    until not HasNode
    {
        remove NextNode.
        wait 0.05.
    }
}

local circNode to choose node(Time:Seconds + 10, 0, 0, dvNeeded[1]) if ETA:Apoapsis > ETA:Periapsis else node(Time:Seconds + ETA:Apoapsis, 0, 0, dvNeeded[1]).
add circNode.

set g_StageLimit to stageLimit.

set g_ShipEngines_Spec to GetShipEnginesSpecs(Ship).
set g_NextEngines to GetNextEngines().

ExecNodeBurn_Next(circNode, stageLimit).

ClearScreen.
print "Hopefully you are in orbit.".
print "If so, thank you for flying with Aurora, and enjoy space.".
print " ".
print "If not, well, hold on to your butts because this is gonna".
print "get real, real quick.".