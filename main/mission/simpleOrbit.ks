
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

local deployOrder to lex().

for p in ship:partsTaggedPattern("payloadDeploy.")
{
    local pTag to p:tag:split(".")[1].
    if not deployOrder:hasKey(pTag)
    {
        set deployOrder[pTag] to list(p).
    }
    else
    {
        deployOrder[pTag]:add(p).
    }
}

from { local idx to 0.} until idx >= deployOrder:keys:length - 1 step { set idx to idx + 1.} do 
{
    deployPayloadId(ship:partsTaggedPattern("payloadDeploy." + idx), idx).
    wait 2.
}
deployPayloadId(ship:partsTaggedPattern(""), "").

if orbitTime > 0
{
    OutTee("Orbiting until " + timestamp(orbitTS):full).
    InitWarp(OrbitTS, "orbit script termination").
}
else
{
    OutTee("Orbiting indefinitely").
}
OutHUD("Press End key in terminal to abort").

until false
{
    if CheckInputChar(terminal:input:endcursor)
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

// Local functions
// deployPayloadId :: <parts>, <int> | <none>
// Runs a step on the parts passed in
local function deployPayloadId
{
    parameter partsList,
            sequenceIdx.
    
    OutMsg("Deploying orbital apparatus.").
    OutInfo("Step: " + sequenceIdx).
    
    for p in partsList
    {
        if p:hasModule("ModuleAnimateGeneric")
        {
            local m to p:getModule("ModuleAnimateGeneric").
            DoEvent(m, "open").
        }
    }

    for p in partsList
    {
        if p:hasModule("ModuleDeployablePart")
        {
            local m to p:getModule("ModuleDeployablePart").
            DoEvent(m, "extend").
        }
    }

    for p in partsList 
    {
        if p:hasModule("ModuleRTAntenna")
        {
            local m to p:getModule("ModuleRTAntenna").
            DoEvent(m, "activate").
        }
    }

    for p in partsList
    {
        if p:hasModule("ModuleDeployableSolarPanel")
        {
            local m to p:getModule("ModuleDeployableSolarPanel").
            DoAction(m, "extend solar panel", true).
        }
    }
}