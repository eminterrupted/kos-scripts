@lazyGlobal off.
clearScreen. 

parameter tgt is "Agena-TD JR".

runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_mnv").
runOncePath("0:/lib/lib_nav").
runOncePath("0:/lib/lib_rendezvous").
runOncePath("0:/lib/lib_util").
runOncePath("0:/lib/lib_vessel").
runOncePath("0:/kslib/lib_navigation").

disp_main().

set target  to nav_orbitable(tgt).

local p0    to nav_lng_to_degrees(ship:longitude).
wait 5.
local p1    to nav_lng_to_degrees(ship:longitude).
local phaseRate to (p1 - p0) / 5.

local targetAngle   to mod(nav_lng_to_degrees(target:longitude) - nav_lng_to_degrees(ship:longitude) + 260, 360).
local timeToAdd     to targetAngle / phaseRate.
local resonantPeriod to ship:orbit:period + timeToAdd.

local resonantSMA to ((ship:body:mu * resonantPeriod^2) / 4 * constant:pi^2)^(1/3).
local resonantAp  to resonantSMA - ship:body:radius.

print "phaseRate     : " + phaseRate at (2, 21).
print "targetPhase   : " + round(targetAngle, 2) at (2, 22).
print "phaseToCover  : " + round(targetAngle, 2) at (2, 23).
print "current Period: " + round(ship:orbit:period, 1) at (2, 24).
print "resonantPeriod: " + round(resonantPeriod, 1) at (2, 25).
print "resonantAP    : " + round(resonantAp, 1) at (2, 26).

until false 
{
    wait 0.01.
}
