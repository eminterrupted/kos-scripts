@lazyGlobal off.
clearScreen.

runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_sci").
runOncePath("0:/lib/lib_mnv").
runOncePath("0:/lib/lib_nav").
runOncePath("0:/lib/lib_vessel").

local curMass to 0.
local wetMass to 0.
local dryMass to 0.

print "ship:stagedDeltaV".
print "-----------------".
ves_available_dv().

print "Calculated DeltaV".
print "-----------------".
ves_available_dv_next().

print " ".
print " ".


print "Mass".
print "----".

for p in ship:parts
{
    set curMass to curMass + p:mass.
    set wetMass to wetMass + p:wetmass.
    set dryMass to dryMass + p:drymass.

    print "CurMass: " + round(curMass, 3) + " | WetMass: " + round(wetMass, 3) + " | DryMass: " + round(dryMass, 3) + " | PartMass: " + round(p:mass, 3) + " | PartName: " + p:name.
}
print " ".
print "Ship:mass: " + round(ship:mass, 3).