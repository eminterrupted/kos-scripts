@lazyGlobal off.
clearScreen.

// Easy reentry near KSC

//-- Dependencies --//
runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_nav").


//-- Variables --//
local parachutes to ship:modulesNamed("RealChuteModule").
local kscWindow  to list(135, 137.5).
local reentryAlt to 35000.
local shipLng    to 0.
local stagingAlt to body:atm:height + 15000.
local sVal       to lookDirUp(ship:retrograde:vector, body("sun"):position).
local tVal       to 0.

// Locks
lock steering to sVal.
lock throttle to tVal.

// Main
disp_main().
disp_msg("Waiting for KSC reentry window").
until shipLng >= kscWindow[0] - 5 and shipLng <= kscWindow[1] + 5
{
    set shipLng to lng_to_degrees(ship:longitude).
    set sVal to lookDirUp(ship:retrograde:vector, body("sun"):position).
    disp_info("Window: " + kscWindow[0] + " - " + kscWindow[1]).
    disp_info2("Current longitude: " + round(shipLng, 2)).
    disp_orbit().
    wait 0.01.
}
if warp > 0 set warp to 0.

until shipLng >= kscWindow[0] and shipLng <= kscWindow[1]
{
    set shipLng to lng_to_degrees(ship:longitude).
    set sVal to lookDirUp(ship:retrograde:vector, body("sun"):position).
    disp_info("Window: " + kscWindow[0] + " - " + kscWindow[1]).
    disp_info2("Current longitude: " + round(shipLng, 2)).
    disp_orbit().
    wait 0.01.
}
if warp > 0 set warp to 0.
disp_info().
disp_info2().

disp_msg().
disp_msg("Entering reentry window").
for c in parachutes 
{
    c:doEvent("arm parachute").
}

set tVal to 1.
disp_msg().
disp_msg("Reentry burn").
until ship:periapsis <= reentryAlt
{
    set sVal to lookDirUp(ship:retrograde:vector, body("sun"):position).
    disp_telemetry().
}
set tVal to 0.
disp_msg().
disp_msg("Waiting until staging altitude: " + stagingAlt).

until ship:altitude <= stagingAlt
{
    set sVal to lookDirUp(ship:retrograde:vector, body("sun"):position).
    disp_telemetry().
}
if warp > 0 set warp to 0.
wait 5.

disp_msg().
disp_msg("Staging").
set sVal to lookDirUp(ship:prograde:vector + r(0, -90, 0), body("sun"):position).
wait 5.
until stage:number = 1 
{
    stage.
    wait 5.
}
disp_msg().
disp_msg("Waiting until reentry interface").

until ship:altitude <= body:atm:height
{
    set sVal to lookDirUp(ship:retrograde:vector, body("sun"):position).
    disp_telemetry().
}
disp_msg().
disp_msg("Reentry interface").

until ship:groundspeed <= 1000
{
    set sVal to ship:retrograde.
    disp_telemetry().
}
unlock steering.
disp_msg().
disp_msg("Control released").

until alt:radar <= 2500
{
    disp_telemetry().
}
disp_msg().
disp_msg("Chute deploy").

until alt:radar <= 700
{
    disp_telemetry().
}
disp_msg().
disp_msg("Awaiting touchdown").

until alt:radar <= 5
{
    disp_telemetry().
}