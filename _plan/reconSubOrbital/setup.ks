parameter _prms to list().

RunOncePath("0:/lib/globals.ks").

if _prms:Length = 0 
{
    set _prms to g_Tag["PRM"].
}

set g_MP_List to list(
     "launch/launchPhase_SO", _prms
    ,"sci/collectSamples", list()
    ,"reentry/reentry", list(25000, True)
).