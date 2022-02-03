@lazyGlobal off.
clearScreen.

parameter params is list().

runOncePath("0:/lib/disp").
runOncePath("0:/lib/vessel").
runOncePath("0:/lib/util").

DispMain(scriptPath(), false).

local parachutes to ship:modulesnamed("RealChuteModule").
local payloadStage to choose 0 if core:tag:split("|"):length < 2 else core:tag:split("|")[1]:tonumber.
local reentryTgt to ship:body:atm:height / 2.
local retroFire to false.
local retroStage to 4.
local spinStab to false.
local stagingAlt to ship:body:atm:height + 25000.
local ts to time:seconds.

local sVal to ship:facing.
local rVal to ship:facing:roll.
lock steering to sVal + r(0, 0, rVal).

local tVal to 0.
lock throttle to tVal.


///Params
//retroFire: bool, fire rockets to deorbit
//spinStab: bool, stages to fire spin stablization motors
//stagingAlt:scalar, altitude of CSM jetison 
//retroStage:scalar, stage number of the retro rocket fire
if params:length > 0 
{
    set retroFire to params[0].
    if params:length > 1 set spinStab to params[1].
    if params:length > 2 set stagingAlt to params[2].
    if params:length > 3 set retroStage to params[3].
}
local startAlt to stagingAlt + 10000.

OutMsg("Waiting until descent").
OutInfo("Press Enter to warp to Ap").
OutInfo2("Press End to begin reentry procedures now").
until ship:verticalspeed < 0 
{
    local charToCheck to GetInputChar().
    if charToCheck <> ""
    {
        if charToCheck = terminal:input:enter
        {
            InitWarp(time:seconds + eta:apoapsis, "apoapsis").
        }
        else if charToCheck = terminal:input:endcursor
        {
            OutInfo("Immediate reentry procedure mode").
            OutInfo2().
            break.
        }
    }
    DispTelemetry().
    wait 0.01.
}
OutInfo().
OutInfo2().

OutMsg("Beginning Reentry Procedure").

if retroFire and ship:periapsis > reentryTgt
{
    OutMsg("Aligning retrograde for retro fire").
    set sVal to ship:retrograde + r(0, 0, rVal).
    local settleTime to 3.
    set ts to time:seconds + settleTime.
    until time:seconds >= ts
    {
        if not CheckSteering() 
        {
            set ts to time:seconds + settleTime.
        }
        
        OutInfo("Settle time remaining: " + round(ts - time:seconds, 2)).
        DispTelemetry().
        wait 0.05.
    }
    OutInfo().

    if stage:number > payloadStage
    {
        OutMsg("[" + stage:number + "] Staging to payloadStage [" + payloadStage + "] for retro fire").
        until false 
        {
            if stage:number = payloadStage break.
            wait 0.50.
            if stage:ready stage.
            wait 0.50.
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

    OutMsg("Firing retro rockets to stage " + retroStage).
    set tVal to 1.
    until stage:number <= retroStage
    {
        stage.
        wait until stage:ready.
    }
    wait 0.1.
    until GetTotalThrust(GetEngines("active"), "curr") <= 0.1 or ship:periapsis <= reentryTgt
    {
        if stage = 1 set tVal to 0.
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
            DispTelemetry().
            wait 0.01.
            set ship:control:neutralize to true.
        }
    }
}

set sVal to lookDirUp(ship:retrograde:vector, sun:position) + r(0, 0, rVal).
lock steering to sVal.

OutMsg("Waiting until altitude <= " + startAlt).
local dir to choose "down" if startAlt <= ship:altitude else "up".
Terminal:Input:Clear.   // Clear the terminal input so we don't auto warp from an old keypress
until false
{
    if ship:altitude <= startAlt 
    {
        break.
    }
    else 
    {
        OutTee("Press Enter in terminal to warp " + dir + " to " + startAlt).
        until ship:altitude <= startAlt 
        {
            if CheckWarpKey()
            {
                OutInfo("Warping to startAlt: " + startAlt).
                WarpToAlt(startAlt).
            }
            set sVal to lookDirUp(ship:retrograde:vector, sun:position) + r(0, 0, rVal).
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
    set sVal to ship:facing.
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
until ship:altitude <= stagingAlt
{
    set sVal to GetSteeringDir("body-sun").
    DispTelemetry().
}

if warp > 0 set warp to 0.
wait until kuniverse:timewarp:issettled.
set sVal to GetSteeringDir("body-sun").
wait 1.

OutMsg("Staging").
until stage:number <= 1 
{
    stage.
    wait 2.
}
OutMsg("Waiting for reentry interface").
set ts to time:seconds + 5.
until ship:altitude <= body:atm:height + 1000
{
    set sVal to ship:retrograde + r(0, 0, rVal).
    DispTelemetry().
    if CheckWarpKey()
    {
        OutInfo("Warping to atmospheric reentry: " + body:atm:height).
        WarpToAlt(body:atm:height + 1000).
        terminal:input:clear.
    }
}

until ship:altitude <= body:atm:height
{
    set sVal to ship:retrograde + r(0, 0, rVal).
    DispTelemetry().
}
OutMsg("Reentry interface, signal lost").
clrDisp().

for m in ship:modulesNamed("ModuleRTAntenna")
{
    DoEvent(m, "Deactivate").
}

until ship:groundspeed <= 1350 and ship:altitude <= 30000
{
    set sVal to ship:srfRetrograde + r(0, 0, rVal).
    DispTelemetry(false). // False: simulate telemetry blackout
}

for m in ship:modulesNamed("ModuleRTAntenna")
{
    DoEvent(m, "Activate").
}
OutMsg("Signal reacquired").
clrDisp().
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