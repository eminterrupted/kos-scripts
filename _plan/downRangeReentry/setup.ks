parameter _prms to list().

RunOncePath("0:/lib/globals.ks").

set g_MP_List to list(
    "launch/launchPhase_Main", _prms
    ,"reentry/reentry", list(10000, True)
).