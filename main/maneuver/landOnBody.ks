@LazyGlobal off.
ClearScreen.

parameter params is list().

runOncePath("0:/lib/globals").
runOncePath("0:/lib/burnCalc").
runOncePath("0:/lib/disp").
runOncePath("0:/lib/util").
runOncePath("0:/lib/vessel").

DispMain(ScriptPath(), false).

local orientation to "facing-sun".
local tgtSrfSpd to list(250, 125, 75, 25, 10, 5).
local tgtVSpd to -100.

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
    OutMsg("Press End to end coast phase and begin landing sequence").
    until false
    {
        if CheckInputChar(Terminal:Input:EndCursor)
        {
            OutMsg().
            break.
        }
        set sVal to srfRetroFailsafe()[0].
        DispTelemetry().
    }

    // Fast braking phase to 250.
    if Ship:Velocity:Surface:Mag >= tgtSrfSpd[0]
    {
        set tVal to 1.
        OutMsg("Landing Initiated").
        OutInfo("Burn 0 [100%]: srfVelocity <= " + tgtSrfSpd[0]).
        until Ship:Velocity:Surface:Mag <= tgtSrfSpd[0]
        {
            set sVal to srfRetroFailsafe()[0].
            DispTelemetry().
        }
    }

    if Ship:Velocity:Surface:Mag >= tgtSrfSpd [2]
    {
        set tVal to 0.65.
        OutInfo("Burn 1 [ 65%]: srfVelocity <= " + tgtSrfSpd[2]).
        until Ship:Velocity:Surface:Mag <= tgtSrfSpd[2]
        {
            set sVal to srfRetroFailsafe()[0].
            DispTelemetry().
        }
        set tVal to 0.
        OutInfo().
    }

    // Manual braking down to 1000m
    unlock throttle.
    OutMsg("Throttle unlocked and returned to manual control").
    until alt:radar <= 1000
    {
        local srfDir to srfRetroFailsafe().
        set sVal to srfDir[0].
        DispTelemetry().
        OutInfo("Surface Speed [tgt]: " + round(Ship:Orbit:Velocity:Surface:Mag) + " [" + tgtVSpd + "]").
        OutInfo2("srfRetroFailsafe mode: " + srfDir[1]).
    }

    set tgtVSpd to -25.
    until alt:radar <= 250
    {
        local srfDir to srfRetroFailsafe().
        set sVal to srfDir[0].
        DispTelemetry().
        OutInfo("Vertical Speed [tgt]: " + round(VerticalSpeed) + " [" + tgtVSpd + "]").
        OutInfo2("srfRetroFailsafe mode: " + srfDir[1]).
    }

    // Deploy the landing legs
    Gear on.

    set tgtVSpd to -10.
    until alt:radar <= 100
    {
        local srfDir to srfRetroFailsafe().
        set sVal to srfDir[0].
        DispTelemetry().
        OutInfo("Vertical Speed [tgt]: " + round(VerticalSpeed) + " [" + tgtVSpd + "]").
        OutInfo2("srfRetroFailsafe mode: " + srfDir[1]).
    }

    // Turn on the landing lights
    Lights on.

    set tgtVSpd to -5.
    until alt:radar <= 10
    {
        local srfDir to srfRetroFailsafe().
        set sVal to srfDir[0].
        DispTelemetry().
        OutInfo("Vertical Speed [tgt]: " + round(VerticalSpeed) + " [" + tgtVSpd + "]").
        OutInfo2("srfRetroFailsafe mode: " + srfDir[1]).
    }

    set tgtVSpd to -2.
    until Alt:Radar <= Ship:Status = "LANDED"
    {
        local srfDir to srfRetroFailsafe().
        set sVal to srfDir[0].
        DispTelemetry().
        OutInfo("Vertical Speed [tgt]: " + round(VerticalSpeed) + " [" + tgtVSpd + "]").
        OutInfo2("srfRetroFailsafe mode: " + srfDir[1]).
    }

    OutInfo().
    OutInfo2().
    OutMsg("Landing complete!").
}

wait 1.

local partsToDeploy to ship:partstaggedpattern("srfDeploy.*").
if partsToDeploy:length > 0
{
    OutMsg("Deploying landing apparatus.").
    DeployPartSet("srfDeploy", "deploy").
    OutMsg("Deployments complete").
}


////
local function srfRetroFailsafe
{
    if Ship:VerticalSpeed <= 0 
    {
        return list(GetSteeringDir("srfRetro-sun"), "srfRetro_Locked").
    }
    else
    {
        return list(GetSteeringDir("radOut-pro"), "upPos_Override").
    }
}