@lazyGlobal off.
clearScreen.

runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_vessel").

local commList to ship:modulesNamed("ModuleRTAntenna").
local dishTgt to body:position.
local primaryDish to ves_antenna_top_gain(commList).
local solarList to ship:modulesNamed("ModuleDeployableSolarPanel").

ves_activate_antenna(commList).
ves_activate_solar(solarList).

for m in commList 
{
    if m:part:tag = "primaryDish" set primaryDish to m.
}

if dishTgt  <> "active-vessel" and dishTgt <> "no-target"
{
    set dishTgt to ves_antenna_top_gain(commList):getField("target").
}

lock steering to lookDirUp(dishTgt, sun:position).

disp_main(scriptPath():name).
until false
{
    disp_orbit().
}
