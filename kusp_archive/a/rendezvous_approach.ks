@lazyGlobal off.

parameter rdvTgt is target.

runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/lib_log").
runOncePath("0:/lib/lib_display").
runOncePath("0:/lib/lib_rendezvous").
runOncePath("0:/lib/lib_warp").

if rdvTgt:typename = "string" set rdvTgt to orbitable(rdvTgt).
if not hasTarget set target to rdvTgt.

lock  relVel to rdvTgt:velocity:orbit - ship:velocity:orbit.

local lastDist  to 999999.
local safeDist  to 100.
local startDist to 1000.
local tStamp    to choose time:seconds + eta:apoapsis - 180 if ship:altitude < rdvTgt:altitude else time:seconds + eta:periapsis - 180.

out_msg("Warping to approach interface (" + startDist + ")").
warp_to_timestamp(tStamp).
lock steering to lookdirup(relVel, sun:position).
out_msg("Awaiting closest approach or ideal startDist: " + startDist).
until rdvTgt:distance <= startDist
{
    set lastDist to rdvTgt:distance.
    update_display().
    disp_rendezvous(rdvTgt).
    wait 0.25.
    if rdvTgt:distance > lastDist break.
}
disp_clear_block("rdv").
out_msg().

until rdvTgt:distance <= safeDist 
{
    out_msg("Killing relative velocity").
    rdv_cancel_velocity(rdvTgt).
    out_msg("Making approach").
    rdv_approach_target(rdvTgt, min(10, rdvTgt:distance / 100)).
    out_msg("Awaiting nearest approach").
    rdv_await_nearest_approach(rdvTgt, safeDist).
}
rdv_cancel_velocity(rdvTgt).
disp_clear_block("rdv").

out_msg("Ready for docking").