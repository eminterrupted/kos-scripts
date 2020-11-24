// This file is distributed under the terms of the MIT license, (c) the KSLib team
@lazyGlobal off.

clearscreen.

runPath("0:/kslib/library/lib_navigation.ks").

local quit is false.
on AG10 {
    set quit to true.
}

set target to body("Mun").

print "Activate action group 10 (0) to exit.".
print "We will print angle to".
print "relative ascending node for the Mun".
print "Phase angle to the Mun: ".
print "Angle to RAN for the Mun: ".
until quit {
    local line is 3.
    print phaseAngle() at (23, line).
    set line to line + 1.
    print angleToRelativeAscendingNode(
        orbitBinormal(ship),
        orbitBinormal(target)
    ) at (25, line). 
}
