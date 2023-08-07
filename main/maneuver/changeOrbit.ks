@LazyGlobal off.
ClearScreen.

parameter _params is list().

RunOncePath("0:/lib/libLoader").

DispMain(ScriptPath()).

local burnTgt to Ship:Apoapsis.
local burnAt  to "AP".

if _params:Length > 0
{
    set burnTgt to ParseStringScalar(_params[0]).
    if _params:Length > 1 set burnAt to _params[1].
}

local tgtPe    to burnTgt.
local tgtAp    to Ship:Apoapsis. 
local tgtXfr   to Ship:Apoapsis.
local compMode to "PE".
local XfrTS    to Time:Seconds + ETA:Apoapsis.

if burnAt = "PE"
{
    local tgtPe    to Ship:Periapsis.
    local tgtAp    to burnTgt. 
    local tgtXfr   to Ship:Periapsis.
    local compMode to "AP".
    local XfrTS    to Time:Seconds + ETA:Periapsis.
}

local burnDV   to CalcDvBE(Ship:Periapsis, Ship:Apoapsis, tgtPe, tgtAp, tgtXfr, Ship:Body, compMode).
local burnNode to Node(XfrTS, 0, 0, burnDV[1]).

until not HasNode
{
    remove nextNode.
}

add burnNode.

OutMsg("Burn node added (DV: {0})":Format(Round(burnDV[1], 2))).
wait 1.

ExecNodeBurn(burnNode).

OutMsg("Maneuver complete").
