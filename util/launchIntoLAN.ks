// Script to run on a separate core to begin a launch countdown at a specific LAN
@lazyGlobal off.
clearScreen.

parameter tgtInc to 0,
          tgtLaunchLAN to ship:orbit:lan + 5.

runOncePath("0:/lib/disp").
runOncePath("0:/lib/nav").
runOncePath("0:/lib/util").

DispMain(scriptPath()).

if hasTarget set tgtLaunchLAN to target:orbit:lan.
local tgtEffectiveLAN to choose mod((360 + tgtLaunchLAN) + (90 - tgtInc), 360) if tgtInc <= 90 and tgtInc >= -90 else abs(mod((360 - tgtLaunchLAN) + (90 - tgtInc), 360)).

local launchWindow to 0.
local timeToLAN to 0.

set timeToLAN to (360 + tgtEffectiveLAN - ship:orbit:LAN) * (body:rotationperiod / 360).
set launchWindow to time:seconds + timeToLAN.
OutTee("Waiting for launch window").

if ship:orbit:lan < tgtEffectiveLAN - 5 or ship:orbit:lan >= tgtEffectiveLAN + 5.01 
{
    InitWarp(launchWindow - 30, "Launch Window").
}

until CheckValRange(ship:orbit:LAN, tgtEffectiveLAN - 5, tgtEffectiveLAN + 5)
{
    DispLaunchWindow(tgtLaunchLAN, tgtEffectiveLAN, launchWindow).
    wait 0.01.
}
if warp > 0 kuniverse:timewarp:cancelwarp.
wait until kuniverse:timewarp:issettled.

until CheckValRange(ship:orbit:LAN, tgtEffectiveLAN, tgtEffectiveLAN + 10)
{
    DispLaunchWindow(tgtLaunchLAN, tgtEffectiveLAN, launchWindow).
    wait 0.01.
}
OutInfo().
OutInfo2().
OutTee("Launch is GO!").
OutTee("Handing off to launch countdown!").
clearScreen.