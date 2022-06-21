@LazyGlobal off.
ClearScreen.

parameter params is list().

// Dependencies
RunOncePath("0:/lib/loadDep").

DispMain(ScriptPath():name).

// Declare Variables
local hoverTime to 60.
local hoverStop to 0.
local tgtAlt to 0.
local shipBox to ship:bounds.
local vSpd to 3.
local sVal to ship:facing:vector.
local tVal to 0.

// Pid
local kP to 1.0.
local kI to 0.
local kD to 0.
local plMinOut to 0.
local plMaxOut to 1.
local plSetpoint to 0.

local tPid          to PidLoop(kP, kI, kD, plMinOut, plMaxOut).
set tPid:Setpoint to plSetpoint.

lock steering to up.
lock throttle to tVal.

// Parse Params
if params:length > 0 
{
  set tgtAlt to params[0].
  if params:length > 1 set hoverTime to params[1].
}

OutMsg("Target hover altitude: " + tgtAlt).
OutInfo("Press Enter to launch").
until CheckInputChar(Terminal:Input:Enter)
{
    wait 0.01.
}
OutInfo().

set tVal to 1.
until ship:availableThrust > 0.01 stage.

set tPid:Setpoint to vSpd.
set tVal to 1.
until ship:altitude >= tgtAlt
{
    set tVal to tPid:update(time:seconds, ship:verticalspeed).
    DispTelemetry().
}

OutMsg("TgtAlt reached, hovering").
set tPid:setpoint to 0.
set hoverStop to time:seconds + hoverTime.
until time:seconds >= hoverStop
{
    set tVal to tPid:update(time:seconds, ship:verticalspeed).
    DispTelemetry().
}

OutMsg("Descent").
set tPid:setpoint to -vSpd.
until ship:status = "landed"
{
    set tVal to tPid:update(time:seconds, ship:verticalspeed).
    DispTelemetry().
}

OutMsg("Done!").