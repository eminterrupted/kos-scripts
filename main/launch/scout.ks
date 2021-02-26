@lazyGlobal off.
clearScreen.

runOncePath("0:/lib/lib_sci").

local sciFlag   is false.
local therm     is ship:partsDubbedPattern("thermometer")[0]:getModule("ModuleScienceExperiment").
local tel       is ship:rootPart:getmodule("ModuleScienceExperiment").

// Main
sci_deploy(therm).
sci_deploy(tel).
wait 1.
sci_recover(therm).
sci_recover(tel).

local ts to time:seconds + 10.
until time:seconds >= ts
{
    print "Countdown: " + round(time:seconds - ts) + " " at (2, 2).
}
stage.

when ship:availablethrust <= 0.1 then
{
    stage.
}

until ship:altitude >= 18000
{
    if not sciFlag
    {
        sci_deploy(therm).
        sci_deploy(tel).
        sci_recover(therm).
        sci_recover(tel).
        set sciFlag to true.
    }
    print_telemetry().
    wait 0.02.
}

set sciFlag to false.

until false
{
    if not sciFlag 
    {
        sci_deploy(therm).
        sci_deploy(tel).
        sci_recover(therm).
        sci_recover(tel).
        set sciFlag to true.
    }
    print_telemetry().
    wait 0.02.
}

// Functions
local function print_telemetry 
{
    print "Mission Time: " + round(missionTime) + "   " at (2, 2).
    print "Altitude    : " + round(ship:altitude) + "    " at (2, 3).
    print "AvailThrust : " + round(ship:availablethrust, 2) + "     " at (2, 4).
    print "MaxThrust   : " + round(ship:maxthrust, 2) + "     " at (2, 5).
}