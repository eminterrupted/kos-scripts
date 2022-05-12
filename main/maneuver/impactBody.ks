@LazyGlobal off.
ClearScreen.

parameter params is list().

runOncePath("0:/lib/globals").
runOncePath("0:/lib/burnCalc").
runOncePath("0:/lib/disp").
runOncePath("0:/lib/util").
runOncePath("0:/lib/vessel").

DispMain(ScriptPath(), false).

local orientation       to "retro-radOut".
local srfDir            to "".

// Vars for logging. Will log start values and resulting distance to waypoint after touchdown.
local logPath       to Path("0:/data/landingResults/minmus/_distResults.csv").
local startAlt      to 0.
local startDist     to 0.
local startRadarAlt to 0.
local startTWR      to 0.
local wp to "".

// Parse the params
if params:Length > 0
{
    set orientation to params[0].
}

local sVal to GetSteeringDir(orientation).
lock Steering to sVal.

local tVal to 0.
lock Throttle to tVal.

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
            DispLanding(55).
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
        set startRadarAlt to round(Ship:Bounds:BottomAltRadar, 1).
        set startTWR      to round(GetTWRForStage(), 1).
    }

    // Main loop - iterate through the tgtDescentAlt phases, matching the tgtSrfSpd to the corresponding tgtDescentAlt
    from { local i to 0.} until i + 1 > aDescentAlt:Length step { set i to i + 1.} do 
    {
        local program to i + 60.
        OutMsg("[P" + program + "]: Running descent routine").
        if i = 6 
        {
            Gear on.
            Lights off.
            Lights on.
        }
        set tgtSrfSpd to choose aSrfSpeed[i] / 2 if Ship:Body = Body("Minmus") and aSrfSpeed[i] > 10 else aSrfSpeed[i].
        set tgtVertSpd to choose aVertSpd[i] / 2 if Ship:Body = Body("Minmus") and aVertSpd[i] > 5 else aVertSpd[i].

        until Ship:Bounds:BottomAltRadar <= aDescentAlt[i]
        {
            set srfDir to SrfRetroSafe(). // Returns either a list containing direction depending on verticalSpeed & directionName
            set sVal to srfDir[0].
            if Ship:Velocity:Surface:Mag > tgtSrfSpd * 1.025 //or Ship:VerticalSpeed > tgtVertSpd // If we are above target speed for this altitude, burn
            {
                if tVal <> 1 set tVal to 1.
            }
            else if Ship:Velocity:Surface:Mag <= tgtSrfSpd * 0.975 //or Ship:VerticalSpeed <= tgtVertSpd * 0.975 // If we are below target speed for this altitude, cut throttle
            {
                if tVal <> 0 set tVal to 0.
            }
            DispLanding(program, aDescentAlt[i], tgtSrfSpd, tgtVertSpd).
            OutInfo("SrfRetroSafe mode: " + srfDir[1]).
        }
    }

    set tgtSrfSpd to 0.5.
    set tgtVertSpd to -0.5.
    until Ship:Status = "LANDED"
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

local partsToDeploy to Ship:PartsTaggedPattern("srfDeploy.*").
if partsToDeploy:length > 0
{
    OutMsg("srfDeploy in progress.").
    DeployPartSet("srfDeploy", "deploy").
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