runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/lib_tag").

clearscreen.

local sciPath to "local:/sci".

copypath("0:/_main/component/aero_sci_for_biome", sciPath).

print "running path: " + sciPath.
runPath(sciPath).