@LazyGlobal off.
ClearScreen.

parameter params is list().

// Dependencies
RunOncePath("0:/lib/depLoader").

DispMain(ScriptPath():name).

// Declare Variables
local runmode to 0. // Used to identify which loop to use
local program to 0. // Used to control flow within a loop
                    // Example: Loop 1 may be running the pre-launch check,
                    //          and program would identify the current step


// Parse Params
if params:length > 0 
{
  set foo to params[0].
}