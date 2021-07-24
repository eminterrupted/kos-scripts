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
local safeDist  to 100.
local startDist to 1000.

lock steering to lookdirup(relVel, sun:position).
disp_msg("Awaiting ideal startDist or closest approach").
until target:distance <= startDist
{
    set lastDist to target:distance.
    disp_info("Target distance: " + round(lastDist)).
    wait 0.1.
    if target:distance > lastDist break.
}

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