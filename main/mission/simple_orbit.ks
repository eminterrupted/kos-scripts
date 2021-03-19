
@lazyGlobal off.
clearScreen.

runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_vessel").
runOncePath("0:/lib/lib_util").

local sVal to lookDirUp(ship:prograde:vector, body("sun"):position).

lock steering to sVal.

ves_activate_solar().
ves_activate_antenna().

disp_main(scriptPath():name).
ag10 off.

hudtext("Activate AG10 to end Simple Orbit sequence", 25, 2, 20, green, false).
until ag10
{
    set sVal to lookDirUp(ship:prograde:vector, body("sun"):position).
    disp_orbit().
}
ag10 off.
