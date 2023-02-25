parameter _prms to list().

RunOncePath("0:/lib/globals.ks").

set g_MP_List to list(
     "launch/launchPhase_Main", g_Tag:PRM
    ,"reentry/reentry", list(50000, True)
).