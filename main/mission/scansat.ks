@lazyGlobal off.
clearScreen.

// [0] Direction to lock steering to
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
local scanner to ship:partsDubbedPattern("scansat")[0].

local sVal to ship:facing.
lock steering to sVal.

ScansatActivate(scanner).

until false
{
    set sVal to GetSteeringDir(orientation).

    DispScansat(scanner).
    wait 0.01.
}