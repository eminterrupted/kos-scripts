@LazyGlobal off.
ClearScreen.

RunOncePath("0:/lib/libLoader.ks").

set g_MainProcess to ScriptPath().
DispMain().

set g_MissionTag to ParseCoreTag(core:Part:Tag).