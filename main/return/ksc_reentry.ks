@lazyGlobal off.
clearScreen.

// Easy reentry near KSC

//-- Dependencies --//
runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_nav").

//-- Variables --//
local parachutes to ship:modulesNamed("RealChuteModule").
local kscWindow  to list(145, 150).
local reentryAlt to 35000.
local shipLng    to 0.
local stagingAlt to body:atm:height + 15000.
local sVal       to lookDirUp(ship:retrograde:vector, body("sun"):position).
local tVal       to 0.

// Locks
lock steering to sVal.
lock throttle to tVal.


// Main
disp_main(scriptPath():name).
disp_msg("Waiting for KSC window or AG10 activation").
ag10 off.
until (shipLng >= kscWindow[0] - 5 and shipLng <= kscWindow[1] + 5) or ag10
{
    set shipLng to nav_lng_to_degrees(ship:longitude).
    set sVal to lookDirUp(ship:retrograde:vector, body("sun"):position).
    disp_info("Window: " + kscWindow[0] + " - " + kscWindow[1]).
    disp_info2("Current longitude: " + round(shipLng, 2)).
    disp_orbit().
    wait 0.01.
}
if warp > 0 set warp to 0.
wait until kuniverse:timewarp:issettled.

until (shipLng >= kscWindow[0] and shipLng <= kscWindow[1]) or ag10
{
    set shipLng to nav_lng_to_degrees(ship:longitude).
    set sVal to lookDirUp(ship:retrograde:vector, body("sun"):position).
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

disp_msg().
disp_msg("Beginning reetry procedure").
for c in parachutes 
{
    if c:hasEvent("arm parachute") c:doEvent("arm parachute").
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
set sVal to ship:prograde:vector + r(0, -90, 0).
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
    set sVal to ship:retrograde.
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