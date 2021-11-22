
@lazyGlobal off.
clearScreen.

parameter param is list().

runOncePath("0:/lib/disp").
runOncePath("0:/lib/vessel").
runOncePath("0:/lib/util").

DispMain(scriptPath():name).

local doneFlag to false.
local orbitTime to 0.
local orientation to "pro-sun".

if param:length > 0 
{
    set orbitTime to param[0].
    if param:length > 1 set orientation to param[1].
}
local orbitTS to time:seconds + orbitTime.

local sVal to ship:facing.
lock steering to sVal.

for p in ship:partsTagged("solarBay")
{
    if p:hasModule("ModuleAnimateGeneric") 
    {
        OutMsg("Opening solar bay doors").
        if not DoEvent(p:getModule("ModuleAnimateGeneric"), "open").
        {
            DoAction(p:getModule("ModuleAnimateGeneric"), "toggle").
        }
        wait 0.1.
        until p:getModule("ModuleAnimateGeneric"):getfield("status") = "Locked"
        {
            DispOrbit().
            wait 0.01.
        }
        OutMsg().
    }
}

for m in ship:modulesnamed("ModuleDeployableSolarPanel")
{
    if m:part:tag = "" DoAction(m, "Extend Solar Panel").
}

for m in ship:modulesNamed("ModuleRTAntenna")
{
    if m:part:tag = "" DoAction(m, "Activate").
}

// for m in ship:modulesNamed("ModuleResourceConverter")
// {
//     if m:part:tag = "" and m:hasEvent("Start Fuel Cell") orbitalFuelCells:add(m).
// }
fuelCells on.

if orbitTime > 0
{
    OutTee("Orbiting until " + timestamp(orbitTS):full).
}
else
{
    OutTee("Orbiting indefinitely").
}
OutHUD("Press Enter to warp to orbit timestamp").
OutHUD("Press End in terminal to abort").

until doneFlag
{
    if orbitTime > 0 and time:seconds >= orbitTS 
    {
        set doneFlag to true.
    }

    if terminal:input:hasChar
    {
        if terminal:input:getChar = terminal:input:endCursor
        {
            OutTee("Terminating Orbit").
            set warp to 0.
            set doneFlag to true.
        }
        else if terminal:input:getChar = terminal:input:enter
        {
            OutTee("Warping to orbital timestamp").
            warpTo(orbitTS).
        }
    }
    set sVal to GetSteeringDir(orientation).
    
    if orbitTime > 0 
    {
        local tsStr to timestamp(orbitTS - time:seconds).
        set tsStr to (tsStr:year - 1) + "y, " + (tsStr:day - 1) + "d " + tsStr:clock.
        OutInfo("Time remaining: " + tsStr).
    }
    DispOrbit().
    wait 0.05.
}
