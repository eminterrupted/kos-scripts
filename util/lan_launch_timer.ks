// Script to run on a second core during a relay test launch
// to find the amount of time and phase advancement during 
// launch. Use to find optimal launch windows for constellations
@lazyGlobal off.
clearScreen.

parameter tgtLaunchLAN to 87.

runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_nav").
runOncePath("0:/lib/lib_util").

print "Waiting for launch".
print " ".

until util_check_range(ship:orbit:LAN, tgtLaunchLAN - 1, tgtLaunchLAN + 1)
{
    print "Current LAN: " + round(ship:orbit:longitudeofascendingnode, 5) + "   " at (0, 9).
    wait 0.01.
}
if warp > 0 set warp to 0.
until util_check_range(ship:orbit:LAN, tgtLaunchLAN, tgtLaunchLAN + (90 - tgtLaunchLAN))
{
    print "Current LAN: " + round(ship:orbit:longitudeofascendingnode, 5) + "   " at (0, 9).
    wait 0.01.
}
ag10 on.
local launchTime    to time:seconds.
local myLaunchLAN   to ship:orbit:longitudeofascendingnode.

clearScreen.

print "Liftoff at " + time:full.
print "Vessel longitude at liftoff : " + myLaunchLAN.
print " ".

until ag9
{
    wait 0.01.
}

local arrivalTime   to time:seconds.
local arrivalLAN  to ship:orbit:longitudeofascendingnode.
local diffLAN     to arrivalLAN - myLaunchLAN.

print "Arrival on orbit at " + time:full.
print "Vessel longitude at arrival : " + arrivalLAN.
print " ".
print "Time eclipsed: " + (arrivalTime - launchTime).
print "Vessel longitude covered: " + diffLAN.