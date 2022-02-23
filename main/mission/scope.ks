@LazyGlobal off.
ClearScreen.

Parameter param is list().

RunOncePath("0:/lib/disp").
RunOncePath("0:/lib/vessel").

DispMain(ScriptPath(), false).

local maxTorque to "0.000005".
local tgtBody to Ship:Body.

if param:length > 0 
{
    set tgtBody to GetOrbitable(param[0]).
}

local sVal to GetSteeringDir("facing-sun").

OutMsg("Calibrating Telescope").
OutInfo("Setting Steering Manager to: " + maxTorque).

set SteeringManager:TorqueEpsilonMax to maxTorque:ToNumber(0.0005).
wait 1.

lock steering to sVal.

OutInfo().

until false
{
    set sVal to GetTargetDir().
    DispScope().
}

local function GetTargetDir
{
    if HasTarget
    {
        OutMsg("Scope target: " + Target:Name).
        return Target:Position.
    }
    else if tgtBody <> Ship:Body
    {
        set Target to tgtBody.
        OutMsg("Scope target: " + Target:Name).
        return Target:Position.
    }
    else
    {
        OutMsg("Scope target: N/A").
        return GetSteeringDir("facing-sun").
    }
}