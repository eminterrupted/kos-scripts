parameter _prms to list().

RunOncePath("0:/lib/globals.ks").

if g_Tag:PRM:Length > 0 and _prms:length = 0 { set _prms to g_Tag:PRM. }

set g_MP_List to list(
     "launch/launchMaxAlt", _prms
).
