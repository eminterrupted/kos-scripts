
@lazyGlobal off.
clearScreen.

runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_vessel").
runOncePath("0:/lib/lib_util").

disp_main(scriptPath():name).

local orbitalFuelCells to list().
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

for m in ship:modulesNamed("ModuleResourceConverter")
{
    if m:part:tag = "" and m:hasEvent("Start Fuel Cell") orbitalFuelCells:add(m).
}
ves_activate_fuel_cell(orbitalFuelCells).

ag10 off.
disp_hud("AG10 to end Simple Orbit sequence").

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