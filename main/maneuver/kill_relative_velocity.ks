@lazyGlobal off.
clearScreen.

// Assumes a target is set

// Dependencies
runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_rendezvous").
runOncePath("0:/lib/lib_util").

disp_main(scriptPath()).

if not hasTarget 
{
    print "no target set".
    print 1 / 0.
}

local lastDist  to 999999.
lock  relVel to target:velocity:orbit - ship:velocity:orbit.
lock maxAcc to (0.000000001 + ship:availablethrust) / ship:mass.
local safeDist  to 100.
local startDist to 250.

lock steering to lookdirup(relVel, sun:position).
ag10 off.
disp_msg("Awaiting ideal startDist, closest approach, or AG10").
until target:distance <= startDist or ag10
{
    set lastDist to target:distance.
    disp_info("Target distance: " + round(lastDist, 2)).
    wait 0.1.
    if target:distance > lastDist break.
}
ag10 off.

until target:distance <= safeDist 
{
    rdv_cancel_velocity(target).
    disp_msg("Killing relative velocity").
    disp_msg("Making approach").
    rdv_approach_target(target, min(10, target:distance / 100)).
    disp_msg("Awaiting nearest approach").
    rdv_await_nearest_approach(target, safeDist).
}
rdv_cancel_velocity(target).

disp_msg("Ready for docking").