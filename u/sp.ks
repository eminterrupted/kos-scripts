@lazyGlobal off.

parameter _tgt is "Megfrid's Debris".

runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/lib_core").
runOncePath("0:/lib/nav/lib_nav").
runOncePath("0:/lib/nav/lib_deltav").
runOncePath("0:/lib/nav/lib_mnv").
runOncePath("0:/lib/nav/lib_calc_mnv").
runOncePath("0:/lib/nav/lib_node").
runOncePath("0:/lib/nav/lib_rendezvous").

set target to orbitable(_tgt).

out_msg("Checking target phase").

local transObj to get_transfer_obj().
print transObj.