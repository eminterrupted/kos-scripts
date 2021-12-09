@lazyGlobal off.
clearScreen.

parameter params is list().

runOncePath("0:/lib/disp").
runOncePath("0:/lib/globals").
runOncePath("0:/lib/nav").
runOncePath("0:/lib/vessel").
runOncePath("0:/lib/util").

DispMain(scriptPath()).

local orientation to "pro-sun".

if params:length > 0 
{
    set orientation to params[0].
}

local sVal to GetSteeringDir(orientation).
lock steering to sVal.

OutMsg("Orientation: " + orientation).
until false
{
    set sVal to GetSteeringDir(orientation).
    DispOrbit().
}