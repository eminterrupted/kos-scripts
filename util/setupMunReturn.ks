runOncePath("0:/lib/lib_util").
runOncePath("0:/lib/lib_vessel").

print "Setting up return plan".

if not (exists("/boot/bootLoader.ks")) copyPath("0:/boot/bootLoader.ks", "/boot/bootLoader.ks").
set core:bootfilename to "/boot/bootLoader.ks".

writeJson(queue(
    "/return/return_from_mun",
    "return/reentry"
), "data_0:/missionPlan.json").

if ship:modulesNamed("ModuleResourceConverter"):length > 0 
{
    for m in ship:modulesNamed("ModuleResourceConverter") 
    {
        ves_activate_fuel_cell(list(m)).
    }
}
else if ship:modulesNamed("ModuleDeployableSolarPanel"):length > 0
{
    ves_activate_solar().
}

reboot.