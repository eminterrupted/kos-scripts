@LazyGlobal off.
ClearScreen.

parameter _params is list().

RunOncePath("0:/lib/libLoader").

set g_MainProcess to ScriptPath().
DispMain().

local burnAt  to "ap".
local compVal to "pe".
local stageLimit to 0.
local tgtAp   to Ship:Apoapsis.
local tgtEcc  to 0.0025.
local tgtPe   to tgtAp.

ParseCoreTag(Core:Tag).

// if _params:Length > 0
// {
//     set tgtAp to _params[0].
//     if _params:Length > 1 set tgtPe to _params[1].
//     // if _params:Length > 2 set stageLimit to _params[2].
// }


local tgtApTag to Round(tgtAp / 1000):ToString + "Km".

if _params:Length > 0
{
    set tgtAp to _params[0].
    if _params:Length > 1
    {
        local p1 to ParseStringScalar(_params[1]).
        if p1 < 1
        {
            set tgtEcc to p1.
            if tgtEcc < 0
            {
                set tgtPe to GetPeFromApEcc(tgtAp, abs(tgtEcc), Ship:Body).
            }
            else
            {
                set tgtPe to Ship:Apoapsis.
                set tgtAp to GetApFromPeEcc(Ship:Apoapsis, tgtEcc, Ship:Body).
                set compVal to "ap".
            }
        }
        else if p1 > Ship:Body:ATM:Height
        {
            if p1 > Ship:Apoapsis * 1.125 and Ship:Periapsis > Body:ATM:Height
            {
                set tgtAp to p1.
                set compVal to "ap".
                set burnAt to "pe".
            }
            else
            {
                set tgtPe to p1.
            }
            set tgtEcc to GetEccFromApPe(tgtAp, tgtPe, Ship:Body).
        }

        if _params:Length > 2 
        {
            set g_AzData to _params[2].
        }
    }
    else
    {
        if _params[0] > Ship:Apoapsis * 1.125 and Ship:Periapsis > Body:ATM:Height
        {
            set tgtAp to _params[0].
            set compVal to "ap".
            set burnAt to "pe".
        }
        else
        {
            set tgtPe to _params[0].
        }
        set tgtPe to tgtAp.
    }
}

set g_ShipEngines_Spec to GetShipEnginesSpecs(Ship).
local dvNeeded to CalcDvBE(Ship:Periapsis, Ship:Apoapsis, tgtAp, tgtPe, Ship:Apoapsis, compVal).
OutMsg("Calculated DV Needed: {0}":Format(Round(dvNeeded[1], 2))).

local nodeTS to Time:Seconds + ETA:Apoapsis.
if burnAt = "Ap"
{
    if ETA:Apoapsis > ETA:Periapsis and Ship:Periapsis < Ship:Body:ATM:Height
    {
        set nodeTS to Time:Seconds + 5.
    }
}
else
{
     set nodeTS to Time:Seconds + ETA:Periapsis.
}
local circNode to Node(nodeTS, 0, 0, dvNeeded[1]).

if hasNode
{
    until not hasNode
    {
        remove nextNode. 
        wait 0.01.
    }
}
add circNode.

local execFlag to True.

if circNode:DeltaV:Mag < 1 and circNode:ETA > 10 and Ship:Periapsis > Body:Atm:Height
{
    set g_TS to Time:Seconds + 5.
    OutInfo("DV Below skip threshold!").
    until Time:Seconds > g_TS or not execFlag
    {
        OutInfo("[{0}] Press Backspace to skip maneuver":Format(Round(g_TS - Time:Seconds)), 1).
        if CheckTermChar(Terminal:Input:Backspace, True)
        {
            OutInfo("Skipping manuever").
            OutInfo("", 2).
            set execFlag to False.
        }
    }
}

OutInfo().

if execFlag 
{
    ExecNodeBurn_Next(circNode, stageLimit).
    OutMsg("Maneuver complete").
}
else
{
    remove circNode.
    OutMsg("Manuever skipped by user").
}

wait 1.