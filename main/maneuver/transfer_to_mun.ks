@lazyGlobal off.
clearScreen.

parameter tgt is "Mun",
          altPadding to 225000.

runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_mnv").
runOncePath("0:/lib/lib_nav").
runOncePath("0:/lib/lib_rendezvous").
runOncePath("0:/lib/lib_util").
runOncePath("0:/lib/lib_vessel").
//runOncePath("0:/kslib/lib_navigation").

disp_main(scriptPath()).

local sVal to lookDirUp(ship:prograde:vector, sun:position).
lock steering to sVal.

if not hasTarget 
{
    if tgt:typename = "string" set tgt to nav_orbitable(tgt).
    set target to nav_orbitable(tgt).
}
else
{
    set tgt to target.
}
set altPadding to altPadding + target:radius.

local tgtAlt to target:altitude - target:soiradius + altPadding.
local currentPhase to 0.
//lock  currentPhase to calc_simple_phase_angle(target).
lock  currentPhase to mod(360 + ksnav_phase_angle(), 360).

// Calculate the ideal phase angle for transfer
local transferPhase to mod(nav_transfer_phase_angle(target, ship:apoapsis + ship:periapsis / 2) + 360, 360).

disp_msg("Transfer angle to target: " + round(transferPhase, 2) + "   ").
// Calculate the time we should make the transfer at
// Sample the phase change per second
disp_info("Sampling phase change per second").
local p0 to currentPhase.
wait 1.
local phaseRate  to abs(abs(currentPhase) - abs(p0)).
set   phaseRate  to phaseRate.

// Calulate the transfer timestamp
local degreesToTravel to choose transferPhase - currentPhase if transferPhase <= currentPhase else currentPhase + (360 - transferPhase).
local transferEta     to abs(degreesToTravel / phaseRate).
local burnAt          to transferEta + time:seconds.

print "Degrees to travel: " + round(degreesToTravel, 5) at (2, 24).
print "Phase Rate       : " + round(phaseRate, 5) at (2, 25).
print "Time to transfer : " + round(transferEta) at (2, 26).
print "BurnAt           : " + round(burnAt) at (2, 27).

disp_msg().
disp_info().

// Get the amount of dv needed to get to the target
local dvNeeded to mnv_dv_hohmann(ship:altitude, tgtAlt, ship:body).
disp_msg("dv0: " + round(dvNeeded[0], 2) + " | dv1: " + round(dvNeeded[1], 2)).

// Transfer burn
local burnDur to mnv_burn_dur(dvNeeded[0]).
local halfDur to mnv_burn_dur(dvNeeded[0] / 2).
local burnEta to burnAt - halfDur.
disp_info("Burn ETA : " + round(burnEta, 1) + "          ").
disp_info2("Burn duration: " + round(burnDur, 1) + "          ").
mnv_exec_circ_burn(dvNeeded[0], burnAt, burnEta).

if ship:orbit:hasnextpatch 
{
    disp_msg("Transfer complete!").
    disp_info("Pe at target: " + round(ship:orbit:nextPatch:periapsis)).

    until ship:body = tgt
    {
        disp_info2("Time to SOI change: " + ship:orbit:nextpatcheta).
        disp_orbit().
    }

    disp_info2().
    disp_info2("Arrived at " + tgt:name + " SOI").
}