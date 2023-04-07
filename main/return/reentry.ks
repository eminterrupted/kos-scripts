@lazyGlobal off.
clearScreen.

parameter params is list().

runOncePath("0:/lib/libLoader").

DispMain(scriptPath()).

local parachutes to ship:modulesnamed("RealChuteModule").
local payloadStage to choose 0 if core:tag:split("|"):length < 2 else core:tag:split("|")[2]:tonumber.
local reentryTgt to (ship:body:atm:height * 0.425).
local retroFire to false.
local retroStage to payloadStage.
local spinStab to false.
local stagingAlt to ship:body:atm:height + 25000.
local ts to time:seconds.

local sVal to ship:facing.
lock steering to sVal.

local tVal to 0.
lock throttle to tVal.


///Params
//retroFire: bool, fire rockets to deorbit
//spinStab: bool, stages to fire spin stablization motors
//stagingAlt:scalar, altitude of CSM jetison 
//retroStage:scalar, stage number of the retro rocket fire
if params:length > 0 
{
    set stagingAlt to params[0].
    if params:length > 1 set retroFire to params[1].
    if params:length > 2 set retroStage to params[2].
    if params:length > 3 set spinStab to params[3].
}
local startAlt to stagingAlt + 10000.

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
wait 1.

OutMsg("Enter: Warp to Ap | Home: Warp to Pe").
OutInfo("Down: Wait until descent | Up: Wait until ascent").
OutInfo("End: Begin reentry procedures now | PageDown: Skip reentry burn", 1).
local mode to "".
local doneFlag to false.


