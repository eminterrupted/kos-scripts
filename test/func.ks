@lazyGlobal off.
clearScreen.

runOncePath("0:/lib/disp").
runOncePath("0:/lib/util").
runOncePath("0:/lib/vessel").

parameter param is 6, param2 is true.

if param2 ArmAutoStaging(param).

until false
{
    print "Avail Thrust  : " + round(ship:availablethrust, 1) + "   " at (2, 5).
    print "Throttle      : " + round(throttle, 2) + "   " at (2, 6).
    print "Test condition: " + (ship:availablethrust <= 0.01 and throttle > 0) + "   " at (2, 7).
    wait 0.01.
}