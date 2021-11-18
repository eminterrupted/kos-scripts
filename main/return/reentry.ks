@lazyGlobal off.
clearScreen.

parameter params is list().

runOncePath("0:/lib/disp").
runOncePath("0:/lib/vessel").
runOncePath("0:/lib/util").

DispMain(scriptPath(), false).

local parachutes to ship:modulesnamed("RealChuteModule").
local payloadStage to choose 0 if core:tag:split("|"):length < 2 else core:tag:split("|")[1].
local reentryTgt to 45000.
local retroFire to false.
local retroStage to 2.
local spinStab to false.
local stagingAlt to ship:body:atm:height + 50000.
local ts to time:seconds.

local sVal to ship:facing.
lock steering to sVal.

local tVal to 0.
lock throttle to tVal.

if params:length > 0 
{
    set retroFire to params[0].
    if params:length > 1 set spinStab to params[1].
    if params:length > 2 set stagingAlt to params[2].
    if params:length > 3 set retroStage to params[3].
}
local startAlt to stagingAlt + 10000.

OutMsg("Waiting until descent").
until ship:verticalspeed < 0 
{
    DispTelemetry().
    wait 0.01.
}

OutMsg("Beginning Reentry Procedure").

if retroFire and ship:periapsis > reentryTgt
{
    OutMsg("Aligning retrograde for retro fire").
    set sVal to ship:retrograde.
    local settleTime to 3.
    set ts to time:seconds + settleTime.
    // set steeringManager:pitchts to 0.25.
    // set steeringManager:yawts to 0.25.
    // set steeringManager:rollts to 0.25.
    until time:seconds >= ts
    {
        if not CheckSteering() 
        {
            set ts to time:seconds + settleTime.
        }
        
        OutInfo("Settle time remaining: " + round(settleTime, 2)).
        DispTelemetry().
        wait 0.05.
    }
    OutInfo().

    if stage:number > payloadStage
    {
        OutMsg("Staging for retro fire").
        until stage:number = payloadStage.
        {
            if stage:ready stage.
            wait 0.25.
        }
    }
    
    if spinStab
    {
        OutMsg("Initiating spin stabilization").
        unlock steering.
        set ts to time:seconds + 7.5.
        until time:seconds > ts 
        {
            set ship:control:roll to 0.5.
            DispTelemetry().
            wait 0.01.
        }
        OutMsg("Spin stabilization complete").
    }

    OutMsg("Firing retro rockets").
    set tVal to 1.
    until stage:number = retroStage
    {
        stage.
        wait until stage:ready.
    }
    until ship:periapsis <= reentryTgt or ship:availableThrust <= 0.1
    {
        DispTelemetry().
    }
    set tVal to 0.
    OutMsg("Retro fire complete").
    wait 1.
    if spinStab
    {
        OutMsg("Stabilizing spin").
        set ts to time:seconds + 7.5.
        until time:seconds > ts
        {
            set ship:control:roll to -1.
            DispTelemetry().wait 0.01.
            set ship:control:neutralize to true.
        }
    }
}

set sVal to lookDirUp(ship:retrograde:vector, sun:position).
lock steering to sVal.

OutMsg("Waiting until altitude <= " + startAlt).
local dir to choose "down" if startAlt <= ship:altitude else "up".
until false
{
    if ship:altitude <= startAlt 
    {
        break.
    }
    else 
    {
        OutTee("Press Enter in terminal to warp " + dir + " to " + startAlt).
        local warpFlag to false.
        until ship:altitude <= startAlt 
        {
            if CheckInputChar(terminal:input:enter) 
            {
                set warpFlag to true.
            }
            if warpFlag 
            {
                WarpToAlt(startAlt).
            }
            set sVal to lookDirUp(ship:retrograde:vector, sun:position).
            DispTelemetry().
            wait 0.01. 
        }
        break.
    }
}

if warp > 0 set warp to 0.
wait until kuniverse:timewarp:issettled.

until ship:altitude <= startAlt
{
    set sVal to lookDirUp(ship:retrograde:vector, sun:position).
    DispTelemetry().
}

if warp > 0 set warp to 0.
wait until kuniverse:timewarp:issettled.

OutMsg("Arming Parachute(s)").
if parachutes:length > 0 
{
    if parachutes[0]:name = "RealChuteModule" 
    {
        for c in parachutes 
        {
            DoEvent(c, "arm parachute").
        }
    }
    else if parachutes[0]:name = "ModuleParachute"
    {
        when parachutes[0]:getField("safe to deploy?") = "Safe" then 
        {
            for c in parachutes
            {
                DoEvent(c, "deploy chute").
            }
        }
    }
}

set sVal to body:position.
OutMsg("Waiting until staging altitude: " + stagingAlt).
until ship:altitude <= stagingAlt.
{
    set sVal to body:position.
    DispTelemetry().
}

if warp > 0 set warp to 0.
wait until kuniverse:timewarp:issettled.
set sVal to body:position.
wait 1.

OutMsg("Staging").
until stage:number <= 1 
{
    stage.
    wait 5.
}
OutMsg("Waiting for reentry interface").

until ship:altitude <= body:atm:height
{
    set sVal to ship:retrograde.
    DispTelemetry().
}
OutMsg("Reentry interface, signal lost").
for m in ship:modulesNamed("ModuleRTAntenna")
{
    DoEvent(m, "Deactivate").
}

until ship:groundspeed <= 1500 and ship:altitude <= 30000
{
    set sVal to ship:srfRetrograde.
    DispTelemetry().
}
for m in ship:modulesNamed("ModuleRTAntenna")
{
    DoEvent(m, "Activate").
}
OutMsg("Signal reacquired").
wait 1.

unlock steering.
OutMsg("Control released").

until alt:radar <= 2500
{
    DispTelemetry().
}
OutMsg("Chute deploy").

until alt:radar <= 5
{
    DispTelemetry().
}