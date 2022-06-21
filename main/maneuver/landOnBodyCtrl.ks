@LazyGlobal off.
ClearScreen.

parameter params is list().

runOncePath("0:/lib/globals").
runOncePath("0:/lib/burnCalc").
runOncePath("0:/lib/disp").
runOncePath("0:/lib/util").
runOncePath("0:/lib/vessel").

DispMain(ScriptPath(), false).

local orientation   to "retro-body".
local srfDir        to "".
local tgtHoverAlt   to 100.
local tgtObtSpd     to 150.
local tgtSrfSpd     to 150.
local tgtVertSpd    to 0.

local tti to 0.
local tKillVel to 0.

local kP to 1.0.
local kI to 0.
local kD to 0.
local plMinOut to 0.
local plMaxOut to 1.
local plSetpoint to 0.

local tPid          to PidLoop(kP, kI, kD, plMinOut, plMaxOut).
set tPid:Setpoint to plSetpoint.

local vBounds to Ship:Bounds.

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

    set tVal to 1.
    until ship:velocity:surface:mag <= tgtSrfSpd
    {
        set sVal to GetSteeringDir(orientation).
        DispLanding(21, 0, tgtSrfSpd).
    }
    set tVal to 0.

    // Coast until suicide burn
    until false
    {
        
    }

    // Landed
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
    OutMsg("srfDeploy in progress").
    DeployPartSet("land", "deploy").
    OutMsg("Deployments complete").
}
wait 1.

OutHud("End of " + ScriptPath():Name).
wait 1.