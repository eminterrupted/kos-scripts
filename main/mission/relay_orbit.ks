@lazyGlobal off.
clearScreen.

runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_vessel").


local commList to ship:modulesNamed("ModuleRTAntenna").
local solarList to ship:modulesNamed("ModuleDeployableSolarPanel").
local dishTgt to kerbin:position.

ves_activate_antenna(commList).
ves_activate_solar(solarList).

set dishTgt to ves_antenna_top_gain(commList):getField("target").
if dishTgt <> "active-vessel"
{
    lock steering to lookDirUp(dishTgt:position, sun:position).
}
else
{
    lock steering to lookDirUp(kerbin:position, sun:position).
}


disp_main(scriptPath():name).
until false
{
    disp_orbit().
}
