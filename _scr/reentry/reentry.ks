@LazyGlobal off.
ClearScreen.

Parameter params is list().

RunOncePath("0:/lib/loadDep").

DispMain(scriptPath()).

OutMsg("Running reentry routine").

local tgtAlt to body:Atm:height + 25000.
local fairingList to Ship:PartsTaggedPattern("fairing.reentry").
local hasReentryFairings to fairingList:Length > 0.
local fairingJettisonAlt to 10000.
local stageOnFairings to true.
local stageToID to 1.

if params:Length > 0
{
    set tgtAlt to body:Atm:height + params[0].
    if params:Length > 1 set hasReentryFairings to params[1].
    if params:Length > 2 set fairingJettisonAlt to params[2].
    if params:Length > 3 set stageOnFairings to params[3].
    if params:Length > 4 set stageToID to params[4].
}

RCS on.
set s_Val to Ship:SrfRetrograde.
lock Steering to s_Val.

set t_Val to 0.
lock Throttle to t_Val.

if hasReentryFairings
{
    for f in fairingList
    {
        if f:Tag:MatchesPattern("fairing\.reentry\.\d*") 
        { 
            set fairingJettisonAlt to f:Tag:Replace("fairing.reentry.",""):ToNumber(fairingJettisonAlt).
            break.
        }
    }
    OutInfo("Fairing Jettison Altitude: {0}":Format(fairingJettisonAlt), 1).
    wait 0.25.
}

// if Ship:PartsTaggedPattern("OnEvent.Reentry"):Length > 0
// {
if Ship:PartsTaggedPattern("OnEvent\(ETA\.REI"):Length > 0
{
    InitOnEventTrigger(Ship:PartsTaggedPattern("OnEvent\(ETA\.REI")).
}
    // for p in Ship:PartsTaggedPattern("OnEvent.Reentry")
    // {
    //     {
    //         OutInfo("OnEvent Trigger Initiated for {0}":Format(p:name)).
    //         wait 0.25.
    //     }
    // }
// }
wait 1.

OutMsg("Waiting until {0}m":Format(tgtAlt)).
OutInfo("Press Home to Warp").
local warpFlag to false.
until ship:Altitude < tgtAlt + 10000
{
    set s_Val to ship:SrfRetrograde.
    
    GetTermChar().
    if g_TermChar <> ""
    {
        if g_TermChar = Terminal:Input:HomeCursor
        {
            //set warpFlag to true.
            OutInfo("WARPING: Press End to cancel").
        }
        else if g_TermChar = Terminal:Input:EndCursor
        {
            //set warp to 0.
            //set warpFlag to false.
            OutInfo("Press Home to Warp").
        }
    }

    if warpFlag 
    { 
        set warpFlag to false. 
        WarpToAlt(tgtAlt + 10000). 
    }
    
    local etaREI to (Ship:Altitude - Body:Atm:Height) / (Abs(Ship:VerticalSpeed) + GetLocalGravity(Body, Ship:Altitude)).
    local dataLex to lexicon(
        "REENTRY", "-"
        ,"TIME TO ATM INTERFACE", round(etaREI, 2)
        , "VERTICALSPEED", Round(Ship:VerticalSpeed, 1)
    ).
    DispTelemetry(dataLex).
    wait 0.01.
}
set warp to 0.
set warpFlag to false.
OutInfo().

RCS On.
OutMsg("Maneuvering for staging").
local stg_TS to Time:Seconds + 10.
set s_Val to ship:SrfRetrograde.
until Time:Seconds > stg_TS
{
    OutMsg("Manuevering for staging: {0}s":Format(Round(stg_TS - Time:Seconds, 2))).
    wait 0.01.
}

OutMsg("Staging [{0}/{1}]":Format(Stage:Number, 1)).
until Stage:Number = 1
{
    wait 0.025.
    Stage.
    wait 0.01.
    OutMsg("Staging [{0}/{1}]":Format(Stage:Number, 1)).
    wait 0.50.
}

OutMsg("Reorienting for reentry").
set s_Val to ship:SrfRetrograde.

for m in Ship:ModulesNamed("RealChuteModule")
{
    OutInfo("Arming parachutes").
    m:DoAction("arm parachute", true).
}
wait 2.5.

OutMsg("Waiting for reentry interface").
until ship:Altitude < body:Atm:height
{
    set s_Val to ship:srfretrograde.
    local etaREI to (Ship:Altitude - Body:Atm:Height) / (Abs(Ship:VerticalSpeed) + GetLocalGravity(Body, Ship:Altitude)).
    local dataLex to lexicon(
        "REENTRY", "-"
        ,"TIME TO ATM INTERFACE", round(etaREI, 2)
        , "VERTICALSPEED", Round(Ship:VerticalSpeed, 1)
    ).
    DispTelemetry(dataLex).
    wait 0.01.
    wait 0.01.
}

OutMsg("Reentry interface").
until Ship:Altitude - Ship:GeoPosition:TerrainHeight < fairingJettisonAlt
{
    set s_Val to ship:srfretrograde.
    local etaImpact to ((Ship:Altitude - Ship:GeoPosition:TerrainHeight) / (Abs(Ship:VerticalSpeed) + GetLocalGravity(Body, Ship:Altitude))).
    local dataLex to lexicon(
        "REENTRY", "-"
        ,"TIME TO IMPACT", round(etaImpact, 2)
        , "VERTICALSPEED", Round(Ship:VerticalSpeed, 1)
    ).
    DispTelemetry(dataLex).
    wait 0.01.
}

if hasReentryFairings
{
    Lights On.
    OutMsg("Fairings jettison").
    OutInfo().
    OutInfo("",1).
    JettisonFairings("fairing.reentry").
    if stageOnFairings
    {
        until Stage:Number = stageToID
        {
            OutInfo("Staging ({0}/{1})":Format(Stage:Number, stageToID)).
            wait 0.25.
            Wait until Stage:Ready.
            Stage.
        }
    }
}
wait 2.

OutMsg("Releasing control").
unlock Steering.
unlock Throttle.
until Ship:Status = "LANDED" or Ship:Status = "SPLASHED"
{
    local etaImpact to ((Ship:Altitude - Ship:GeoPosition:TerrainHeight) / (Abs(Ship:VerticalSpeed) + GetLocalGravity(Body, Ship:Altitude))).
    local dataLex to lexicon(
        "REENTRY", "-"
        ,"TIME TO IMPACT", round(etaImpact, 2)
        , "VERTICALSPEED", Round(Ship:VerticalSpeed, 1)
    ).
    DispTelemetry(dataLex).
    wait 0.01.
}
OutMsg("[{0}]: Complete":Format(ScriptPath())).
OutInfo().
OutInfo("",1).
OutInfo("",2).
wait 1.