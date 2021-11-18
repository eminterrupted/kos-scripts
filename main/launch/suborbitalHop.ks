@lazyGlobal off.
clearScreen.

parameter param is list().

runOncePath("0:/lib/disp").
runOncePath("0:/lib/util").

DispMain(scriptPath(), false).

local coastStage to choose 1 if core:tag:split("|"):length <= 1 else core:tag:split("|")[1].
local ts to time:seconds + 10.

local rVal to 0.
local sVal to ship:prograde.
lock steering to sVal.

if param:length > 0
{
    set rVal to param[0].
}

OutMsg("Waiting for booster staging").
until time:seconds >= ts
{
    set sVal to ship:prograde.
    DispTelemetry().
    wait 0.01.
}
until stage:number = coastStage
{
    wait until stage:ready.
    stage.
}
OutMsg("Booster staged").

set ts to time:seconds + 2.5.
until time:seconds >= ts
{
    DispTelemetry().
    wait 0.01.
}

set ts to time:seconds + 10.
OutMsg("Orienting to retrograde").
until time:seconds >= ts 
{
    set sVal to lookDirUp(ship:retrograde:vector, sun:position) + r(0, 0, rVal).
    DispTelemetry().
    wait 0.01.
}

if ship:crew:length > 0
{ 
    OutMsg("Control released to pilot").
    unlock steering.
    wait 2.5.
    
    OutMsg("Coasting to apoapsis").
    set ts to time:seconds + eta:apoapsis.
    InitWarp(ts, "near apoapsis").
    until time:seconds >= ts
    {
        DispTelemetry().
        wait 0.01.
    }
}
else
{
    OutMsg("Coasting to apoapsis").
    set ts to time:seconds + eta:apoapsis.
    InitWarp(ts, "near apoapsis").
    until time:seconds >= ts
    {
        set sVal to lookDirUp(ship:retrograde:vector, sun:position) + r(0, 0, rVal).
        DispTelemetry().
        wait 0.01.
    }
}

until time:seconds >= ts
{
    DispTelemetry().
    wait 0.01.
}
sas off.
OutMsg("Suborbital script complete!").
wait 2.5.