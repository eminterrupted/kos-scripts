// Script to run on a separate core to begin a launch countdown at a specific LAN
@lazyGlobal off.
clearScreen.

parameter tgtInc to 0,
          tgtLaunchLAN to ship:orbit:lan + 7.5.

runOncePath("0:/lib/disp").
runOncePath("0:/lib/launch").
runOncePath("0:/lib/nav").
runOncePath("0:/lib/util").

DispMain(scriptPath()).

//if hasTarget set tgtLaunchLAN to target:orbit:lan.
local spdFactor to 2.92.
local latSrfSpd to 2 * constant:pi * body:position:mag * cos(ship:geoposition:lat) / body:rotationperiod.
local lanAdjust to round(latSrfSpd / spdFactor, 1).

local tgtEffectiveLAN   to choose mod((360 + tgtLaunchLAN) + lanAdjust, 360) if tgtInc <= 90 and tgtInc >= -90 else abs(mod(360 + tgtLaunchLAN + lanAdjust, 360)).
local tgtBuffer         to 90 * (latSrfSpd / body:rotationperiod).
local tgtBufferLANLow   to mod(360 + tgtEffectiveLAN - tgtBuffer, 360).
local tgtBufferLANHigh  to mod(360 + tgtEffectiveLAN + tgtBuffer, 360).
local tgtWarpStopLAN    to tgtEffectiveLAN + (15 * (latSrfSpd / body:rotationperiod)).

local launchNow to false.
local launchWindow to 0.
local timeToLAN to 0.


//set timeToLAN to (360 + tgtEffectiveLAN - ship:orbit:LAN) * (body:rotationperiod / 360).
set timeToLAN to mod((360 + tgtEffectiveLAN - ship:orbit:LAN) * (body:rotationperiod / 360), body:rotationPeriod).
set launchWindow to time:seconds + timeToLAN.
lock launchETA to time:seconds - launchWindow.
DispLaunchWindow2(launchETA, tgtInc, tgtLaunchLAN, latSrfSpd, lanAdjust, tgtEffectiveLAN).
wait 2.5.

OutTee("Waiting for launch window").
OutInfo("Enter to warp to launch, End to launch now").

until CheckValRange(ship:orbit:LAN, tgtBufferLANLow, tgtBufferLANHigh)
{
    set g_termChar to GetInputChar().

    if g_termChar = Terminal:Input:Enter
    {
        InitWarp(launchWindow, "Launch Window", 15, true).
    }
    else if g_termChar = Terminal:Input:Endcursor
    {
        set launchNow to true.
    }
        
    // set g_termChar to GetInputChar().
    // if g_termChar = "" 
    // {
    //     OutInfo().
    // }
    // else
    // {
    //     OutInfo("Current Keypress: " + g_termChar).
    // }

    // if g_termChar = Terminal:Input:Enter
    // {
    //     InitWarp(launchWindow, "Launch Window", 15, true).
    //     Terminal:Input:Clear.
    // }
    DispLaunchWindow2(launchETA, tgtInc, tgtLaunchLAN, latSrfSpd, lanAdjust, tgtEffectiveLAN).
    if launchNow break.
    wait 0.1.
}
if warp > 0 kuniverse:timewarp:cancelwarp.
wait until kuniverse:timewarp:issettled.

if launchNow
{
    OutMsg("Immediate launch mode activated").
}
else
{
    until CheckValRange(ship:orbit:LAN, tgtEffectiveLAN, tgtWarpStopLAN)
    {
        DispLaunchWindow2(launchETA, tgtInc, tgtLaunchLAN, latSrfSpd, lanAdjust, tgtEffectiveLAN).
        wait 0.01.
    }
    if warp > 0 kuniverse:timewarp:cancelwarp.
    wait until kuniverse:timewarp:issettled.
}
OutInfo().
OutInfo2().
OutTee("Launch is GO!").
unlock launchETA.
OutTee("Handing off to launch countdown!").
clearScreen.