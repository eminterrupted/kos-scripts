@lazyGlobal off. 
clearScreen.

runOncePath("0:/lib/lib_disp").

local sVal to lookDirUp(ship:prograde:vector, body("sun"):position) + r(0, 90, 0).
lock steering to sVal.

disp_main(scriptPath():name).
disp_msg("All mission scripts completed").
until false
{
    set sVal to lookDirUp(ship:prograde:vector, body("sun"):position).
    disp_orbit().
}