
@lazyGlobal off.
clearScreen.

runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_vessel").
runOncePath("0:/lib/lib_util").

disp_main(scriptPath():name).
local orbitalComms  to list().
local orbitalPanels to list().
local orbitalRads   to list().

local sVal to lookDirUp(ship:prograde:vector, -body:position).
lock steering to sVal.

for m in ship:modulesnamed("ModuleDeployableSolarPanel")
{
    if m:part:tag = "stationPanel" orbitalPanels:add(m).
}
ves_activate_solar(orbitalPanels).

for m in ship:modulesNamed("ModuleRTAntenna")
{
    if m:part:tag = "stationAntenna" orbitalComms:add(m).
}
ves_activate_antenna(orbitalComms).

for m in ship:modulesNamed("ModuleSystemHeatRadiator")
{
    if m:part:tag = "stationRadiator" orbitalRads:add(m).
}
for m in ship:modulesNamed("ModuleDeployableRadiator")
{
    if m:part:tag = "stationRadiator" orbitalRads:add(m).
}
ves_activate_radiator(orbitalRads).

ag10 off.
disp_hud("Activate AG10 to end Simple Orbit sequence").
//hudtext("Activate AG10 to end Simple Orbit sequence", 25, 2, 20, green, false).
until ag10
{
    set sVal to lookDirUp(ship:prograde:vector, -body:position).
    disp_orbit().
}
ag10 off.