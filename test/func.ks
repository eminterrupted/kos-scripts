@lazyGlobal off.
clearScreen.

runOncePath("0:/lib/lib_vessel").

// ves_auto_capacitor().
// until false 
// {
//     wait 0.01.
// }

local commList to ship:modulesNamed("ModuleRTAntenna").
local dishTgt to kerbin:position.

set dishTgt to ves_antenna_top_gain(commList):getField("target").
print dishTgt.
unlock steering.
lock steering to lookDirUp(dishTgt:position, sun:position).
until false 
{
    wait 1.
}