@LazyGlobal off.
ClearScreen. 

parameter params is list().

RunOncePath("0:/lib/loadDep").
RunOncePath("0:/lib/land").

DispMain(ScriptPath()).

local impactAlt     to -Body:Radius / 2.
local orientation   to "retro-sun".
local radarAlt      to 0.
local tti           to -1.
local vBounds       to Ship:Bounds.

local sVal to GetSteeringDir(orientation).
local tVal to 0.

if params:length > 0 
{
    set impactAlt to params[0].
}

lock steering to sVal.
lock throttle to tVal.

if Ship:ModulesNamed("ModuleRCSFX"):Length > 0 
{
    rcs on.
}
wait 0.1.

ArmAutoStaging().

if Ship:Periapsis > impactAlt
{
    OutMsg("Press Enter to initiate impact burn").
    until false
    {
        set g_termChar to GetInputChar().
        if CheckChar(Terminal:Input:Enter)
        {
            break.
        }
        OutInfo("Steering error: " + round(steeringManager:angleError, 5)).
        DispTelemetry().
    }
    OutInfo().
    wait 0.1.

    OutMsg("Aligning for P1 impact burn").
    until CheckSteering(1)
    {
        OutInfo("Steering error: " + round(steeringManager:angleError, 5)).
        DispTelemetry().
    }
    OutInfo().
    wait 0.1.

    DeorbitBurn().
}
else
{
    OutMsg("Vessel already on impact trajectory!").
}
wait 0.1.
set orientation to "body-pro".

OutMsg("Aligning to Body-Prograde").
until CheckSteering(0.100)
{
    set radarAlt    to vBounds:BottomAltRadar.
    set tti         to TimeToImpact(Ship:VerticalSpeed, radarAlt).
    OutInfo("Steering error: " + round(steeringManager:angleError, 5)).
    DispImpact(tti, radarAlt).
}
OutInfo().
wait 0.1.

OutMsg("Descent coast phase").
OutInfo("Press Enter to warp to 10000m").
until radarAlt <= 10000
{
    if CheckWarpKey() 
    {
        WarpToAlt(10000).
    }
    set radarAlt    to vBounds:BottomAltRadar.
    set tti         to TimeToImpact(Ship:VerticalSpeed, radarAlt).
    DispImpact(tti, radarAlt).
}
wait 0.1.

OutMsg("P2 impact burn").
set tVal to 1.
until Ship:AvailableThrust <= 0.1
{
    set radarAlt    to vBounds:BottomAltRadar.
    set tti         to TimeToImpact(Ship:VerticalSpeed, radarAlt).
    DispImpact(tti, radarAlt).
}
set tVal to 0.

OutMsg("Impact iminent").
until radarAlt <= 0
{
    set radarAlt    to vBounds:BottomAltRadar.
    set tti         to TimeToImpact(Ship:VerticalSpeed, radarAlt).
    DispImpact(tti, radarAlt).
}



// Local Functions
local function DeorbitBurn
{
    set tVal to 1. 
    OutMsg("Deorbit burn: Engine ignition").
    until Ship:Periapsis < impactAlt
    {
        if g_staged
        {
            set vBounds to Ship:Bounds.
        }
        set radarAlt    to vBounds:BottomAltRadar.
        set sVal        to GetSteeringDir(orientation).
        set tti         to TimeToImpact(Ship:VerticalSpeed, radarAlt).
        DispImpact(tti, radarAlt).
    }
    set tVal to 0.
}