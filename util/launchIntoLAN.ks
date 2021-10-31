// Script to run on a separate core to begin a launch countdown at a specific LAN
@lazyGlobal off.
clearScreen.

parameter tgtLaunchLAN to ship:orbit:lan + 5,
          tgtInc to 0.

runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_nav").
runOncePath("0:/lib/lib_util").

disp_main(scriptPath()).

if hasTarget set tgtLaunchLAN to target:orbit:lan.
local tgtEffectiveLAN to choose mod((360 + tgtLaunchLAN) + (90 - tgtInc), 360) if tgtInc <= 90 and tgtInc >= -90 else abs(mod((360 - tgtLaunchLAN) + (90 - tgtInc), 360)).

local launchWindow to 0.
local timeToLAN to 0.

set timeToLAN to (360 + tgtEffectiveLAN - ship:orbit:LAN) * (body:rotationperiod / 360).
set launchWindow to time:seconds + timeToLAN.
disp_tee("Waiting for launch window").

if ship:orbit:lan < tgtEffectiveLAN - 5 or ship:orbit:lan >= tgtEffectiveLAN + 5.01 
{
    util_warp_trigger(launchWindow - 30, "Launch Window").
}

until util_check_range(ship:orbit:LAN, tgtEffectiveLAN - 5, tgtEffectiveLAN + 5)
{
    disp_launch_window(tgtLaunchLAN, tgtEffectiveLAN, launchWindow).
    wait 0.01.
}
if warp > 0 kuniverse:timewarp:cancelwarp.
wait until kuniverse:timewarp:issettled.

until util_check_range(ship:orbit:LAN, tgtEffectiveLAN, tgtEffectiveLAN + 10)
{
    disp_launch_window(tgtLaunchLAN, tgtEffectiveLAN, launchWindow).
    wait 0.01.
}
disp_info().
disp_info2().
disp_tee("Launch is GO!").
disp_tee("Handing off to launch countdown!").
clearScreen.