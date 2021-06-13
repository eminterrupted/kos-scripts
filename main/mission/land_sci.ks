@lazyGlobal off.
clearScreen.

runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_sci").
runOncePath("0:/lib/lib_util").
runOncePath("0:/lib/lib_vessel").

disp_main(scriptPath()).

local sciMod    to sci_modules().
local bayList      to list().
local bayLights to list().

for light in ship:modulesNamed("ModuleLight")
{
    if light:part:tag = "bay" bayLights:add(light).
}

for bay in ship:modulesNamed("USAnimateGeneric")
{
    if bay:hasEvent("deploy primary bays") bayList:add(bay).
}

disp_msg("Opening bay doors").
ves_open_bays(bayList).
wait 1.
ves_activate_lights(bayLights).
wait 1.

disp_msg("Collecting science").
sci_deploy_list(sciMod).

wait 1.
disp_msg("Recovering science").
sci_recover_list(sciMod).

disp_msg("Experiments completed").

until false
{
    wait 0.
}