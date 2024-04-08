@LazyGlobal off.
ClearScreen.

parameter _params is list().

RunOncePath("0:/lib/depLoader.ks").

local altThresh to 25000.

if _params:length > 0
{
    set altThresh to _params[0].
}

print "P8: Waiting to RSO".
wait until Ship:Altitude <= altThresh.
core:part:GetModule("ModuleRangeSafety"):DoEvent("Range Safety").