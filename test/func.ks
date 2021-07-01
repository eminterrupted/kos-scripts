@lazyGlobal off.
clearScreen.

runOncePath("0:/lib/lib_vessel").

local groundAntenna to list().
local groundLights to list().
local groundPanels to list().
local landingLights to list().

for p in ship:partsTaggedPattern("groundAntenna")
{
    groundAntenna:add(p:getModule("ModuleRTAntenna")).
}

for p in ship:partsTaggedPattern("groundLight")
{
    groundLights:add(p:getModule("ModuleLight")).
}

for p in ship:partsTaggedPattern("groundPanel")
{
    groundPanels:add(p:getModule("ModuleDeployableSolarPanel")).
}

for p in ship:partsTaggedPattern("landingLight")
{
    landingLights:add(p:getModule("ModuleLight")).
}


// Turn off the landing lights
ves_activate_lights(landingLights, false).

// Activate the ground-only solar panels, comms, and lights
ves_activate_solar(groundPanels).
ves_activate_antenna(groundAntenna).
ves_activate_lights(groundLights).