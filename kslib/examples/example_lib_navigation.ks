// This file is distributed under the terms of the MIT license, (c) the KSLib team
@lazyGlobal off.

clearscreen.

runPath("0:/kslib/lib_navigation").

local quit is false.
on AG10 {
    set quit to true.
}

set target to body("Mun").

print "Activate action group 10 (0) to exit.".
print "We will print angle to".
print "relative ascending node for the Mun".
print "Phase angle to the Mun   : ".
print "Phase angle (normalized) : ".
print "Phase change per s       : ".
print "Angle to RAN for the Mun : ".
lock phaseAng to kslib_nav_phase_angle().
local p0 to phaseAng. 
wait 1. 
local p1 to phaseAng.

until quit {
    local line is 3.
    print phaseAng at (28, line).
    set line to line + 1.
    if phaseAng < 0 print phaseAng + 360 at (28, line). else print phaseAng at (28, line).
    set line to line + 1.
    print abs(p1 - p0) at (28, line).
    set line to line + 1.
    print kslib_nav_ang_to_rel_asc_node(
        kslib_nav_obt_binormal(ship),
        kslib_nav_obt_binormal(target)
    ) at (28, line). 
}
