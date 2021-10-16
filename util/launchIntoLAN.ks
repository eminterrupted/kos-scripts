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
local tgtEffectiveLAN to mod((360 + tgtLaunchLAN) + (90 - tgtInc), 360).

local curLan to 0.
local degPerSec to 0.
local lanDiff to 0.
local launchWindow to 0.
local timeToLAN to 0.
local ts to 0.

disp_msg("Measuring current LAN rate...").
set curLan to ship:orbit:lan.
set ts to time:seconds + 60.
warpTo(ts).
until time:seconds >= ts 
{
    disp_info("Time remaining: " + round(ts - time:seconds, 2)).
}
set lanDiff to mod(360 + ship:orbit:lan - curLan, 360).
set degPerSec to lanDiff / 60.

set timeToLAN to mod(360 + tgtEffectiveLAN - ship:orbit:lan, 360) / degPerSec.
set launchWindow to time:seconds + timeToLAN.
disp_tee("Waiting for launch window").
disp_info2("EffectiveLAN: " + round(tgtEffectiveLAN, 3)).
util_warp_trigger(launchWindow - 15, "Launch Window").

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