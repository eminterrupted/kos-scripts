@lazyGlobal off.
clearScreen.

runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_vessel").


local commList to ship:modulesNamed("ModuleRTAntenna").
local solarList to ship:modulesNamed("ModuleDeployableSolarPanel").
local sVal to lookDirUp(ship:prograde:vector, body("sun"):position) + r(0, 90, 0).

lock steering to sVal.

ves_activate_antenna(commList).
ves_activate_solar(solarList).

disp_main(scriptPath():name).
until false
{
    set sVal to lookDirUp(ship:prograde:vector, body("sun"):position) + r(0, 90, 0).
    disp_orbit().
}
