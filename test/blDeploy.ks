@lazyGlobal off.
clearScreen.

local tgtEcc to 0.003925.

print "Press any key to start".
wait until Terminal:Input:HasChar.
print "Starting...".
print " ".

lock throttle to 1.
until Stage:Number <= 0 
{
    print "Staging: " + Stage:Number.
    wait until Stage:Ready.
    stage.
}
wait 0.01.
if Ship:Thrust > 0
{
    print "Burning".
    until Ship:Thrust <= 0.01 or Ship:Orbit:Eccentricity <= tgtEcc
    {
        print "Ecc: {0}  ":Format(Round(Ship:Orbit:Eccentricity, 5)).
    }
    print "Burn complete".
}
lock throttle to 0.
unlock throttle.
print "Final Ecc: " + Round(Ship:Orbit:Eccentricity, 5).