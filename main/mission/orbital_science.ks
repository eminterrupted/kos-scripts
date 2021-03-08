@lazyGlobal off.

runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_sci").
runOncePath("0:/lib/lib_util").
runOncePath("0:/lib/lib_vessel").

// Flags
local recover to true.
local stow    to false.
local sciList   to sci_modules().

lock steering to lookDirUp(ship:prograde:vector, body("sun"):position).

ves_activate_antenna().
ves_activate_solar().



sci_deploy_list(sciList).

if recover {
    sci_recover_list(sciList).
}
else if stow
{
    sci_stow_experiments().
}