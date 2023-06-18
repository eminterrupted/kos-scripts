@LazyGlobal off.
ClearScreen.

parameter _params is list().

// Load dependencies
RunOncePath("0:/lib/libLoader.ks").

// Define high-level variables
local tgtHeading to 90.
local tgtAngle   to 89.25.

// Parameter checking
if _params:length > 0 
{
    set tgtHeading to _params[0].
    if _params:length > 1 set tgtAngle to _params[1].
}

DispMain(ScriptPath()).

// Begin
