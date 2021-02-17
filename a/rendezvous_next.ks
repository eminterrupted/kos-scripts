@lazyGlobal off.

parameter rdvTgt is target.

runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/lib_log").
runOncePath("0:/lib/lib_display").
runOncePath("0:/lib/lib_rendezvous").

local safeDist  to 100.
local startDist to 5000.

if not hasTarget set target to orbitable(rdvTgt).

out_msg("Waiting until approach interface (" + startDist + ")").
until rdvTgt:distance < startDist
{
    update_display().
    disp_rendezvous(rdvTgt).
}
out_msg().
disp_clear_block("rdv").

until rdvTgt:distance <= safeDist 
{
    out_msg("Killing relative velocity").
    rdv_cancel_vel(rdvTgt).
    out_msg("Making approach").
    rdv_approach(rdvTgt, max(10, rdvTgt:distance / 100)).
    out_msg("Awaiting nearest approach").
    rdv_await_nearest(rdvTgt, safeDist).
}
rdv_cancel_vel(rdvTgt).

out_msg("Ready for docking").