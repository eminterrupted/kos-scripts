// Script to allow vessels to enter a body's atmosphere.
// Terminates once the vessel is moving slow enough through the 
// atmosphere

@lazyGlobal off.
clearScreen.

// Easy reentry near KSC

//-- Dependencies --//
runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_nav").
runOncePath("0:/lib/lib_util").

disp_main(scriptPath()).

//-- Variables --//
local fairings to list().
local hasFairings to false.
local parachutes to ship:modulesNamed("RealChuteModule").
local reentryAlt to ship:body:atm:height * 0.525.
local stagingAlt to ship:body:atm:height + 50000.
local testPatch  to ship:orbit.

// Locks
local sVal       to lookDirUp(body:position, sun:position).
lock steering to sVal.
local tVal       to 0.
lock throttle to tVal.

// Fairing check
if ship:partsTaggedPattern("landingFairing"):length > 0 or ship:partsTaggedPattern("reentryFairing"):length > 0
{
    set hasFairings to true.
    for m in ship:modulesNamed("ProceduralFairingDecoupler")
    {
        fairings:add(m).
    }

    for m in ship:modulesNamed("ModuleProceduralFairing")
    {
        fairings:add(m).
    }

    for m in ship:modulesNamed("ModuleSimpleAdjustableFairing")
    {
        fairings:add(m).
    }
}

// Main

if not ship:body:atm:exists
{
    disp_tee("No atmosphere present on " + ship:body:name + "!", 2).
    print 1 / 0.
}

if testPatch:periapsis >= body:atm:height
{
    disp_msg("Waiting for AG10 activation").
    ag10 off.
    until ag10 or ship:altitude <= body:atm:height
    {
        disp_info("Lattitude: " + round(ship:latitude, 2)).
        disp_info2("Longitude: " + round(ship:longitude, 2)).
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
// Stage once to get rid of transfer stage
ves_safe_stage().
wait 1.
// Uncomment if two stages are necessary
ves_safe_stage().
wait 1.

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

until ship:groundspeed <= 500
{
    disp_telemetry().
}
disp_msg("Deploying fairings").
if hasFairings ves_jettison_fairings(fairings).

disp_tee("Unpowered entry complete").