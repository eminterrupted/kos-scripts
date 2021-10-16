@lazyGlobal off.

parameter tgtInc is 7.5,
          tgtLAN is 125,
          nearestNode is false.

clearscreen.
clearVecDraws().

runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_mnv").
runOncePath("0:/lib/lib_nav").
runOncePath("0:/lib/lib_util").
runOncePath("0:/lib/lib_vessel").

disp_main(scriptPath()).

// Creating the new orbit
local targetObt is createOrbit(
    tgtInc, 
    ship:orbit:eccentricity, 
    ship:orbit:semiMajorAxis, 
    tgtLAN,
    ship:orbit:argumentOfPeriapsis,
    ship:orbit:meanAnomalyAtEpoch,
    ship:orbit:epoch,
    ship:body).

// Inclination match burn data
local burnData  to "".
local burnDur   to lex().
local burnETA   to 0.
local burnMag   to 0.
local burnVec   to v(0, 0, 0).
local drawVec   to false.
local mnvNode   to node(0, 0, 0, 0).
local mnvTime   to 0.

//Steering
local sVal is lookDirUp(ship:prograde:vector, sun:position).
lock steering to sVal.

local tVal is 0.
lock throttle to tVal.

//Staging trigger
when ship:availablethrust <= 0.1 and tVal > 0 then
{
    ves_safe_stage().
    preserve.
}

// Main
disp_info("Current inc: " + round(ship:orbit:inclination, 5) + " | Target inc: " + tgtInc).
disp_info2("Current LAN: " + round(ship:orbit:lan, 1) + " | Target LAN: " + tgtLAN).
wait 2.
if util_check_range(ship:orbit:inclination, tgtInc - 1, tgtInc + 1) and util_check_range(ship:orbit:lan, tgtLAN - 2.5, tgtLAN + 2.5)
{
    disp_msg("Orbit already within target error margin").
    disp_hud("Orbit already within target error margin", 1, 5).
}
else
{
    disp_msg("Executing inclination change").
    //Setup burn
    set burnData    to mnv_inc_match_burn(ship, ship:orbit, targetObt, nearestNode).
    set mnvTime     to burnData[0].
    set burnMag     to burnData[3].
    set burnVec     to burnData[1].
    set mnvNode     to burnData[2].
    add mnvNode. 

    // set burnDur     to mnv_burn_dur(burnMag).
    // local fullDur   to burnDur["Full"].
    // local halfDur   to burnDur["Half"].
    // set burnETA     to mnvTime - halfDur.
    disp_info("DeltaV remaining: " + round(burnMag, 1)).


    // Vecdraw
    // if drawVec
    // {
    //     local burnVDTail to positionAt(ship, mnvTime).
    //     local burnVD     to vecDraw(
    //         burnVDTail,
    //         1000 * burnVec,
    //         magenta,
    //         "dV:" + round(burnMag, 1) + " m/s, dur:" + round(fullDur, 1) + "s",
    //         1,
    //         true,
    //         0.1
    //     ).
    //     print burnVD.
    //     // Keep the draw updating the start position until the burn is done.
    //     set burnVD:startUpdater to { return positionAt(ship, mnvTime). }.
    // }

    set sVal to lookDirUp(burnVec, sun:position).
    lock steering to sVal.

    // Perform the maneuver
    //mnv_exec_node_burn(mnvNode, burnETA, fullDur).
    mnv_exec_node_burn(mnvNode).
    set sVal to lookDirUp(ship:prograde:vector, sun:position).
    lock steering to sVal.
    remove mnvNode.
    clearVecDraws().
}

disp_msg(scriptPath() + " completed").
disp_info().
disp_info2().