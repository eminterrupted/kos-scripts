@lazyGlobal off.

parameter _tgtInclination,
          _tgtLongitudeAscendingNode is ship:orbit:lan.

clearscreen.

runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_mnv").
runOncePath("0:/lib/lib_nav").
runOncePath("0:/lib/lib_util").
runOncePath("0:/lib/lib_vessel").

disp_main(scriptPath()).

// Creating the new orbit
local targetObt is createOrbit(
    _tgtInclination, 
    ship:orbit:eccentricity, 
    ship:orbit:semiMajorAxis, 
    _tgtLongitudeAscendingNode,
    ship:orbit:argumentOfPeriapsis,
    ship:orbit:meanAnomalyAtEpoch,
    ship:orbit:epoch,
    ship:body).

// Inclination match burn data
local burnData   to "".
local burnVector to v(0, 0, 0).
local burnETA    to 0.
local mnvNode    to node(0, 0, 0, 0).
local mnvTime    to 0.

//Steering
local sVal is lookDirUp(ship:prograde:vector, sun:position).
lock steering to sVal.

local tVal is 0.
lock throttle to tVal.

//Staging trigger
when ship:availableThrust < 0.1 and tVal > 0 then 
{
    ves_safe_stage().
    preserve.
}

// Main
disp_msg("Current inc: " + round(ship:orbit:inclination, 5) + " | Target inc: " + _tgtInclination).

//Setup burn
set burnData    to mnv_inc_match_burn(ship, targetObt).
set mnvTime     to burnData[0].
set burnVector  to burnData[1].
set burnETA     to mnvTime - mnv_burn_dur(burnVector:mag / 2).
disp_info("DeltaV remaining: " + round(burnVector:mag, 1)).

set sVal to lookDirUp(burnVector, sun:position).
lock steering to sVal.
wait until ves_settled().

// Perform the maneuver
mnv_exec_vec_burn(burnVector, mnvTime, burnETA).