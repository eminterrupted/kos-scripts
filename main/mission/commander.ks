@LazyGlobal off.
ClearScreen.

RunOncePath("0:/lib/libLoader.ks").

set g_MainProcess to ScriptPath().
DispMain().

set g_MissionTag to ParseCoreTag(core:Part:Tag).
local tgtInc       to choose g_MissionTag:Params[0] if g_MissionTag:Params:Length > 0 else 0.
local tgtAlt       to choose g_MissionTag:Params[1] if g_MissionTag:Params:Length > 1 else 175000.
local tgtEcc       to choose g_MissionTag:Params[2] if g_MissionTag:Params:Length > 2 else -1. 
local azObj        to choose l_az_calc_init(tgtAlt, tgtInc) if g_GuidedAscentMissions:Contains(g_MissionTag:Mission) else list().
