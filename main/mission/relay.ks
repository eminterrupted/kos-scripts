@lazyGlobal off.
clearScreen.

parameter params is list().

runOncePath("0:/lib/disp").
runOncePath("0:/lib/globals").
runOncePath("0:/lib/nav").
runOncePath("0:/lib/vessel").
runOncePath("0:/lib/util").

DispMain(scriptPath()).

local bodyTgt to Body("Kerbin").
local orientation to "pro-sun".
local relayType to "base".
local txTgt to "active-vessel".

if params:length > 0 
{
    set orientation to params[0].
    if params:length > 1 set relayType to params[1].
    if params:length > 2 set txTgt to GetOrbitable(params[2]).
}

set sVal to GetSteeringDir(orientation).
lock steering to sVal.

OutMsg("Relay type: " + relayType).
OutInfo("Orientation: " + orientation).

if relayType:contains("tx")
{
    local txList to ship:partsTaggedPattern("dish.primary").
    for p in txList 
    {
        if p:hasModule("ModuleRTAntenna")
        {
            local m to p:getModule("ModuleRTAntenna").

            if m:hasField("dish range") m:setField("target", txTgt).
        }
    }
}

until false
{
    set sVal to GetSteeringDir(orientation).
    DispOrbit().
}