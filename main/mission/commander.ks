@LazyGlobal off.
ClearScreen.

RunOncePath("0:/lib/libLoader.ks").

DispMain(ScriptPath()).

set g_MissionTag to ParseCoreTag(core:Part:Tag).