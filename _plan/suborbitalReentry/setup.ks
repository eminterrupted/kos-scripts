parameter _prms to list().

RunOncePath("0:/lib/globals.ks").

set g_MP_List to list(
     "launch/launchPhase_SO", _prms
    ,"reentry/reentry", list(25000, True)
).