@LazyGlobal off.
ClearScreen.

parameter _params is list().

// Dependencies
RunOncePath("0:/lib/libLoader").

DispMain(ScriptPath(), False).

// Declare Variables
local angCheck to 90.
local positionRefTgt to Ship.
local positionRefVessel to Ship:Name:Replace(" Probe","").
local trackRefVessel to False.
local tgtPe to -(Body:Radius / 2).

local steerLex to Lexicon(
    "Body:Pro", list("Aligning to Body:Pro to reposition from spacecraft", 5, "Reposition thrust", 15),
    "Retro:Up", list("Aligning to Retro:Up for deorbit burn", 5, "Ullage thrust", 7.5)
).

// Parse Params
if _params:length > 0 
{
  set tgtPe to ParseStringScalar(_params[0], tgtPe).
  if _params:Length > 1 set positionRefVessel to _params[1].
  if _params:Length > 2 { if _params[2]:IsType("Lexicon") set steerLex to _params[2].}
}
if positionRefVessel:IsType("String")
{
    local allTargets to { local tgtList to list(). list Targets in tgtList. return tgtList.}.
    for t in allTargets:Call()
    {
        if t:Name = positionRefVessel
        {
            set positionRefTgt to Vessel(positionRefVessel).
            set trackRefVessel to True.
        }
    }
}
else if positionRefVessel:IsType("Vessel")
{
    set positionRefTgt to positionRefVessel.
    set trackRefVessel to True.
}

rcs on.
set s_Val to Ship:Facing.
lock steering to s_Val.

set g_TS to Time:Seconds + 5.
until Time:Seconds > g_TS
{
    OutMsg("Beginning deorbit sequence in T{0} ":Format(Round(Time:Seconds - g_TS, 2))).
}

OutMsg("Deorbit sequence started...").
for steerDir in steerLex:Keys
{
    wait 1.
    set g_SteeringDelegate to GetOrbitalSteeringDelegate(steerDir).
    local steerData to steerLex[steerDir].
    OutInfo(steerData[0]).

    set angCheck to 90.
    local settleDur to steerData[1].
    local settleFlag to False.
    local settleTime to settleDur.

    until settleTime < 0
    {

        if settleFlag
        {
            if angCheck > 1 {
                set settleFlag to False.
                set settleTime to settleDur.
            } 
            else
            {
                set settleTime to g_TS - Time:Seconds.
            }
        }
        else
        {
            if angCheck < 1
            {
                set settleFlag to True.
                set g_TS to Time:Seconds + settleDur.
            }              
            set s_Val to g_SteeringDelegate:Call().
        }
        local settleMarker to choose "S" if settleFlag else " ".
        set angCheck to VAng(Ship:Facing:Vector, Steering:Vector).
        if trackRefVessel
        {
            OutInfo("Alignment angle error: {0}{1} | Distance from Ship: {2} ":Format(Round(angCheck, 3), settleMarker, Round(positionRefTgt:Distance, 2)), 1).
        }
        else
        {
            OutInfo("Alignment angle error: {0}{1} | Distance from Ship: N/A ":Format(Round(angCheck, 3), settleMarker), 1).
        }
    }

    set Ship:Control:Fore to 1.
    OutInfo(steerData[2]).
    set g_TS to Time:Seconds + steerData[3].
    local timer to g_TS - Time:Seconds.
    until timer < 0
    {
        set timer to g_TS - Time:Seconds.
        if trackRefVessel
        {
            OutInfo("Thrust time remaining: {0} | Distance from Ship: {1} ":Format(Round(timer, 2), Round(positionRefTgt:Distance, 2)), 1).
        }
        else
        {
            OutInfo("Thrust time remaining: {0} | Distance from Ship: N/A ":Format(Round(timer, 2)), 1).
        }
    }
    set Ship:Control:Fore to 0.
    OutInfo("{0} (Complete)":Format(steerData[2])).
    OutInfo(" ", 1).
}

OutInfo("Deorbit burn: Ignition").
lock throttle to 1.
set ship:control:fore to 0.
until Periapsis < tgtPe {
  OutInfo("Current / (Target) PE: {0} / ({1})) ":Format(Round(Periapsis), tgtPe), 1). 
}
OutInfo().
OutInfo("", 1).
lock throttle to 0.
unlock throttle.
unlock steering.
OutMsg("Deorbit burn complete").
wait 1.