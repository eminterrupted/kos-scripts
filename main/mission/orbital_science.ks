@lazyGlobal off.

runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_sci").
runOncePath("0:/lib/lib_util").

local recover to false.
local stow    to true.
local sciList to sci_modules().

lock steering to lookDirUp(ship:prograde:vector, body("sun"):position).

for comm in ship:modulesNamed("ModuleRTAntenna")
{
    util_do_event(comm, "activate").
}

sci_deploy_list(sciList).

if recover {
    sci_recover_list(sciList).
}
else if stow
{
    sci_stow_experiments().
}