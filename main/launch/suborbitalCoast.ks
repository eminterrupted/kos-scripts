@lazyGlobal off.
clearScreen.

parameter params is list().

runOncePath("0:/lib/loadDep").

DispMain(scriptPath(), false).

local coastStage to choose 1 if core:tag:split("|"):length <= 1 else core:tag:split("|")[1].
local ts to time:seconds + 10.

set g_orientation to "pro-body".
lock steering to sVal.

if params:length > 0
{
    set g_orientation to params[0].
}

OutMsg("Waiting for booster staging").
until time:seconds >= ts
{
    set sVal to GetSteeringDir(g_orientation).
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
    OutMsg("Coasting to apoapsis in retrograde").
    set ts to time:seconds + eta:apoapsis.
    InitWarp(ts, "near apoapsis").
    until time:seconds >= ts
    {
        set sVal to GetSteeringDir(g_orientation).
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