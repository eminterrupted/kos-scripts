@lazyGlobal off.
clearScreen.

// Easy reentry near KSC

//-- Dependencies --//
runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_nav").
runOncePath("0:/lib/lib_util").

disp_main(scriptPath()).

//-- Variables --//
local parachutes to ship:modulesNamed("RealChuteModule").
local kscWindow  to list(145, 150).
local reentryAlt to 35000.
local shipLng    to 0.
local stagingAlt to ship:body:atm:height + 15000.
local sVal       to lookDirUp(ship:retrograde:vector, sun:position).
local testPatch  to ship:orbit.
local tVal       to 0.

// Locks
lock steering to sVal.
lock throttle to tVal.


// Main
until false
{
    if testPatch:hasNextPatch 
    {
        set testPatch to testPatch:nextpatch.
    }
    else
    {
        break.
    }
}

until ship:body:name = "Kerbin"
{
    disp_orbit().
    wait 0.01.
}

if testPatch:periapsis > Kerbin:atm:height
{
    disp_main(scriptPath():name).
    disp_msg("Waiting for KSC window or AG10 activation").
    ag10 off.
    until (shipLng >= kscWindow[0] - 2.5 and shipLng <= kscWindow[1] + 2.5) or ag10
    {
        set shipLng to nav_lng_to_degrees(ship:longitude).
        set sVal to lookDirUp(ship:retrograde:vector, sun:position).
        disp_info("Window: " + kscWindow[0] + " - " + kscWindow[1]).
        disp_info2("Current longitude: " + round(shipLng, 2)).
        disp_orbit().
        wait 0.01.
    }
    if warp > 0 set warp to 0.
    wait until kuniverse:timewarp:issettled.

    disp_msg("In KSC window, beyond warp                ").
    until (shipLng >= kscWindow[0] and shipLng <= kscWindow[1]) or ag10
    {
        set shipLng to nav_lng_to_degrees(ship:longitude).
        set sVal to lookDirUp(ship:retrograde:vector, sun:position).
        disp_info("Window: " + kscWindow[0] + " - " + kscWindow[1]).
        disp_info2("Current longitude: " + round(shipLng, 2)).
        disp_orbit().
        wait 0.01.
    }
    if warp > 0 set warp to 0.
    wait until kuniverse:timewarp:issettled.
    disp_info().
    disp_info2().
    ag10 off.

    set tVal to 1.
    disp_msg("Reentry burn").
    until ship:periapsis <= reentryAlt
    {
        set sVal to lookDirUp(ship:retrograde:vector, sun:position).
        disp_orbit().
    }
    set tVal to 0.
}

local startAlt to stagingAlt + 25000.
disp_msg("Waiting until altitude <= " + startAlt).

ag10 off.
ag9 off.
disp_hud("Activate AG10 to warp to starting altitude, or AG9 for manual warp").
local ts to time:seconds + 30.
until ag10 or ag9 or time:seconds > ts
{
    set sVal to lookDirUp(ship:retrograde:vector, sun:position).
    disp_telemetry().
}

if ag9
{
    until ship:altitude <= startAlt
    {
        set sVal to lookDirUp(ship:retrograde:vector, sun:position).
        disp_telemetry().
    }
}
else if ag10
{
    until ship:altitude <= startAlt
    {
        util_warp_down_to_alt(startAlt).
        set sVal to lookDirUp(ship:retrograde:vector, sun:position).
        disp_telemetry().
    }
}

if warp > 0 set warp to 0.
wait until kuniverse:timewarp:issettled.

disp_msg("Beginning reetry procedure").
for c in parachutes 
{
    util_do_event(c, "arm parachute").
}

disp_msg("Waiting until staging altitude: " + stagingAlt).
until ship:altitude <= stagingAlt.
{
    set sVal to body:position.
    disp_telemetry().
}
if warp > 0 set warp to 0.
wait until kuniverse:timewarp:issettled.
set sVal to body:position.
wait 1.
disp_msg("Staging").
//set sVal to ship:prograde:vector + r(0, -90, 0).
until stage:number = 1 
{
    stage.
    wait 2.5.
}
disp_msg("Waiting for reentry interface").

until ship:altitude <= body:atm:height
{
    set sVal to ship:retrograde.
    disp_telemetry().
}
disp_msg("Reentry interface").

until ship:groundspeed <= 1500
{
    set sVal to ship:retrograde.
    disp_telemetry().
}
unlock steering.
disp_msg("Control released").

until alt:radar <= 2500
{
    disp_telemetry().
}
disp_msg("Chute deploy").

until alt:radar <= 5
{
    disp_telemetry().
}