@lazyGlobal off.
clearScreen.

parameter params is lex().

runOncePath("0:/lib/disp").
runOncePath("0:/lib/vessel").
runOncePath("0:/lib/util").

DispMain(scriptPath(), false).

local parachutes to ship:modulesnamed("RealChuteModule").
local hsStage to choose 1 if core:tag:split("|"):length < 2 else choose core:tag:split("|")[2]:tonumber if core:tag:split("|"):length > 2 else core:tag:split("|")[1]:tonumber.

local armFairings       to true.
local fairingTag        to "descent".
local fairingAlt        to 6500.
local reentryTgt        to ship:body:atm:height / 2.5.
local retroFire         to false.
local retroStage        to 4.
local shellSepAlt       to 2500.
local spinStab          to false.
local stagingAlt        to ship:body:atm:height + 25000.
local ts                to time:seconds.

set sVal to ship:facing.
lock steering to sVal.

set tVal to 0.
lock throttle to tVal.

///Params
//retroFire: bool, fire rockets to deorbit
//spinStab: bool, stages to fire spin stablization motors
//stagingAlt:scalar, meters above atmosphere of CSM jetison 
//retroStage:scalar, stage number of the retro rocket fire
if params:typename = "lexicon"
{
    if params:keys:length > 0 
    {
        for key in params:keys
        {
            if key = "armFairings" set armFairings to params[key].
            else if key = "fairingTag"  set fairingTag to params[key].
            else if key = "fairingAlt"  set fairingAlt to params[key].
            else if key = "reentryTgt"  set reentryTgt to params[key].
            else if key = "retroFire"   set retroFire to params[key]. 
            else if key = "retroStage"  set retroStage to params[key].
            else if key = "spinStab"    set spinStab to params[key].
            else if key = "stagingAlt"  set stagingAlt to params[key].
            else if key = "shellSepAlt"    set shellSepAlt to params[key].
        }
    }
}
else if params:typename = "list"
{
    set stagingAlt to Max(Body:Atm:Height + 25000, params[0]).
    if params:length > 1 set retroFire to params[1].
    if params:length > 2 set retroStage to params[2].
    if params:length > 3 set reentryTgt to params[3].
    if params:length > 4 set spinStab to params[4].
    if params:length > 5 set armFairings to params[5].
    if params:length > 6 set fairingTag to params[6].
    if params:length > 7 set fairingAlt to params[7].
    if params:length > 8 set shellSepAlt to params[8].
}
local startAlt to stagingAlt + 10000.

OutMsg("Press Enter to warp to Ap, Home to warp to Pe").
OutInfo("Press Down to wait until descent, Up to wait until ascent").
OutInfo2("Press End to begin reentry procedures now").
local mode to "".
local doneFlag to false.

until doneFlag
{
    local charToCheck to GetInputChar().
    if charToCheck <> ""
    {
        if charToCheck = terminal:input:enter
        {
            InitWarp(time:seconds + eta:apoapsis, "apoapsis").
            set mode to "ap".
        }
        else if charToCheck = Terminal:Input:HomeCursor
        {
            InitWarp(time:seconds + eta:periapsis, "periapsis").
            set mode to "pe".
        }
        else if charToCheck = Terminal:Input:UpCursorOne
        {
            set mode to "ascent".
        }
        else if charToCheck = Terminal:Input:DownCursorOne
        {
            set mode to "descent".
        }
        else if charToCheck = terminal:input:endcursor
        {
            set mode to "immediate".
            OutInfo("Immediate reentry procedure mode").
            OutInfo2().
            wait 0.5.
        }
    }
    if mode = "descent" 
    {
        if ship:VerticalSpeed <= 0 set doneFlag to true.
    }
    else if mode = "ascent" 
    {
        if ship:VerticalSpeed >= 0 set doneFlag to true.
    }
    else if mode = "ap"
    {
        if eta:Apoapsis <= 15 set doneFlag to true.
    }
    else if mode = "pe"
    {
        if eta:Periapsis <= 15 set doneFlag to true.
    }
    else if mode = "immediate"
    {
        set doneFlag to true.
    }

    DispTelemetry().
    wait 0.01.
}
OutInfo().
OutInfo2().

