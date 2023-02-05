parameter _prms to list().

RunOncePath("0:/lib/globals.ks").

set g_MP_List to list(
     "0:/_scr/launch/launchMaxAlt.ks", _prms
    ,"0:/_scr/reentry/reentry.ks", list(50000, True)
).