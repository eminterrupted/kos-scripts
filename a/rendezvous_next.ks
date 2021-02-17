@lazyGlobal off.

parameter rdvTgt is target.

runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/lib_log").
runOncePath("0:/lib/lib_display").
runOncePath("0:/lib/lib_rendezvous").
runOncePath("0:/lib/lib_warp").

local lastDist  to 0.
local safeDist  to 100.
local startDist to 1000.
local tStamp    to time:seconds + eta:apoapsis - 300.

if not hasTarget set target to orbitable(rdvTgt).

out_msg("Warping to approach interface (" + startDist + ")").
warp_to_timestamp(tStamp).
out_msg("Awaiting closest approach or ideal startDist: " + startDist).
until rdvTgt:distance <= startDist
{
    set lastDist to rdvTgt:distance.
    update_display().
    disp_rendezvous(rdvTgt).
    wait 0.01.
    if rdvTgt:distance > lastDist break.
}
out_msg().
disp_clear_block("rdv").

until rdvTgt:distance <= safeDist 
{
    out_msg("Killing relative velocity").
    rdv_cancel_vel(rdvTgt).
    out_msg("Making approach").
    rdv_approach(rdvTgt, min(10, rdvTgt:distance / 100)).
    out_msg("Awaiting nearest approach").
    rdv_await_nearest_approach(rdvTgt, safeDist).
}
rdv_cancel_vel(rdvTgt).

out_msg("Ready for docking").