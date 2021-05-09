@lazyGlobal off.

parameter tgt.

clearscreen.
clearVecDraws().

runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_mnv").
runOncePath("0:/lib/lib_nav").
runOncePath("0:/lib/lib_util").
runOncePath("0:/lib/lib_vessel").

if tgt:typename = "list" 
{
    set tgt to tgt[0].
}
else if tgt:typename = "string"
{
    set tgt to nav_orbitable(tgt).
}
set target to tgt.

disp_main(scriptPath()).

// Inclination match burn data
local burnData  to "".
local burnDur   to 0.
local burnETA   to 0.
local burnMag   to 0.
local burnVec   to v(0, 0, 0).
local drawVec   to false.
local mnvNode   to node(0, 0, 0, 0).
local mnvTime   to 0.
local tgtInc    to tgt:orbit:inclination.

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
disp_msg("Current inc: " + round(ship:orbit:inclination, 5) + " | Target inc: " + tgtInc).

//Setup burn
set burnData    to mnv_inc_match_burn(ship, tgt:orbit).
set mnvTime     to burnData[0].
set burnMag     to burnData[3].
set burnVec     to burnData[1].
set mnvNode     to burnData[2].
add mnvNode. 

set burnDur     to mnv_burn_dur(burnMag).
set burnETA     to mnvTime - mnv_burn_dur(burnMag / 2).
disp_info("DeltaV remaining: " + round(burnMag, 1)).


// Vecdraw
if drawVec
{
    local burnVDTail to positionAt(ship, mnvTime).
    local burnVD     to vecDraw(
        burnVDTail,
        1000 * burnVec,
        magenta,
        "dV:" + round(burnMag, 1) + " m/s, dur:" + round(burnDur, 1) + "s",
        1,
        true,
        0.1
    ).
    print burnVD.
    // Keep the draw updating the start position until the burn is done.
    set burnVD:startUpdater to { return positionAt(ship, mnvTime). }.
}

// Set up the inclination check delegate
set sVal to lookDirUp(burnVec, sun:position).
lock steering to sVal.

// Perform the maneuver
mnv_exec_node_burn(mnvNode, burnETA, burnDur).
set sVal to lookDirUp(ship:prograde:vector, sun:position).
lock steering to sVal.
remove mnvNode.
clearVecDraws().