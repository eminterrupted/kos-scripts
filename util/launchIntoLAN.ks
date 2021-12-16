// Script to run on a separate core to begin a launch countdown at a specific LAN
@lazyGlobal off.
clearScreen.

parameter tgtInc to 0,
          tgtLaunchLAN to ship:orbit:lan + 7.5.

runOncePath("0:/lib/disp").
runOncePath("0:/lib/nav").
runOncePath("0:/lib/util").

DispMain(scriptPath()).

if hasTarget set tgtLaunchLAN to target:orbit:lan.
local tgtEffectiveLAN to choose mod((360 + tgtLaunchLAN) + 90, 360) if tgtInc <= 90 and tgtInc >= -90 else abs(mod((360 - tgtLaunchLAN) + 90, 360)).

local tgtLaunchBuffer to 1.0.

local launchWindow to 0.
local timeToLAN to 0.

//set timeToLAN to (360 + tgtEffectiveLAN - ship:orbit:LAN) * (body:rotationperiod / 360).
set timeToLAN to mod((360 + tgtEffectiveLAN - ship:orbit:LAN) * (body:rotationperiod / 360), body:rotationPeriod).
set launchWindow to time:seconds + timeToLAN.
OutTee("Waiting for launch window").

if ship:orbit:lan < tgtEffectiveLAN - tgtLaunchBuffer or ship:orbit:lan >= tgtEffectiveLAN + tgtLaunchBuffer
{
    InitWarp(launchWindow, "Launch Window").
}

until CheckValRange(ship:orbit:LAN, tgtEffectiveLAN - tgtLaunchBuffer, tgtEffectiveLAN + tgtLaunchBuffer)
{
    DispLaunchWindow(tgtInc, tgtLaunchLAN, tgtEffectiveLAN, launchWindow).
    wait 0.01.
}
if warp > 0 kuniverse:timewarp:cancelwarp.
wait until kuniverse:timewarp:issettled.

until CheckValRange(ship:orbit:LAN, tgtEffectiveLAN, tgtEffectiveLAN + 10)
{
    DispLaunchWindow(tgtInc, tgtLaunchLAN, tgtEffectiveLAN, launchWindow).
    wait 0.01.
}
if warp > 0 kuniverse:timewarp:cancelwarp.
wait until kuniverse:timewarp:issettled.
OutInfo().
OutInfo2().
OutTee("Launch is GO!").
OutTee("Handing off to launch countdown!").
clearScreen.