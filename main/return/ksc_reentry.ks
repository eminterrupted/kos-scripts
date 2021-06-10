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

local startAlt to kerbin:atm:height + 17500.
disp_msg("Waiting until altitude <= " + startAlt).
//util_warp_altitude(startAlt).
until ship:altitude <= startAlt
{
    set sVal to lookDirUp(ship:retrograde:vector, sun:position).
    disp_telemetry().
}
if warp > 0 set warp to 0.
wait until kuniverse:timewarp:issettled.

disp_msg("Beginning reetry procedure").
for c in parachutes 
{
    util_do_event(c, "arm parachute").
}

disp_msg("Waiting until staging altitude").
until ship:altitude <= Kerbin:atm:height + 10000
{
    set sVal to lookDirUp(ship:retrograde:vector, sun:position) + r(0, 90, 0).
    disp_telemetry().
}
if warp > 0 set warp to 0.
wait until kuniverse:timewarp:issettled.

disp_msg("Staging").
//set sVal to ship:prograde:vector + r(0, -90, 0).
wait 5.
until stage:number = 1 
{
    stage.
    wait 5.
}
disp_msg("Waiting for reentry interface").

until ship:altitude <= body:atm:height
{
    set sVal to ship:retrograde.
    disp_telemetry().
}
disp_msg("Reentry interface").

until ship:groundspeed <= 1000
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