@lazyGlobal off.
clearScreen.

parameter params is list().

runOncePath("0:/lib/disp").
runOncePath("0:/lib/burnCalc").
runOncePath("0:/lib/mnv").
runOncePath("0:/lib/nav").
runOncePath("0:/lib/util").
runOncePath("0:/lib/vessel").

DispMain(scriptPath(), false).

local tgtInc to ship:orbit:inclination.
local tgtLAN to ship:orbit:longitudeofascendingnode.
local tgtBody to ship:body.

if params:length > 0
{
    set tgtInc to params[0].
    if params:length > 1 set tgtLAN to params[1].
}

OutTee("Hi I AM IN YOUR ROCKETS A-CHANGIN URE THINGS >:D", 0, 2.5).

local tgtObt to createOrbit(
    tgtInc,
    ship:orbit:eccentricity,
    ship:orbit:semiMajorAxis,
    tgtLAN,
    ship:orbit:argumentOfPeriapsis,
    ship:orbit:meanAnomalyAtEpoch,
    ship:orbit:epoch,
    tgtBody
).

local mnvNode to IncMatchBurn(ship, ship:orbit, tgtObt, true)[2].
add mnvNode.
ExecNodeBurn(mnvNode).

OutHUD("Change Inclination Burn Complete").