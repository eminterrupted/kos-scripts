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

DispMain(scriptPath(), false).

local tgtType to 0.
local tgtValue to 0.
local tgtEcc to 0.
local tgtPe to 0.
local tgtAp to 0.

if params:length > 0 
{
    set tgtType to params[0].
    if params:length > 1 set tgtValue to params[1].
    if params:length > 2 set tgtEcc to params[2].
}

if (tgtType = "ap")
{
    set tgtPe to GetPe(tgtValue, tgtEcc).
    set tgtAp to tgtValue.
}
else if (tgtType = "pe")
{
    set tgtPe to tgtValue.
    set tgtAp to GetAp(tgtValue, tgtEcc).
}
else if (tgtType = "sma")
{
    local tgtApPe to GetApPe(tgtValue, tgtEcc).
    set tgtPe to tgtApPe[0].
    set tgtAp to tgtApPe[1].
}
else 
{
    //lol exception 🤷‍♀️
    OutTee("No valid target type provided", 0, 2).
    print 1 / 0.
}

runPath("0:/main/maneuver/changeOrbit", list(tgtPe, tgtAp)).

