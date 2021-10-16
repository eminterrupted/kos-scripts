
@lazyGlobal off.
clearScreen.

runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_vessel").
runOncePath("0:/lib/lib_util").

disp_main(scriptPath():name).

local orbitalPanels to list().
local orbitalComms  to list().
local orientation to "prograde".

local sVal to lookDirUp(ship:prograde:vector, sun:position).
lock steering to sVal.

for m in ship:modulesnamed("ModuleDeployableSolarPanel")
{
    if m:part:tag = "" orbitalPanels:add(m).
}
ves_activate_solar(orbitalPanels).

for m in ship:modulesNamed("ModuleRTAntenna")
{
    if m:part:tag = "" orbitalComms:add(m).
}
ves_activate_antenna(orbitalComms).

ag10 off.
disp_hud("Activate AG10 to end Simple Orbit sequence").
//hudtext("Activate AG10 to end Simple Orbit sequence", 25, 2, 20, green, false).
until ag10
{
    if orientation = "sun_position" 
    {
        set sVal to lookDirUp(sun:position, ship:prograde:vector).
    }
    else 
    {
        set sVal to lookDirUp(ship:prograde:vector, sun:position).
    }
    disp_orbit().
}
ag10 off.