@lazyGlobal off.
clearScreen.

parameter tgtParam is "Mun",
          tgtAlt is 150000,
          altPadding to 50000.

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
local dvNeeded          to list().
local halfDur           to 0.
local mnv               to node(0, 0, 0, 0).
local tgtBodyAlt        to 0.
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

local sVal to lookDirUp(ship:facing:forevector, sun:position).
lock steering to sVal.

// Staging trigger
when ship:availableThrust <= 0.1 and throttle > 0 then 
{
    ves_safe_stage().
    preserve.
}

// Main
if hasNode and not ship:orbit:hasnextpatch remove nextNode.
wait 1.
if not hasNode
{
    lock currentPhase to mod(360 + ksnav_phase_angle(), 360).

    // Calculate the ideal phase angle for transfer
    set transferPhase to nav_transfer_phase_angle(target, ship:orbit:semimajoraxis - ship:body:radius).

    disp_msg("Transfer angle to target: " + round(transferPhase, 2) + "   ").

    // Calulate the transfer timestamp
    local angVelSt      to nav_ang_velocity(ship, target:body).
    local angVelTgt     to nav_ang_velocity(target, target:body).
    local angVelPhase   to angVelSt - angVelTgt.
    set burnEta         to (currentPhase - transferPhase) / angVelPhase.
    set burnAt          to choose burnEta + time:seconds if burnEta > 0 else burnEta + time:seconds + ship:orbit:period.

    print "Target           : " + target + "   " at (2, 23).
    
    print "Degrees to travel: " + round(mod((360 + currentPhase) - transferPhase, 360), 5) at (2, 24).
    print "Time to transfer : " + round(burnEta) at (2, 25).
    print "BurnAt           : " + round(burnAt) at (2, 26).

    disp_msg().
    disp_info().

    // Get the amount of dv needed to get to the target
    set tgtBodyAlt to target:altitude - ship:body:radius + altPadding.
    set dvNeeded to mnv_dv_bi_elliptic(ship:periapsis, ship:apoapsis, tgtBodyAlt, tgtBodyAlt, tgtBodyAlt).
    print "Transfer dV      : " + round(dvNeeded[0], 2) + "m/s     " at (2, 27).
    print "Arrival  dV      : " + round(dvNeeded[1], 2) + "m/s     " at (2, 28).

    // Add the maneuver node
    set mnv to mnv_opt_transfer_node(node(burnAt, 0, 0, dvNeeded[0]), target, tgtAlt, 1).
    add mnv.
}

if hasNode
{
    // Transfer burn
    set mnv to nextNode.
    set burnAt  to nextNode:time.
    set burnDur to mnv_staged_burn_dur(nextNode:deltav:mag).
    set halfDur to mnv_staged_burn_dur(nextNode:deltav:mag / 2).
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