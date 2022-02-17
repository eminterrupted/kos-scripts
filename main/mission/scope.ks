@LazyGlobal off.
ClearScreen.

Parameter param is list().

RunOncePath("0:/lib/disp").
RunOncePath("0:/lib/vessel").

DispMain(ScriptPath(), false).

local maxTorque to 0.00001.
local tgtBody to Ship:Body.

if param:length > 0 
{
    set tgtBody to GetOrbitable(param[0]).
}

set Steering to GetSteeringDir("facing-sun").

OutMsg("Calibrating Telescope").
OutInfo("Setting Steering Manager to: " + maxTorque).

set SteeringManager:TorqueEpsilonMax to maxTorque.
wait 3.

OutInfo().
if HasTarget 
{
    OutMsg("Focusing on target: " + target:name).
    lock sVal to target:position.
}
else
{
    if tgtBody <> Ship:Body
    {
        set target to tgtBody.
        lock sVal to target:position.
    }
}

lock Steering to sVal.

until false
{
    DispScope().
}