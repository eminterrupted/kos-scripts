clearScreen.

print "Waiting for KSC connection to load dependencies".
until addons:rt:hasKscConnection(ship)
{
    wait 30.
}
print "Connection established".
runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_vessel").
clearScreen.

local commList to ship:partsDubbedPattern("antenna").
local solarList to ship:partsDubbedPattern("solar").
local sVal to lookDirUp(ship:prograde:vector, body("sun"):position) + r(0, -90, 0).

lock steering to sVal.

ves_activate_solar(solarList).
ves_activate_antenna(commList).

disp_main().
until false
{
    set sVal to lookDirUp(ship:prograde:vector, body("sun"):position) + r(0, -90, 0).
    disp_orbit().
}
