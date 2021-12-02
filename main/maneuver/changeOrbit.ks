@lazyGlobal off.
clearScreen.

parameter params is list().

runOncePath("0:/lib/burnCalc").
runOncePath("0:/lib/disp").
runOncePath("0:/lib/globals").
runOncePath("0:/lib/mnv").
runOncePath("0:/lib/nav").
runOncePath("0:/lib/util").
runOncePath("0:/lib/vessel").

DispMain(scriptPath()).

local argPe to ship:orbit:argumentofperiapsis.
local stAp  to ship:apoapsis.
local stPe  to ship:periapsis.
local tgtAp to 0.
local tgtPe to 0.

if params:length > 0 
{
    set tgtPe to params[0].
    if params:length > 1 set tgtAp to params[1].
    if params:length > 2 set argPe to params[2].
}

OutMsg("changeOrbit complete!").