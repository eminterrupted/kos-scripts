@LazyGlobal off.
ClearScreen.

parameter _params is list().

// Dependencies
RunOncePath("0:/lib/depLoader").

// Declare Variables
local stAp to Ship:Apoapsis.
local stPe to Ship:Periapsis.

local tgtAp to 0.
local tgtPe to 0.
local tgtUT to 0.

// Parse Params
if _params:length > 0 
{
  set tgtAp to ParseStringScalar(_params[0], tgtAp).
  if _params:length > 1 set tgtUT to ParseStringScalar(_params[1], tgtUT).
}

if tgtAp = 0
{
    if tgtUT > 0
    {
        
    }
}
else
{

}

if tgtUT = 0
{

}

// TgtPe
if career:CanMakeNodes
{
    set stPe to Body:AltitudeOf(PositionAt(Ship, tgtUT)).
    set stAp to Body:AltitudeOf(PositionAt(Ship, tgtUT + Ship:Period / 2)).
}


local dvNeeded to CalcDvBE(stPe, stAp, Ship:Apoapsis, Ship:Apoapsis, "pe").

local circNode to node(Time:Seconds + ETA:Apoapsis, 0, 0, dvNeeded[1]).