
@lazyGlobal off.
clearScreen.

parameter param is list().

runOncePath("0:/lib/disp").
runOncePath("0:/lib/vessel").
runOncePath("0:/lib/util").

DispMain(scriptPath():name).

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

for m in ship:modulesnamed("ModuleDeployableSolarPanel")
{
    if m:part:tag = "" DoEvent(m, "Extend Solar Panel").
    else if m:part:tag = "" DoAction(m, "Extend Solar Panels").
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
    InitWarp(OrbitTS, "orbit script termination").
}
else
{
    OutTee("Orbiting indefinitely").
}
OutHUD("Press Backspace in terminal to abort").

until false
{
    if CheckInputChar(terminal:input:backspace)
    {
        OutMsg("Terminating Orbit").
        wait 1.
        break.
    }
    if orbitTime > 0 and time:seconds >= orbitTS 
    {
        break.
    }

    if orientation = "sun-pro" 
    {
        set sVal to lookDirUp(sun:position, ship:prograde:vector).
    }
    else if orientation = "pro-radOut"
    {
        set sVal to lookDirUp(ship:prograde:vector, -body:position).
    }
    else if orientation = "pro-sun"
    {
        set sVal to lookDirUp(ship:prograde:vector, sun:position).
    }
    
    if orbitTime > 0 
    {
        local tsStr to timestamp(orbitTS - time:seconds).
        set tsStr to (tsStr:year - 1) + "y, " + (tsStr:day - 1) + "d " + tsStr:clock.
        OutInfo("Time remaining: " + tsStr).
    }
    DispOrbit().
    wait 0.1.
}
