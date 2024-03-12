@LazyGlobal off.
ClearScreen.

parameter params is list().

// Dependencies
RunOncePath("0:/lib/depLoader.ks").

// Declare Variables
local foo to 0.

// Parse Params
if params:length > 0 
{
  set foo to params[0].
}