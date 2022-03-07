@lazyGlobal off.
clearScreen.

parameter params to list().

runOncePath("0:/lib/scansat").
runOncePath("0:/lib/disp").
runOncePath("0:/lib/nav").
runOncePath("0:/lib/vessel").
runOncePath("0:/lib/util").

DispMain(scriptPath()).

local orientation to "pro-sun".

if params:length > 0 
{
    set orientation to params[0].
}

local sVal to ship:facing.
local scanList to ship:modulesNamed("scansat").
//local scanner to scanlist[0]:part.
local scanParts to list().
for scanner in scanList 
{
    scanParts:add(scanner:part).
}
    

lock steering to sVal.

for scnSat in scanList 
{
    ScansatActivate(scnSat:part).
}

//space constraints means we can only display the first scanner 
until false
{
    set sVal to GetSteeringDir(orientation).

    DispScansat(scanParts).
    wait 0.01.
}