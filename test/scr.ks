@lazyGlobal off.
clearScreen.

runOncePath("0:/lib/disp").
runOncePath("0:/lib/vessel").

DispMain(scriptPath(), false).

OutMsg("Waiting for burn...").

until GetTotalThrust(GetEngines("active")) > 0.1
{
    DispOrbit().
}

local stLng to ship:longitude.
OutMsg("Burn started").
OutInfo("Starting longitude: " + round(stLng, 3)).

until GetTotalThrust(GetEngines("active")) < 0.1
{
    DispOrbit().
}

local endLng to ship:longitude.
local dLng to endLng - stLng.

OutMsg("Burn complete").
OutInfo2("Ending longitude: " + round(endLng, 3)).
wait 1.
OutInfo2().
OutInfo("Longitude Delta: " + round(dLng, 3)).
