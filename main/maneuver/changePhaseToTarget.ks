@LazyGlobal off.
clearScreen.

parameter params is list().

runOncePath("0:/lib/burnCalc").
runOncePath("0:/lib/disp").
runOncePath("0:/lib/mnv").
runOncePath("0:/lib/nav").
runOncePath("0:/lib/util").
runOncePath("0:/lib/vessel").
runOncePath("0:/kslib/lib_navigation").

DispMain(scriptPath()).

local tgtVes to Ship.
local tgtPhase to 0.
local numOrbits to 1.

if params:length > 0 
{
    set tgtVes to params[0].
    if params:length > 1 set tgtPhase to params[1].
    if params:length > 2 set numOrbits to params[2].
}

if tgtVes = Ship
{
    local timer to time:seconds.
    until tgtVes <> Ship
    {
        if time:seconds > timer 
        {
            OutTee("Choose target vessel for phase change operation", 0, 0, 5).
            set timer to time:seconds + 5.
        }
        DispTelemetry().
        if HasTarget
        {
            set tgtVes to Target.
            break.
        }
    }
}

set currentPhase to kslib_nav_phase_angle(tgtVes, Ship).

OutMsg("TESTING TARGET DATA DISPLAY").
until false
{
    DispTargetData(tgtVes).
    wait 0.05.
}