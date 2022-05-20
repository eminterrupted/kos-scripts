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
local startAlt      to 0.
local startDist     to 0.
local startRadarAlt to 0.
local startTWR      to 0.
local vBounds       to Ship:Bounds.
local wp            to "".

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
        OutMsg("[P55]: Press Enter to begin impact sequence").
        until false
        {
            set sVal to GetSteeringDir(orientation).
            if CheckInputChar(Terminal:Input:Enter)
            {
                OutMsg().
                break.
            }
            DispImpact().
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
    }

    until false
    {
        set srfDir to GetSteeringDir("srfPrograde-bodyOut").
        set sVal to srfDir[0].
        if Ship:Periapsis > -10000
        {
            set tVal to 0.50.
        }
        else
        {
            set tVal to 0.
        }
        DispImpact(70, Round(vBounds:BottomAltRadar)).
        OutInfo("SrfRetroSafe mode: " + srfDir[1]).
        if Ship:Status = "LANDED" break.
    }
    set tVal to 0.
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