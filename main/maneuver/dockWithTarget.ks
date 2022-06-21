@LazyGlobal off.
ClearScreen.

parameter params is list().

// Dependencies
RunOncePath("0:/lib/loadDep").

DispMain(ScriptPath():name).

// Declare Variables
local dockTgt to choose target if hasTarget else "".
local safeDist to 50.
local startDist to 100.

// Parse Params
if params:length > 0 
{
  set dockTgt to params[0].
  if params:length > 1 set safeDist to params[1].
}

// Start a loop that runs until the type referenced by dockTgt is a dockingPort.
// Validate dockTgt is a port. 
// If not a port, check vessel ports.
// If more than one, prompt for selection.
local portList to list().

if dockTgt:IsType("DockingPort")
{
    set portList to list(dockTgt).
}
else 
{
    if dockTgt:IsType("Vessel") or dockTgt:IsType("Station")
    {
        set portList to dockTgt:dockingPorts.
    }
    else if dockTgt:IsType("Part") or dockTgt:IsType("Decoupler")
    {
        set portList to dockTgt:Ship:DockingPorts.
    }
    
    if portList:length = 1
    {
        set dockTgt to portList[0].
    }
    else
    {
        until dockTgt:IsType("DockingPort")
        {
            set dockTgt to PromptPartSelect(dockTgt, "Choose Docking Port", portList, true).
        }
    }
}
OutMsg("dockTgt docking port validation: Complete").

local sVal to ship:facing.
lock steering to sVal. 

OutMsg("Translation Mode").
local posErr to 1.
until false
{
    set posErr to TranslateToDockingPort(dockTgt, ship:dockingPorts[0], startDist, 5). 
    OutInfo("Current Position Error: " + round(posErr, 5)).
    if CheckInputChar(Terminal:Input:EndCursor) break.
}