until doneFlag
{
    GetTermChar().
    if g_TermChar <> ""
    {
        OutInfo("retroFire: " + retroFire, 1).
        if g_TermChar = terminal:input:enter
        {
            //InitWarp(time:seconds + eta:apoapsis, "apoapsis").
            set mode to "ap".
        }
        else if g_TermChar = Terminal:Input:HomeCursor
        {
            //InitWarp(time:seconds + eta:periapsis, "periapsis").
            set mode to "pe".
        }
        else if g_TermChar = Terminal:Input:UpCursorOne
        {
            set mode to "ascent".
        }
        else if g_TermChar = Terminal:Input:DownCursorOne
        {
            set mode to "descent".
        }
        else if g_TermChar = terminal:input:endcursor
        {
            set mode to "immediate".
            OutInfo("Immediate reentry procedure mode").
            OutInfo("", 1).
            wait 0.5.
        }
        else if g_TermChar = terminal:input:PageDownCursor
        {
            set retroFire to false.
            OutInfo("retroFire: " + retroFire, 1).
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

    // DispTelemetry().
    wait 0.01.
}
OutInfo().
OutInfo("", 1).

OutMsg("Beginning Reentry Procedure").
wait 1.

if retroFire and ship:periapsis > reentryTgt
{
    OutInfo("Target reentry alt: " + round(reentryTgt) + " (" + round(ship:periapsis) + ")", 1).
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

        // DispTelemetry().
        wait 0.05.
    }
    OutInfo().
    OutInfo("", 1).

    // if stage:number > payloadStage
    // {
    //     OutMsg("[" + stage:number + "] Staging to payloadStage [" + payloadStage + "] for retro fire").
    //     until false 
    //     {
    //         if stage:number = payloadStage break.
    //         wait 0.50.
    //         if stage:ready stage.
    //         wait 0.50.
    //     }
    // }
    
    if spinStab
    {
        OutMsg("Initiating spin stabilization").
        unlock steering.
        set ts to time:seconds + 7.5.
        until time:seconds > ts 
        {
            set ship:control:roll to 0.5.
            // DispTelemetry().
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
    wait 0.05.
    local perfObj to GetEnginePerformanceData(GetActiveEngines()).
    until perfObj:ThrustAvailPres <= 0.1 or ship:periapsis <= reentryTgt
    {
        if stage = 1 set tVal to 0.
        else if ship:periapsis <= reentryTgt + 10000
        {
            set tVal to Max(0, Min(1, (ship:periapsis - reentryTgt) / 10000)).
        }
        // DispTelemetry().
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
            // DispTelemetry().
            wait 0.01.
            set ship:control:neutralize to true.
        }
    }
    OutInfo("", 1).
}

set sVal to lookDirUp(ship:retrograde:vector, Sun:Position).
lock steering to sVal.

OutMsg("Waiting until altitude <= " + startAlt).
// local dir to choose "down" if startAlt <= ship:altitude else "up".
// local warpFlag to false.
Terminal:Input:Clear.   // Clear the terminal input so we don't auto warp from an old keypress
// Get Timestamp for target alt
// local tsAlt to ship:orbit:eta:periapsis.
// local shipPos to positionAt(ship, tsAlt).
// local altPos  to shipPos - positionAt(body, tsAlt).
// local warpTS to tsAlt.
// until false
// {
//     set tsAlt to tsAlt - 5.
//     set shipPos to positionAt(ship, tsAlt).
//     set shipPos to positionAt(ship, tsAlt).
//     // set altPos  to shipPos - positionAt(body, tsAlt).
//     // if CheckValRange(altPos, startAlt, startAlt + 5000)
//     // {
//     //     local warpTS to tsAlt.
//     // }
// }

// until false
// {
//     if ship:altitude <= startAlt 
//     {
//         // set warp to 0.
//         break.
//     }
//     // else 
//     // {
//     //     InitWarp(warpTS).
//     //     //OutTee("Press Enter in terminal to warp " + dir + " to " + startAlt).
//     //     until ship:altitude <= startAlt 
//     //     {
//     //         // if CheckWarpKey()
//     //         // {
//     //         //     OutInfo("Warping to startAlt: " + startAlt).
//     //         //     set warpFlag to true.
//     //         // }
//     //         // if warpFlag
//     //         // {
//     //         //     WarpToAlt(startAlt).
//     //         //     If ship:altitude <= startAlt
//     //         //     {
//     //         //         set warpFlag to false.
//     //         //     }
//     //         // }
//     //         set sVal to lookDirUp(ship:retrograde:vector, Sun:Position).
//     //         DispTelemetry().
//     //         wait 0.01. 
//     //     }
//     //     break.
//     // }
// }

// if warp > 0 set warp to 0.
// wait until kuniverse:timewarp:issettled.

OutInfo("Press Home to take control, End to relinquish").
until ship:altitude <= startAlt
{
    GetTermChar().
    if g_TermChar = Terminal:Input:HomeCursor
    {
        unlock steering.
    }
    else if g_TermChar = Terminal:Input:EndCursor
    {
        lock steering to sVal.
    }
    else 
    {
        set sVal to LookDirUp(Ship:Retrograde:Vector, -Body:Position).
    }
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

if stage:number > 1
{
    // set sVal to body:position.
    // OutMsg("Waiting until staging altitude: " + stagingAlt).
    // until ship:altitude <= stagingAlt
    // {
    //     set sVal to GetSteeringDir("body-sun").
    //     DispTelemetry().
    // }

    // if warp > 0 set warp to 0.
    // wait until kuniverse:timewarp:issettled.
    // set sVal to GetSteeringDir("body-sun").
    // wait 5.

    OutMsg("Staging").
    until stage:number <= 1 
    {
        stage.
        wait 2.
    }
}

OutMsg("Waiting for reentry interface").
set ts to time:seconds + 5.
until ship:altitude <= body:atm:height + 1000
{
    set sVal to lookDirUp(ship:retrograde:vector, Sun:Position).
    // DispTelemetry().
    
    // DispGeneric().
    // if CheckWarpKey()
    // {
    //     OutInfo("Warping to atmospheric reentry: " + body:atm:height).
    //     WarpToAlt(body:atm:height + 1000).
    //     terminal:input:clear.
    // }
}
OutInfo().

until ship:altitude <= body:atm:height
{
    set sVal to ship:retrograde.
    // DispTelemetry().
}
OutMsg("Reentry Interface").
// OutMsg("Reentry interface, signal lost").
// // clrDisp().

// for m in ship:modulesNamed("ModuleRTAntenna")
// {
//     DoEvent(m, "Deactivate").
// }

until ship:groundspeed <= 1350 and ship:altitude <= 10000
{
    set sVal to ship:srfRetrograde.
    // DispTelemetry(false). // False: simulate telemetry blackout
}

// for m in ship:modulesNamed("ModuleRTAntenna")
// {
    // DoEvent(m, "Activate").
// }
// OutMsg("Signal reacquired").
// clrDisp().
wait 1.

unlock steering.
OutMsg("Control released").

local fairings to ship:PartsTaggedPattern("Fairing\|(Reentry|Descent)").
local jettAlt to 2500.

if fairings:Length > 0 
{
    if fairings[0]:Tag:Split("|"):Length > 2
    {
        set jettAlt to fairings[0]:Tag:Split("|")[2]:ToNumber(2500).
    }
}

until (Ship:Altitude - Ship:GeoPosition:TerrainHeight) <= jettAlt
{
    for f in fairings
    {
        local m to f:GetModule("ProceduralFairingDecoupler").
        DoEvent(m, "jettison fairing").
    }
    // DispTelemetry().
}
OutMsg("Chute deploy").

until alt:radar <= 5
{
    // DispTelemetry().
}