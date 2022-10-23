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

local burnAtNearestNode to false.
local tgtInc to ship:orbit:inclination.
local tgtLAN to ship:orbit:longitudeofascendingnode.
local tgtBody to ship:body.

if params:length > 0
{
    set tgtInc to params[0].
    if params:length > 1 set tgtLAN to params[1].
    if params:length > 2 set burnAtNearestNode to params[2].
}

if tgtInc = -1 set tgtInc to ship:orbit:inclination.
if tgtLAN = -1 set tgtLAN to ship:orbit:LAN.

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

until not hasNode
{
    if hasNode
    {
        remove nextNode.
    }
    else
    {
        break.
    }
}

local mnvNode to IncMatchBurn(ship, ship:orbit, tgtObt, burnAtNearestNode)[2].
add mnvNode.
if round(mnvNode:deltaV:mag, 1) > 1.0
{   DispIncChange(ship:orbit, tgtObt).
    ExecNodeBurn(mnvNode).
    OutHUD("Change Inclination Burn Complete").
}
else
{
    OutHUD("Skipping changeInc, vessel is already close to target inc").
}