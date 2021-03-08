
@lazyGlobal off.
clearScreen.

runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_vessel").

local commList to ship:partsDubbedPattern("antenna").
local solarList to ship:partsDubbedPattern("solar").
local sVal to lookDirUp(ship:prograde:vector, body("sun"):position) + r(0, 90, 0).

lock steering to sVal.

ves_activate_solar(solarList).
ves_activate_antenna(commList).

disp_main().

until false
{
    set sVal to lookDirUp(ship:prograde:vector, body("sun"):position).
    disp_orbit().
}
