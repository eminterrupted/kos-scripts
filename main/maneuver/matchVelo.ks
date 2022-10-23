@LazyGlobal off.
ClearScreen.

parameter params is list().

// Dependencies
RunOncePath("0:/lib/loadDep").

DispMain(ScriptPath():name).

// Declare Variables
local tgtVes to "".

// Parse Params
if params:length > 0 
{
  set tgtVes to params[0].
}

// Assumption: match velocities at closest approach
