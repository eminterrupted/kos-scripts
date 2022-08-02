@lazyGlobal off.
clearScreen.

parameter param is list().

runOncePath("0:/lib/burnCalc").
runOncePath("0:/lib/disp").
runOncePath("0:/lib/mnv").
runOncePath("0:/lib/nav").
runOncePath("0:/lib/util").
runOncePath("0:/lib/vessel").

DispMain(scriptPath()).

local burnAt            to 0.
local burnEta           to 0.
local currentPhase      to 0.
local dv                to list().
local mnv               to node(0, 0, 0, 0).
local orientation       to "pro-sun".
local tgtAlt            to 0.
local transferPhase     to 0.

// Param validation
if param:length > 0
{
    set target      to GetOrbitable(param[0]).
    if param:length > 1 set orientation to param[1].
}
else
{
    if not hasTarget 
    {
        OutTee("No target selected", 2).
        print 1 / 0.
    }
}

local sVal to GetSteeringDir(orientation).
lock steering to sVal.

// Staging trigger
ArmAutoStaging().

// Main
if hasNode and not ship:orbit:hasnextpatch remove nextNode.
wait 1.
if not hasNode
{
    lock currentPhase to mod(360 + KSNavPhaseAng(), 360).

    // Calculate the ideal phase angle for transfer
    set transferPhase to GetTransferPhase(target, ship:orbit:semimajoraxis - ship:body:radius).
    OutMsg("Current phase: " + round(currentPhase, 2)).
    OutInfo("Transfer angle to target: " + round(transferPhase, 2) + "   ").

    // Calulate the transfer timestamp
    local angVelSt      to GetAngVelocity(ship, target:body).
    local angVelTgt     to GetAngVelocity(target, target:body).
    local angVelPhase   to angVelSt - angVelTgt.
    set burnEta         to (currentPhase - transferPhase) / angVelPhase.
    if burnEta < 0 set burnEta to burnEta + ship:orbit:period.
    set burnAt          to choose burnEta + time:seconds if burnEta > 0 else burnEta + time:seconds + ship:orbit:period.

    print "Target           : " + target + "   " at (2, 23).
    
    print "Degrees to travel: " + round(mod((360 + currentPhase) - transferPhase, 360), 5) at (2, 24).
    print "Time to transfer : " + round(burnEta) at (2, 25).
    print "BurnAt           : " + timeSpan(round(burnAt)):full at (2, 26).

    // Get the amount of dv needed to get to the target
    set tgtAlt to target:altitude.
    set dv to CalcDvBE(ship:periapsis, ship:apoapsis, tgtAlt, tgtAlt, tgtAlt).
    print "Transfer dV      : " + round(dv[0], 2) + "m/s     " at (2, 27).
    print "Arrival  dV      : " + round(dv[1], 2) + "m/s     " at (2, 28).

    // Add the maneuver node
    set mnv to node(burnAt, 0, 0, dv[0]).
    add mnv.
}

OutMsg().
OutInfo().

if hasNode
{
    // Transfer burn
    // set mnv to nextNode.
    // set burnAt  to nextNode:time.
    // set burnDur to mnv_burn_dur_next(nextNode:deltav:mag).
    // set fullDur to burnDur["Full"].
    // set halfDur to burnDur["Half"].
    // set burnEta to burnAt - halfDur.
    // disp_info("Burn ETA : " + round(burnEta, 1) + "          ").
    // disp_info2("Burn duration: " + round(fullDur, 1) + "          ").
    //ExecNodeBurn(nextNode).

    if ship:orbit:hasnextpatch 
    {
        OutMsg("Transfer complete!").
        OutInfo("Pe at target: " + round(ship:orbit:nextPatch:periapsis)).
    }
}