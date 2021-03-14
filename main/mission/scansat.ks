@lazyGlobal off.
clearScreen.

runOncePath("0:/lib/lib_addon_scansat").

set terminal:height to 40.
set terminal:width  to 60.
core:doAction("open terminal", true).

local scanList to ship:partsDubbedPattern("scansat").
local scanner  to scanList[0].

local sVal to ship:prograde.
lock steering to sVal.

panels on.
scansat_activate(scanner, true).

until false
{
    scansat_disp(scanner).
}