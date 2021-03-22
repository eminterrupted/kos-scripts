@lazyGlobal off.

parameter tgt.

clearscreen.
clearVecDraws().

runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_mnv").
runOncePath("0:/lib/lib_nav").
runOncePath("0:/lib/lib_util").
runOncePath("0:/lib/lib_vessel").

disp_main(scriptPath()).

if not hasTarget 
{
    if tgt:typename = "string" set tgt to nav_orbitable(tgt).
    set target to nav_orbitable(tgt).
}
else
{
    set tgt to target.
}

// Getting the target orbit
local targetObt is tgt:orbit.

// Inclination match burn data
local burnData  to "".
local burnDur   to 0.
local burnETA   to 0.
local burnVec   to v(0, 0, 0).
local drawVec   to true.
local mnvTime   to 0.

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
disp_msg("Current inc: " + round(ship:orbit:inclination, 5) + " | Target inc: " + targetObt:inclination).

//Setup burn
set burnData    to mnv_inc_match_burn(ship, targetObt).
set mnvTime     to burnData[0].
set burnVec     to burnData[1].

set burnDur     to mnv_burn_dur(burnVec:mag).
set burnETA     to mnvTime - mnv_burn_dur(burnVec:mag / 2).
disp_info("DeltaV remaining: " + round(burnVec:mag, 1)).


// Vecdraw
if drawVec
{
    local burnVDTail to positionAt(ship, mnvTime).
    local burnVD     to vecDraw(
        burnVDTail,
        1000 * burnVec,
        magenta,
        "dV:" + round(burnVec:mag, 1) + " m/s, dur:" + round(burnDur, 1) + "s",
        1,
        true,
        0.1
    ).
    print burnVD.

    // Keep the draw updating the start position until the burn is done.
    set burnVD:startUpdater to { return positionAt(ship, mnvTime). }.
}

set sVal to lookDirUp(burnVec, sun:position).
lock steering to sVal.
wait until ves_settled().

// Perform the maneuver
mnv_exec_vec_burn(burnVec, mnvTime, burnETA).
clearVecDraws().