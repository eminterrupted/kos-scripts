@LazyGlobal off.
ClearScreen.

parameter _params is list().

// Dependencies
RunOncePath("0:/lib/depLoader").
RunOncePath("0:/lib/launch").
RunOncePath("0:/lib/mnv").
RunOncePath("0:/kslib/lib_l_az_calc").


// Declare Variables
local tgtPe to Ship:Apoapsis.
local tgtHdg to compass_for(ship, Ship:Prograde).
local totBurnTime to 0.
local waitTime to 0.

// Parse Params
if _params:length > 0 
{
    // set tgtHdg to ParseStringScalar(params[0], tgtHdg).
    // if params:Length > 1 set waitTime to ParseStringScalar(params[1], waitTime).
    set tgtPe to ParseStringScalar(_params[0], tgtPe).
}

local steerDel to {  if g_Spin_Active { return heading(tgtHdg, 0, 0):Vector.} else { return heading(tgtHdg, 0, 0).}}.

if g_AzData:Length > 0
{
    set steerDel to {  if g_Spin_Active { return heading(l_az_calc(g_AzData), 0, 0). } else { return heading(l_az_calc(g_AzData), 0, 0).}}.
}
set g_Steer to Ship:Facing.
lock steering to g_Steer.
set g_Throt to 0.

// Remove any existing node se we can recalculate
if HasNode 
{
    until not HasNode
    {
        remove NextNode.
        wait 0.05.
    }
}
local dvNeeded to CalcDvBE(Ship:Periapsis, Ship:Apoapsis, tgtPe, Ship:Apoapsis, Ship:Apoapsis, "pe").

local circNode to choose node(Time:Seconds + 10, 0, 0, dvNeeded[1]) if ETA:Apoapsis > ETA:Periapsis else node(Time:Seconds + ETA:Apoapsis, 0, 0, dvNeeded[1]).
add circNode.

set g_ShipEngines to GetShipEnginesSpecs(Ship).
set g_NextEngines to GetNextEngines("1000").

ExecNodeBurn(circNode).

ClearScreen.
print "Hopefully you are in orbit.".
print "If so, thank you for flying with Aurora, and enjoy space.".
print " ".
print "If not, well, hold on to your butts because this is gonna".
print "get real, real quick.".