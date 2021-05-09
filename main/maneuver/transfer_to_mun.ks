@lazyGlobal off.
clearScreen.

parameter tgtParam is "Mun",
          tgtAlt is 30000,
          altPadding to 0.

runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_mnv").
runOncePath("0:/lib/lib_nav").
runOncePath("0:/lib/lib_rendezvous").
runOncePath("0:/lib/lib_util").
runOncePath("0:/lib/lib_vessel").
//runOncePath("0:/kslib/lib_navigation").

disp_main(scriptPath()).

local burnAt            to 0.
local burnDur           to 0.
local burnEta           to 0.
local currentPhase      to 0.
local degreesToTravel   to 0.
local dvNeeded          to list().
local halfDur           to 0.
local mnv               to node(0, 0, 0, 0).
local phaseRate         to 0.
local tgtBodyAlt        to 0.
local transferEta       to 0.
local transferPhase     to 0.


// Param validation
if tgtParam:typeName = "list"
{
    set target      to nav_orbitable(tgtParam[0]).
    set tgtAlt      to tgtParam[1].
    set altPadding  to tgtParam[2].
}
else
{
    if not hasTarget 
    {
        set target  to nav_orbitable(tgtParam).
    }
}

local sVal to lookDirUp(ship:prograde:vector, sun:position).
lock steering to sVal.

// Staging trigger
when ship:maxThrust <= 0.1 and throttle > 0 then 
{
    ves_safe_stage().
    preserve.
}

// Main
//
//lock  currentPhase to calc_simple_phase_angle(target).
if not hasNode {
    lock currentPhase to mod(360 + ksnav_phase_angle(), 360).

    // Calculate the ideal phase angle for transfer
    set transferPhase to mod(nav_transfer_phase_angle(target, ship:apoapsis + ship:periapsis / 2) + 360, 360).

    disp_msg("Transfer angle to target: " + round(transferPhase, 2) + "   ").
    // Calculate the time we should make the transfer at
    // Sample the phase change per second
    disp_info("Sampling phase change per second").
    local p0 to currentPhase.
    local ts to time:seconds + 3.
    until time:seconds >= ts
    {
        disp_info2("Sample time remaining: " + round(ts - time:seconds)).
    }
    set phaseRate  to abs(abs(currentPhase) - abs(p0)) / 3.
    disp_info2().

    // Calulate the transfer timestamp
    set degreesToTravel to choose transferPhase - currentPhase if transferPhase <= currentPhase else currentPhase + (360 - transferPhase).
    set transferEta     to abs(degreesToTravel / phaseRate).
    set burnAt          to transferEta + time:seconds.

    print "Degrees to travel: " + round(degreesToTravel, 5) at (2, 24).
    print "Phase Rate       : " + round(phaseRate, 5) at (2, 25).
    print "Time to transfer : " + round(transferEta) at (2, 26).
    print "BurnAt           : " + round(burnAt) at (2, 27).

    disp_msg().
    disp_info().

    // Get the amount of dv needed to get to the target
    //local dvNeeded to mnv_dv_hohmann(ship:altitude, tgtAlt, ship:body).
    set degreesToTravel to choose transferPhase - currentPhase if transferPhase <= currentPhase else currentPhase + (360 - transferPhase).
    set transferEta     to abs(degreesToTravel / phaseRate).
    //local tgtAlt to target:altitude - target:soiradius + altPadding.
    set tgtBodyAlt to target:altitude + ship:body:radius + altPadding.
    set dvNeeded to mnv_dv_bi_elliptic(ship:periapsis, ship:apoapsis, tgtBodyAlt, tgtBodyAlt, tgtBodyAlt).
    disp_msg("dv0: " + round(dvNeeded[0], 2) + " | dv1: " + round(dvNeeded[1], 2)).

    // Add the maneuver node
    set mnv to mnv_opt_transfer_node(node(burnAt, 0, 0, dvNeeded[0]), target, tgtAlt, 1).
    add mnv.
}

if hasNode
{
    // Transfer burn
    set burnAt  to mnv:time.
    set burnDur to mnv_burn_dur(dvNeeded[0]).
    set halfDur to mnv_burn_dur(dvNeeded[0] / 2).
    set burnEta to burnAt - halfDur.
    disp_info("Burn ETA : " + round(burnEta, 1) + "          ").
    disp_info2("Burn duration: " + round(burnDur, 1) + "          ").
    mnv_exec_node_burn(mnv, burnEta, burnDur).

    if ship:orbit:hasnextpatch 
    {
        disp_msg("Transfer complete!").
        disp_info("Pe at target: " + round(ship:orbit:nextPatch:periapsis)).
    }
}