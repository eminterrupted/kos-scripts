@LazyGlobal off.
ClearScreen.

parameter params is list().

runOncePath("0:/lib/globals").
runOncePath("0:/lib/burnCalc").
runOncePath("0:/lib/disp").
runOncePath("0:/lib/util").
runOncePath("0:/lib/vessel").

DispMain(ScriptPath(), false).

local orientation       to "retro-sun".
local srfDir            to "".
local tgtDescentAlt     to list(10000, 7500, 5000, 2500, 1250, 750, 500, 250, 100,  75, 10, 3, 0).
local tgtSpd            to 0.
local tgtSrfSpd         to list(  300,  225,  150,  125,  100,  75,  50,  25,  10, 7.5,  5, 2, 1).

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
        OutMsg("[P55]: Press End to begin landing sequence").
        until false
        {
            set sVal to GetSteeringDir(orientation).
            if CheckInputChar(Terminal:Input:EndCursor)
            {
                OutMsg().
                break.
            }
            DispLanding(55).
        }
    }

    // Main loop - iterate through the tgtDescentAlt phases, matching the tgtSrfSpd to the corresponding tgtDescentAlt
    from { local i to 0.} until i + 1 > tgtDescentAlt:Length step { set i to i + 1.} do 
    {
        local program to i + 60.
        OutMsg("[P" + program + "]: Running descent routine").
        if i = 6 
        {
            Gear On.
            Lights on.
        }
        set tgtSpd to choose tgtSrfSpd[i] / 2 if Ship:Body = Body("Minmus") and tgtSrfSpd[i] > 10 else tgtSrfSpd[i].                    // Select the sirection for sVal.
        until Ship:Bounds:BottomAltRadar <= tgtDescentAlt[i]
        {
            set srfDir to SrfRetroSafe(). // Returns either a list containing direction depending on verticalSpeed & directionName
            set sVal to srfDir[0].
            if Ship:Velocity:Surface:Mag > tgtSpd * 1.025   // If we are above target speed for this altitude, burn
            {
                if tVal <> 1 set tVal to 1.
            }
            else if Ship:Velocity:Surface:Mag <= tgtSpd * 0.975    // If we are below target speed for this altitude, cut throttle
            {
                if tVal <> 0 set tVal to 0.
            }
            DispLanding(program, tgtDescentAlt[i], tgtSpd).
            OutInfo("SrfRetroSafe mode: " + srfDir[1]).
        }
    }

    set tgtSpd to -0.5.
    until Ship:Status = "LANDED"
    {
        set srfDir to SrfRetroSafe().
        set sVal to srfDir[0].
        if Ship:VerticalSpeed <= tgtSpd
        {
            set tVal to 1.
        }
        else
        {
            set tVal to 0.
        }
        DispLanding(70, 0, tgtSpd).
        OutInfo("SrfRetroSafe mode: " + srfDir[1]).
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
OutHud("End of " + ScriptPath():Name).
wait 1.