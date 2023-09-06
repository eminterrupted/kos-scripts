@LazyGlobal off.
ClearScreen.

parameter _params is list().

RunOncePath("0:/lib/libLoader").

DispMain(ScriptPath()).

local burnTgt   to Ship:Apoapsis.
local burnAt    to "AP".
local tgtAp     to Ship:Apoapsis.
local tgtPe     to Ship:Periapsis.
local trackVal  to "PE".
local xfrTgt    to 0.
local xfrTS     to 0.

if _params:Length > 0
{
    set burnTgt to ParseStringScalar(_params[0]).
    if _params:Length > 1 set burnAt   to _params[1].
    if _params:Length > 2 set trackVal to _params[2].
}

if burnAt = "AP"
{
    if trackVal = "PE"
    {
        if burnTgt < 1    
        {
            set tgtPe to GetPeFromApEcc(Ship:Apoapsis, burnTgt).
        }
        else 
        {
            set tgtPe to burnTgt.
        }
    }
    else
    {
        if burnTgt < 1
        {
            set tgtPe to tgtAp.
            set tgtAp to GetApFromPeEcc(Ship:Periapsis, burnTgt).
        }
        else
        {
            set tgtAp to burnTgt.
        }
    }
    set xfrTgt to Ship:Apoapsis. 
    set XfrTS  to Time:Seconds + ETA:Apoapsis.
}
else
{
    if trackVal = "PE"
    {
        if burnTgt < 1    
        {
            set tgtAp to tgtPe.
            set tgtPe to GetPeFromApEcc(Ship:Apoapsis, burnTgt).
        }
        else
        {
            set tgtPe to burnTgt.
        }
    }
    else
    {
        if burnTgt < 1
        {
            set tgtAp to GetApFromPeEcc(Ship:Periapsis, burnTgt).
        }
        else
        {
            set tgtAp to burnTgt.
        }
    }
    set xfrTgt to Ship:Periapsis.
    set xfrTS  to Time:Seconds + ETA:Periapsis.
}

local burnDV   to CalcDvBE(Ship:Periapsis, Ship:Apoapsis, tgtPe, tgtAp, xfrTgt, trackVal, Ship:Body).
local burnNode to Node(xfrTS, 0, 0, burnDV[1]).

until not HasNode
{
    remove nextNode.
}

add burnNode.

OutMsg("Burn node added (DV: {0})":Format(Round(burnDV[1], 2))).
wait 1.

ExecNodeBurn(burnNode).

OutMsg("Maneuver complete").
