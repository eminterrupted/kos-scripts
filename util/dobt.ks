@lazyGlobal off.
clearScreen.

parameter tgtPe is -(body:radius / 1.5),
          orientation is "retro-sun".

runOncePath("0:/lib/globals").
runOncePath("0:/lib/disp").
runOncePath("0:/lib/util").
runOncePath("0:/lib/vessel").

DispMain(scriptPath(), false).

set sVal to GetSteeringDir("retro-sun").
lock steering to sVal.
lock throttle to tVal.

ArmAutoStaging().

OutMsg("Press Enter to begin deorbit burn").
until CheckInputChar(terminal:input:enter)
{
    wait 0.01.
}

OutMsg("Aligning for deorbit burn").
until CheckSteering(5)
{
    DispOrbit().
}

OutMsg("Beginning deorbit burn").
OutInfo("Dist Remaining: " + Round(ship:periapsis - tgtPe) + "  ").
set tVal to 1.
until ship:periapsis < tgtPe
{
    set sVal to GetSteeringDir("retro-sun").
    OutInfo("Dist Remaining: " + Round(ship:periapsis - tgtPe) + "  ").
    DispOrbit().
}
set tVal to 0.
OutInfo().
OutMsg("Deorbit burn complete").
until false
{
    set sVal to GetSteeringDir(orientation).
    DispOrbit().
}