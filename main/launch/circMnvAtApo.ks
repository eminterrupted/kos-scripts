@LazyGlobal off.
ClearScreen.

parameter _params is list().

RunOncePath("0:/lib/libLoader").

set g_MainProcess to ScriptPath().
DispMain().

ParseCoreTag(Core:Tag).

local tgtAp   to Ship:Apoapsis.
local tgtPe   to tgtAp.
local tgtEcc  to 0.0025.
local compVal to "pe".

if _params:Length > 0
{
    set tgtAp to _params[0].
    if _params:Length > 1
    {
        local p1 to ParseStringScalar(_params[2]).
        if _params[2] < 1
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
            if p1 > Ship:Apoapsis
            {
                set tgtAp to p1.
                set compVal to "ap".
            }
            else
            {
                set tgtPe to p1.
                set compVal to "pe".
            }
            set tgtEcc to GetEccFromApPe(tgtAp, tgtPe, Ship:Body).
        }
    }
    else
    {
        set tgtPe to tgtAp.
    }
}

local dvNeeded to CalcDvBE(Ship:Periapsis, Ship:Apoapsis, tgtAp, tgtPe, Ship:Apoapsis, compVal).
OutMsg("Calculated DV Needed: {0}":Format(Round(dvNeeded[1], 2))).

local circNode to Node(Time:Seconds + ETA:Apoapsis, 0, 0, dvNeeded[1]).
wait 1.

until not hasNode
{
    remove nextNode. 
}
add circNode.

local execFlag to True.

if circNode:DeltaV:Mag < 25 and circNode:ETA > 10 and Ship:Periapsis > Body:Atm:Height
{
    set g_TS to Time:Seconds + 5.
    OutInfo("DV Below skip threshold!").
    until Time:Seconds > g_TS or not execFlag
    {
        OutInfo("[{0}] Press Backspace to skip maneuver":Format(Round(g_TS - Time:Seconds)), 2).

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
    ExecNodeBurn(circNode).
    OutMsg("Maneuver complete").
}
else
{
    remove circNode.
    OutMsg("Manuever skipped by user").
}

wait 1.