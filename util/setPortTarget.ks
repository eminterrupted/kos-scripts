@LazyGlobal off.
ClearScreen.

parameter params is list().

// Dependencies
RunOncePath("0:/lib/loadDep").

DispMain(ScriptPath():name).

// Declare Variables
local tgtVes to choose target if hasTarget else ship.

// Parse Params
if params:length > 0 
{
  set tgtVes to params[0].
}

local portList to tgtVes:dockingPorts.

OutMsg("Waiting for port selection...").

set Target to PromptPartSelect("tgtDp", "Select a target docking port", portList, true).

OutMsg("Selection confirmed: " + target:name).
wait 1.