OutMsg("Beginning Reentry Procedure").
wait 1.

if retroFire and ship:periapsis > reentryTgt
{
    set sVal to ship:retrograde.
    local settleTime to 5.
    local progCounter to 0.
    local progTimer to time:seconds + 2.5.
    local progMarker to "".
    set ts to time:seconds + settleTime.
    until time:seconds >= ts
    {
        if not CheckSteering(0.050) 
        {
            set ts to time:seconds + settleTime.
            set progCounter to progTimer - time:seconds.
            if progCounter <= 0 
            {
                set progMarker to "".
                set progTimer to time:seconds + 2.5.
            }
            else if progCounter >= 2 set progMarker to "".
            else if progCounter >= 1.5 set progMarker to ".".
            else if progCounter >= 1 set progMarker to "..".
            else if progCounter >= 0.5 set progMarker to "...".
            OutMsg("Retro alignment in progress" + progMarker).
            set progCounter to 0.
        }
        else
        {
            OutInfo("Settle time remaining: " + round(ts - time:seconds, 2)).
        }

        DispTelemetry().
        wait 0.05.
    }
    OutInfo().
    
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

set sVal to lookDirUp(ship:retrograde:vector, Sun:Position).
lock steering to sVal.

OutMsg("Waiting until altitude <= " + startAlt).
local dir to choose "down" if startAlt <= ship:altitude else "up".
local warpFlag to false.
Terminal:Input:Clear.   // Clear the terminal input so we don't auto warp from an old keypress
until false
{
    if ship:altitude <= startAlt 
    {
        set warp to 0.
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
                set warpFlag to true.
            }
            if warpFlag
            {
                WarpToAlt(startAlt + 25000).
                If ship:altitude <= startAlt
                {
                    set warpFlag to false.
                }
            }
            set sVal to lookDirUp(ship:retrograde:vector, Sun:Position).
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
wait 0.25.

if armFairings
{
    OutMsg("Arming Fairings").
    ArmFairingJettison("alt-", fairingAlt, fairingTag).
}
wait 0.25.

if stagingAlt > -1 and stage:number > hsStage
{
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
    wait 5.

    OutMsg("Staging").
    until stage:number <= hsStage
    {
        stage.
        wait 2.
    }
}

OutMsg("Waiting for reentry interface").
set ts to time:seconds + 5.
until ship:altitude <= body:atm:height + 1000
{
    set sVal to GetSteeringDir("retro-sun").
    DispTelemetry().
    if CheckWarpKey()
    {
        OutInfo("Warping to atmospheric reentry: " + body:atm:height).
        WarpToAlt(body:atm:height + 1000).
        terminal:input:clear.
    }
}
OutInfo().

until ship:altitude <= body:atm:height
{
    set sVal to ship:retrograde.
    DispTelemetry().
}
OutMsg("Reentry interface, signal lost").
clrDisp().

// for m in ship:modulesNamed("ModuleRTAntenna")
// {
//     DoEvent(m, "Deactivate").
// }

until ship:groundspeed <= 1350 and ship:altitude <= 30000
{
    set sVal to ship:srfRetrograde.
    DispTelemetry(false). // False: simulate telemetry blackout
}

// for m in ship:modulesNamed("ModuleRTAntenna")
// {
//     DoEvent(m, "Activate").
// }
OutMsg("Signal reacquired").
clrDisp().
wait 1.

unlock steering.
OutMsg("Control released").
wait 1.

OutMsg("Awaiting chute deployment").
until alt:radar <= 1000
{
    DispTelemetry().
}
OutMsg("Heatshield Deploy").
until stage:number <= 1
{
    stage.
    wait 1.
}

// Deploy landing legs / gear
gear on.

until alt:radar <= 1
{
    DispTelemetry().
}