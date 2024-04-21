@LazyGlobal off.
ClearScreen.

parameter _params is list().

RunOncePath("0:/lib/depLoader.ks").

local altThresh to 25000.

if _params:length > 0
{
    set altThresh to ParseStringScalar(_params[0], altThresh).
}

OutMsg("P8: Waiting to RSO").
OutInfo("AltThresh: {0}":Format(altThresh)).
cr().
until Ship:Altitude <= altThresh
{
    OutInfo("Distance to AltThresh: {0}":Format(Round(Ship:Altitude - altThresh)), g_line).
}
set g_line to g_line - 1.
OutMsg("P99: KILL").
clr(cr()).
core:part:GetModule("ModuleRangeSafety"):DoEvent("Range Safety").