@LazyGlobal off.
ClearScreen.

parameter _params is list().

// Dependencies
RunOncePath("0:/lib/libLoader").

// Declare Variables
local dispPatch to choose Orbit:NextPatch if Orbit:HasNextPatch else choose NextNode:Orbit if HasNode else Orbit.

// Parse Params
if _params:length > 0 
{
  set dispPatch to _params[0].
}

DispMain(ScriptPath(), False).

until false
{
    set dispPatch to choose Orbit:NextPatch if Orbit:HasNextPatch else choose NextNode:Orbit if HasNode else Orbit.
    DispPatch(dispPatch).
    wait 0.01.

    GetTermChar().

    if g_TermChar = Terminal:Input:EndCursor
    {
       ClearDispBlock(). 
    }
}
wait 1.
