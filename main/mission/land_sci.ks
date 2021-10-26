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
    if light:part:tag:contains("bayLight") bayLights:add(light).
}

for bay in ship:modulesNamed("USAnimateGeneric")
{
    if bay:hasEvent("deploy primary bays") bayList:add(bay).
}

for bay in ship:modulesNamed("ModuleAnimateGeneric") 
{
    if bay:hasEvent("open doors") bayList:add(bay).
}

if bayList:length > 0 
{
    disp_msg("Opening bay doors").
    ves_open_bays(bayList).
    wait 1.
    ves_activate_lights(bayLights).
    wait 1.
}

unlock steering.
sas on.

disp_msg("Collecting science").
sci_deploy_list(sciMod).

if ship:crew():length = 0
{
    wait 1.
    disp_msg("Recovering science").
    sci_recover_list(sciMod).
}
else
{
    wait 1.
    disp_msg("Collecting science").
    sci_recover_list(sciMod, "collect").
}

if ship:modulesNamed("TSTChemCam"):length > 0
{
    disp_msg("Deploying ChemCam").
    sci_deploy_chemcam().
    wait 5.
    ag10 off.
    disp_msg("ChemCam deployed. Press AG10 to terminate experiment").
    until ag10 
    {
        wait 0.1.
    }
    sci_retract_chemcam().
}

ag9 off.
ag10 off.
disp_hud("Press 9 to capture Neptune images, 0 to continue").
until false
{
    if ag9 
    {
        ves_neptune_image().
        ag9 off.
    }
    if ag10 break.
}
ag10 off.

disp_msg("Experiments completed").
ves_close_bays(bayList).