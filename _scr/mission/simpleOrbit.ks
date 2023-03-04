@LazyGlobal off.
ClearScreen.

parameter params is list().

// Dependencies
RunOncePath("0:/lib/loadDep").

DispMain(ScriptPath():name).

// Declare Variables
local foo to 0.

// Parse Params
if params:length > 0 
{
  set foo to params[0].
}

OutMsg("Indefinite orbit").
until false
{
    wait 0.01.
}