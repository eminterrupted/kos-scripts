@lazyGlobal off.
clearScreen.

runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_vessel").


local commList to ship:modulesNamed("ModuleRTAntenna").
local solarList to ship:modulesNamed("ModuleDeployableSolarPanel").

lock steering to lookDirUp(kerbin:position, sun:position) + r(0, 0, 0).

ves_activate_antenna(commList).
ves_activate_solar(solarList).

disp_main(scriptPath():name).
until false
{
    disp_orbit().
}
