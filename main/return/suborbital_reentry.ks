@lazyGlobal off.
clearScreen.

// Easy reentry near KSC

//-- Dependencies --//
runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_nav").


//-- Variables --//
local parachutes to ship:modulesNamed("RealChuteModule").
local sVal       to lookDirUp(ship:retrograde:vector, body("sun"):position) + r(0, 0, 180).
local tVal       to 0.

// Locks
lock steering to sVal.
lock throttle to tVal.

// Main
disp_main().
for c in parachutes 
{
    c:doEvent("arm parachute").
}

disp_msg().
disp_msg("Staging").
set sVal to lookDirUp(ship:prograde:vector + r(0, -90, 0), body("sun"):position).
wait 5.
until stage:number = 1 
{
    stage.
    wait 5.
}
disp_msg().
disp_msg("Waiting until reentry interface").

until ship:altitude <= body:atm:height
{
    set sVal to lookDirUp(ship:retrograde:vector, body("sun"):position).
    disp_telemetry().
}
disp_msg().
disp_msg("Reentry interface").

until ship:groundspeed <= 1000 and ship:altitude <= 30000
{
    set sVal to ship:retrograde.
    disp_telemetry().
}
unlock steering.
disp_msg().
disp_msg("Control released").

until alt:radar <= 2500
{
    disp_telemetry().
}
disp_msg().
disp_msg("Chute deploy").

until alt:radar <= 700
{
    disp_telemetry().
}
disp_msg().
disp_msg("Awaiting touchdown").

until alt:radar <= 1.5
{
    disp_telemetry().
}

disp_msg().
disp_msg("Touchdown!").
wait 1.
disp_msg("Mission complete").
wait 5.
clearScreen.