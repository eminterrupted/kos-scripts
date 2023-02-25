parameter _prms to list().

RunOncePath("0:/lib/globals.ks").

if _prms:Length = 0 
{
    set _prms to g_Tag["PRM"].
}

set g_MP_List to list(
    "launch/launchPhase_Main", _prms
    ,"mission/simpleOrbit", list()
).

// set g_MP_List to list(
//     "launch/launchPhase_Main", _prms
//     ,"mission/simpleOrbit", list()
// ).