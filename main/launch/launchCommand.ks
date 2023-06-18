@LazyGlobal off.
ClearScreen.

parameter _params is list().

// Load dependencies
RunOncePath("0:/lib/libLoader.ks").

// Define high-level variables
local foo is 0.

// Parameter checking
if _params:length > 0 
{
    set foo to _params[0].
}

// Script here