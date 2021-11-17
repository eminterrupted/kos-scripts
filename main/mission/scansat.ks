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

local scanner to ship:partsDubbedPattern("scansat")[0].

local sVal to ship:facing.
lock steering to sVal.

ScansatActivate(scanner).

until false
{
    if params[0] = "radIn-sun" set sVal to lookDirUp(body:position, sun:position).
    else if params[0] = "pro-sun" set sVal to lookDirUp(ship:prograde:vector, sun:position).
    else if params[0] = "pro-body" set sVal to lookDirUp(ship:prograde:vector, -body:position).

    DispScansat(scanner).
    wait 0.01.
}