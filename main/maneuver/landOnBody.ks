@LazyGlobal off.
ClearScreen.

parameter params is list().

runOncePath("0:/lib/globals").
runOncePath("0:/lib/burnCalc").
runOncePath("0:/lib/disp").
runOncePath("0:/lib/util").
runOncePath("0:/lib/vessel").

DispMain(ScriptPath(), false).

local orientation       to "retro-body".

// Parse the params
if params:Length > 0
{
    set orientation to params[0].
}

// Variables
local tgtAlt            to 0.
local tgtSrfSpd         to 0.
local tgtVertSpd        to 0.
local srfDir            to "".
local tDescent          to list().

local vBounds to Ship:Bounds.
local gearFlag to true.

// Vars for logging. Will log start values and resulting distance to waypoint after touchdown.
local logPath       to Path("0:/data/landingResults/minmus/_distResults.csv").
local startAlt      to 0.
local startDist     to 0.
local startRadarAlt to 0.
local startTWR      to 0.
local wp to "".

lock Steering to sVal.
lock Throttle to tVal.

// The descent table for each body
local descentTable to lex(
    Body("Gilly"):Name, lex(
        "SrfSpd",   list(   25,     15,   10,  7.5,    5,   2.5,   1)
        ,"VSpd",    list(  -25,    -15,  -10, -7.5,   -5,  -2.5,  -1)
        ,"Alt",     list( 1000,    250,  100,   50,    25, 12.5,   5)
    )
    ,Body("Ike"):Name, lex(
        "SrfSpd",   list(   200,  125,   75,   50,   25,   10,    5,  2.5,   1)
        ,"VSpd",    list(  -200, -100,  -75,  -25,  -10,  -10,   -5, -2.5,  -1)
        ,"Alt",     list( 10000, 5000, 2500, 1000,  500,  250,   50,   10,   5)
    )
    ,Body("Mun"):Name, lex(
        "SrfSpd",   list(  375,    250,  150,  125,  100,    75,  50,  25,  10,  7.5,  5,  2)
        ,"VSpd",    list( -150,   -125, -100,  -75,  -65,   -55, -40, -20, -10, -7.5, -5, -2)
        ,"Alt",     list(10000,   7500, 5000, 2500, 1250,   750, 500, 250, 100,   75, 10,  3)
    )
    ,Body("Minmus"):Name, lex(
        "SrfSpd",   list(  150, 122.5,  100,    50,    25,   10,     5,  2.5)
        ,"VSpd",    list( -100,   -75,  -50,   -25, -12.5,   -5,  -7.5,   -5)
        ,"Alt",     list( 7500,  5000,  2500,  500,   100,   25,    10,    5)
    )
).

