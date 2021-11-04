@lazyGlobal off.
clearScreen.

// Easy reentry near KSC

//-- Dependencies --//
runOncePath("0:/lib/disp").
runOncePath("0:/lib/nav").
runOncePath("0:/lib/util").

disp_main(scriptPath()).

//-- Variables --//
local parachutes to ship:modulesNamed("RealChuteModule").
local kscWindow  to list(150, 152.5).
local reentryAlt to 40000.
local shipLng    to 0.
local stagingAlt to ship:body:atm:height + 50000.
local sVal       to lookDirUp(body:position, sun:position).
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
        if testPatch:nextPatch:body:name = "Kerbin" or testPatch:nextPatch:body:name = "Mun" or testPatch:nextPatch:body:name = "Minmus"
        {
            set testPatch to testPatch:nextpatch.
        }
        else
        {
            break.
        }
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

if testPatch:periapsis >= Kerbin:atm:height
{
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

local startAlt to stagingAlt + 10000.
disp_msg("Waiting until altitude <= " + startAlt).

ag10 off.
disp_hud("Activate AG10 to warp to starting altitude").
on ag10
{
    until ship:altitude <= startAlt
    {
        util_warp_down_to_alt(startAlt).
        set sVal to lookDirUp(ship:retrograde:vector, sun:position).
        disp_telemetry().
    }
}

until ship:altitude <= startAlt
{
    set sVal to lookDirUp(ship:retrograde:vector, sun:position).
    disp_telemetry().
}


if warp > 0 set warp to 0.
wait until kuniverse:timewarp:issettled.

disp_msg("Beginning reetry procedure").
if parachutes:length > 0 
{
    if parachutes[0]:name = "RealChuteModule" 
    {
        for c in parachutes 
        {
            util_do_event(c, "arm parachute").
        }
    }
    else if parachutes[0]:name = "ModuleParachute"
    {
        when parachutes[0]:getField("safe to deploy?") = "Safe" then 
        {
            for c in parachutes
            {
                util_do_event(c, "deploy chute").
            }
        }
    }
}

set sVal to body:position.
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
    set sVal to ship:srfRetrograde.
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