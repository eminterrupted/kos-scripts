@lazyGlobal off.
clearScreen.

parameter params is list().

runOncePath("0:/lib/disp").
runOncePath("0:/lib/nav").
runOncePath("0:/lib/vessel").

DispMain(scriptPath()).

local tgtPe to ship:periapsis.
local tgtAp to ship:apoapsis.
local tgtInc to ship:orbit:inclination.
local tgtLAN to ship:orbit:lan.
local tgtArgPe to ship:orbit:argumentofperiapsis.

if params:length > 0 
{
    set tgtPe to params[0].
    if params:length > 1 set tgtAp to params[1].
    if params:length > 2 set tgtInc to params[2].
    if params:length > 3 set tgtLAN to params[3].
    if params:length > 4 set tgtArgPe to params[4].
}

OutMsg("Running changeInc with params:").
OutInfo("tgtInc["+ tgtInc + "] | tgtLAN[" + tgtLAN + "]").
wait 1.
runPath("0:/main/maneuver/changeInc", list(tgtInc, tgtLAN)).
OutMsg("changeInc complete").
wait 2.

OutMsg("Running changeOrbit with params: ").
OutInfo("tgtPe[" + tgtPe + "] | tgtAp[" + tgtAp + "]").
OutInfo2("tgtArgPe[" + tgtArgPe + "]").
runPath("0:/main/maneuver/changeOrbit", list(tgtPe, tgtAp, tgtArgPe)).
OutMsg("changeOrbit complete").
