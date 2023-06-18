// #include "0:/lib/libLoader"
@LazyGlobal off.
ClearScreen.

local planSetupPath  to "0:/_plan/{0}/SetupPlan.ks":Format(g_Mission).
local planOutputDir  to "0:/_plan/{0}/missions":Format(g_Mission).
local planOutputPath to "{0}/{1}.json":Format(planOutputDir, g_ShipNameNormalized).

if not (Exists(planOutputDir))
{
    CreateDir(planOutputDir).
}

RunPath(planSetupPath).

WriteJson(g_PlanLex, planOutputPath).