@LazyGlobal off.
ClearScreen.

parameter params is list().

RunOncePath("0:/lib/depLoader.ks").

local altThresh to 25000.

if params:length > 0
{
    set altThresh to params[0].
}

print "P8: Waiting to RSO".
wait until Ship:Altitude <= altThresh.
core:part:GetModule("ModuleRangeSafety"):DoEvent("Range Safety").