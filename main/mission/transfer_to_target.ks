@lazyGlobal off.
clearScreen.

parameter tgt is "Agena-TD JR".

runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_mnv").
runOncePath("0:/lib/lib_nav").
runOncePath("0:/lib/lib_rendezvous").
runOncePath("0:/lib/lib_util").
runOncePath("0:/lib/lib_vessel").
runOncePath("0:/kslib/lib_navigation").

local sVal to lookDirUp(ship:prograde:vector, sun:position).
lock steering to sVal.

if tgt:typename = "string" set tgt to nav_orbitable(tgt).
if not hasTarget set target to nav_orbitable(tgt).

local currentPhase to 0.
//lock  currentPhase to calc_simple_phase_angle(target).
lock  currentPhase to ksnav_phase_angle().

// Calculate the ideal phase angle for transfer
local transferPhase to mod(nav_transfer_phase_angle(target, ship:apoapsis + ship:periapsis / 2) + 360, 360).

disp_main().
disp_msg("Transfer angle to target: " + round(transferPhase, 2) + "   ").
// Calculate the time we should make the transfer at
// Sample the phase change per second
disp_info("Sampling phase change per second").
local p0 to currentPhase.
wait 5.
local phaseRate  to abs(abs(currentPhase) - abs(p0)).
set   phaseRate  to phaseRate / 5.

// Calulate the transfer timestamp
local degreesToTravel to choose currentPhase - transferPhase if currentPhase > transferPhase else (currentPhase + 360) - transferPhase.
local transferEta     to degreesToTravel / phaseRate.
local burnAt          to transferEta + time:seconds.

print "Degrees to travel: " + degreesToTravel at (2, 24).
print "Phase Rate       : " + phaseRate at (2, 25).
print "Time to transfer : " + transferEta at (2, 26).
print "BurnAt           : " + burnAt at (2, 27).

wait 5.

disp_msg().
disp_info().

util_warp_trigger(burnAt - 30, "burn window").

disp_msg("Phase transfer window: " + round(transferPhase, 3)).
until time:seconds >= burnAt - 30
{
    set sVal to ship:prograde.
    disp_info("Current Phase: " + round(currentPhase, 3)).
    disp_info2("Impulse ETA: " + round(burnAt - time:seconds, 1)).
}
if kuniverse:timewarp:warp > 0 kuniverse:timewarp:cancelWarp().

// Get the amount of dv needed to get to the target
local dvNeeded to mnv_dv_hohmann(target:altitude, ship:altitude, ship:body).
disp_msg("dv0: " + round(dvNeeded[0], 2) + " | dv1: " + round(dvNeeded[1], 2)).

// Transfer burn
local burnDur to mnv_burn_dur(dvNeeded[0]).
local halfDur to mnv_burn_dur(dvNeeded[0] / 2).
local burnEta to burnAt - halfDur.
disp_info("Burn ETA : " + round(burnEta, 1) + "          ").
disp_info2("Burn duration: " + round(burnDur, 1) + "          ").
mnv_exec_circ_burn(dvNeeded[0], burnAt, burnEta).

// Circularization burn
// Calculate our burnEta for the circ burn
set burnAt  to time:seconds + (ship:orbit:period / 2) - halfDur.
set burnDur to mnv_burn_dur(dvNeeded[1]).
set halfDur to mnv_burn_dur(dvNeeded[1] / 2).
set burnEta to burnAt - halfDur.
disp_info("Burn ETA : " + round(burnEta, 1) + "          ").
disp_info2("Burn duration: " + round(burnDur, 1) + "          ").
mnv_exec_circ_burn(dvNeeded[1], burnAt, burnEta).

rdv_cancel_velocity(target).