if Ship:Status = "LANDED"
{
    OutMsg("Ship already landed!").
    unlock Steering.
    unlock Throttle.
}
else
{   
    ArmAutoStaging().
    lock steering to sVal.

    set tDescent to descentTable[Ship:Body:Name].

    if ship:periapsis > 0 
    {
        OutMsg("[P55]: Press Enter to begin landing sequence").
        until false
        {
            set sVal to GetSteeringDir(orientation).
            if CheckInputChar(Terminal:Input:Enter)
            {
                OutMsg().
                break.
            }
            DispLanding(55, tDescent:Alt[0], tDescent:SrfSpd[0], tDescent:VSpd[0]).
        }
    }

    // Tuning vars for result logging
    for wpt in AllWaypoints()
    {
        if wpt:IsSelected set wp to wpt.
    }
    if wp = ""
    {
        OutMsg("Logging Error: No Waypoint Selected!").
    }
    else
    {
        set startDist     to round(vxcl(ship:up:vector, wp:position):mag, 2).
        set startAlt      to round(ship:altitude, 1).
        set startRadarAlt to round(vBounds:BottomAltRadar, 1).
        set startTWR      to round(GetTWRForStage(), 1).
    }

    // Main loop - iterate through the tgtDescentAlt phases, matching the tgtSrfSpd to the corresponding tgtDescentAlt
    from { local i to 0.} until i + 1 > tDescent:Alt:Length step { set i to i + 1.} do 
    {
        local program to i + 60.
        
        OutMsg("[P" + program + "]: Running descent routine").
        

        if i > (tDescent:Alt:Length / 2) and gearFlag
        {
            Gear on.
            Lights off.
            Lights on.
            set gearFlag to false.
        }

        local tgtAlt    to tDescent:Alt[i].
        local tgtSrfSpd to tDescent:SrfSpd[i].
        local tgtVSpd   to tDescent:VSpd[i].

        until vBounds:BottomAltRadar <= tgtAlt
        {
            if g_staged
            {
                set vBounds to ResetStagedStatus().
            }
            set srfDir to SrfRetroSafe(). // Returns either a list containing direction depending on verticalSpeed & directionName
            set sVal to srfDir[0].

            if GetInputChar() = Terminal:Input:HomeCursor
            {
                OutInfo2("Throttle unlocked for manual control").
                unlock throttle.
            }
            else if g_termChar = Terminal:Input:EndCursor
            {
                OutInfo2("Throttle locked to autopilot").
                lock throttle to tVal.
            }
            
            if Ship:Velocity:Surface:Mag > tgtSrfSpd * 1.025 //or Ship:VerticalSpeed > tgtVertSpd // If we are above target speed for this altitude, burn
            {
                if tVal <> 1 set tVal to 1.
            }
            else if Ship:Velocity:Surface:Mag <= tgtSrfSpd * 0.975 //or Ship:VerticalSpeed <= tgtVertSpd * 0.975 // If we are below target speed for this altitude, cut throttle
            {
                if tVal <> 0 set tVal to 0.
            }

            DispLanding(program, tgtAlt, tgtSrfSpd, tgtVertSpd, vBounds:BottomAltRadar).
            OutInfo("SrfRetroSafe mode: " + srfDir[1]).
            if Ship:Status = "LANDED" break.
        }
    }

    set tgtSrfSpd to 0.5.
    set tgtVertSpd to -0.5.
    until Ship:Status = "LANDED" or CheckInputChar(Terminal:Input:EndCursor)
    {
        set srfDir to SrfRetroSafe().
        set sVal to srfDir[0].
        if Ship:VerticalSpeed <= tgtVertSpd
        {
            set tVal to 0.50.
        }
        else
        {
            set tVal to 0.
        }
        DispLanding(70, 0, tgtSrfSpd, tgtVertSpd).
        OutInfo("SrfRetroSafe mode: " + srfDir[1]).
        if Ship:Status = "LANDED" break.
    }
    set tVal to 0.

    for eng in GetEnginesByStage(stage:number)
    {
        eng:shutdown.
    }
    OutInfo().
    OutInfo2().
    unlock Steering.
    sas on.
    OutMsg("Landing complete!").
}

wait 1.

local partsToDeploy to Ship:PartsTaggedPattern("deploy.land.*").
if partsToDeploy:length > 0
{
    OutMsg("Deploy Land Group in progress.").
    DeployPartSet("land", "deploy").
    OutMsg("Deployments complete").
}
wait 1.

if wp <> "" 
{
    OutMsg("Logging distance results").
    local resultDist to vxcl(Ship:Up:Vector, wp:position).
    if Exists(Path(logPath))
    {
        log startDist + "," + startAlt + "," + startRadarAlt + "," + startTWR + "," + resultDist to logPath.
    }
    else
    {
        log "StartDist,StartAlt,StartRadarAlt,StartTWR,ResultDist" to logPath.
        log startDist + "," + startAlt + "," + startRadarAlt + "," + startTWR + "," + resultDist to logPath.
    }
}

OutHud("End of " + ScriptPath():Name).
wait 1.