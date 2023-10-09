@LazyGlobal off.
ClearScreen.

parameter params is list().

RunOncePath("0:/lib/libLoader.ks").
RunOncePath("0:/lib/launch.ks").

set g_MainProcess to ScriptPath().
DispMain().

set g_MissionTag to ParseCoreTag(Core:Part:Tag).
set g_MissionTag:Params to g_MissionTag:PARAMS.

local azData   to g_azData.
local tgtAp   to Ship:Apoapsis.

if params:length > 0
{
    set tgtAp to params[0].
    if params:length > 1 set azData to params[1].
}

if azData:Length = 1
{
    set azData to l_az_calc_init(g_MissionTag:Params[1], g_MissionTag:Params[0], azData[0]).
}
else if azData:Length = 0
{
    set azData to l_az_calc_init(g_MissionTag:Params[1], g_MissionTag:Params[0], Ship:Latitude).
}

local dvNeeded to CalcDvHoh(Ship:Periapsis, 0, Ship:Apoapsis, Ship:Body)[0].
local burnDur  to CalcBurnDur(dvNeeded).
local burnTS to Time:Seconds + (ETA:Apoapsis - burnDur[3]).
local mecoTS to burnTS + burnDur[1].

set g_SteeringDelegate to GetOrbitalSteeringDelegate("Flat:Sun", 0.9925).

OutMsg("Waiting until timestamp").
SAS Off.

set s_Val to g_SteeringDelegate:Call().
lock steering to s_Val.

until Time:Seconds >= burnTS - 5
{
    // set s_Val to heading(compass_for(Ship, Ship:Prograde), 0, 0).
    set s_Val to g_SteeringDelegate:Call().

    GetTermChar().
    if g_TermChar = Terminal:Input:HomeCursor
    {
        OutMsg("Warping to timestamp - 30s").
        wait 0.01.
        set warp to 1.
        wait until KUniverse:TimeWarp:IsSettled.
        WarpTo(burnTS - 30).
    }
    else if g_TermChar = Terminal:Input:EndCursor
    {
        set warp to 0.
        OutMsg("Warp Cancelled").
        wait until KUniverse:TimeWarp:IsSettled.
    }
    set g_TermChar to "".

    OutInfo("Time Remaining: {0}s  ":Format(round(burnTS - Time:Seconds, 2))).
    DispLaunchTelemetry().
}

RCS on.
OutMsg("Performing ullage manuever").
set Ship:Control:Fore to 1.

until Time:Seconds >= burnTS
{
    set s_Val to g_SteeringDelegate:Call().
    OutInfo("Time Remaining: {0}s  ":Format(round(burnTS - Time:Seconds, 2))).
    DispLaunchTelemetry().
    wait 0.01.
}

OutMsg("Arming AutoStaging to {0}":Format(g_StageLimit)).
OutInfo().

set t_Val to 1.
lock throttle to t_Val.
ArmAutoStagingNext(g_StageLimit, 1, 2).
wait 0.01.
set Ship:Control:Fore to 0.

set g_SteeringDelegate to GetOrbitalSteeringDelegate("PIDApoErr:Sun").

local rollFlag to false.
local apoFlag to false.

until Stage:Number = g_StageLimit or apoFlag// or Time:Seconds >= mecoTS or apoFlag
{
    set g_ActiveEngines to GetActiveEngines().
    set g_ActiveEngines_Data to GetEnginesPerformanceData(GetActiveEngines()).
    if g_LoopDelegates:HasKey("Staging")
    {
        if g_LoopDelegates:Staging:Check:Call() = 1
        {
            g_LoopDelegates:Staging["Action"]:Call().
        }
    }
    
    if g_LoopDelegates["Events"]:Keys:Length > 0 
    {
        ExecGLoopEvents().
    }

    GetTermChar().
    if g_TermChar = "e"
    {
        if Ship:Control:Roll < 0 
        {
            set Ship:Control:Roll to 0.
            set rollFlag to false.
        }
        else
        {
            set Ship:Control:Roll to 1.
            set rollFlag to true.
        }
    }
    else if g_TermChar = "q"
    {
        if Ship:Control:Roll > 0 
        {
            set Ship:Control:Roll to 0.
            set rollFlag to false.
        }
        else
        {
            set Ship:Control:Roll to -1.
            set rollFlag to true.
        }
    }
    set g_TermChar to "".

    if Ship:Apoapsis >= tgtAp - 10000 and Ship:Apoapsis <= tgtAp + 10000 
    {
        set apoFlag to true.
    }
    else 
    {
        OutInfo("TIME TO MECO: {0} ":Format(Round(mecoTS - Time:Seconds))).
    }


    set s_Val to choose g_SteeringDelegate:Call():Vector if rollFlag else choose Ship:Prograde if apoFlag else g_SteeringDelegate:Call().
    
    DispLaunchTelemetry().
    wait 0.01.
}

wait 0.25.
OutMsg("Final Stage").
set g_ActiveEngines to GetActiveEngines().

local MECOFlag to False.

until MECOFlag
{
    set g_ActiveEngines_Data to GetEnginesPerformanceData(GetActiveEngines()).

    GetTermChar().
    if g_TermChar = "e"
    {
        if Ship:Control:Roll < 0 
        {
            set Ship:Control:Roll to 0.
            set rollFlag to false.
        }
        else
        {
            set Ship:Control:Roll to 1.
            set rollFlag to true.
        }
    }
    else if g_TermChar = "q"
    {
        if Ship:Control:Roll > 0 
        {
            set Ship:Control:Roll to 0.
            set rollFlag to false.
        }
        else
        {
            set Ship:Control:Roll to -1.
            set rollFlag to true.
        }
    }
    set g_TermChar to "".

    set s_Val to choose g_SteeringDelegate:Call():Vector if rollFlag else g_SteeringDelegate:Call().
    set g_ActiveEngines_Data to GetEnginesPerformanceData(GetActiveEngines()).
    if g_ActiveEngines_Data:HasKey("Thrust") 
    {
        if g_ActiveEngines_Data:Thrust <= 0.01
        {
            if g_Debug { OutDebug("g_ActiveEngines_Data:Thrust ({0}) < 0.01":Format(g_ActiveEngines_Data:Thrust), 5).}
            set MECOFlag to true.
        }
    }

    if Ship:Periapsis >= (tgtAp * 0.9975)
    {
        if g_Debug { OutDebug("ShipPeriapsis >= {0} * 0.9975 [{1}]":Format(tgtAp, (tgtAp * 0.9975)), 5).}
        set MECOFlag to True.
    }
    else if Time:Seconds >= mecoTS
    {
        if g_Debug { OutDebug("Time:Seconds({0}) >= mecoTS({1})":Format(Time:Seconds, mecoTS), 5). }
        // set MECOFlag to True.
    }
    else 
    {
        OutInfo("TIME TO MECO: {0} ":Format(Round(mecoTS - Time:Seconds))).
    }
    
    DispLaunchTelemetry().
    wait 0.01.
}
set t_Val to 0.
wait 1.
if Ship:AvailableThrust > 0.01
{
    OutMsg("Waiting for engine burnout").
    until g_ActiveEngines_Data:Thrust <= 0.01
    {
        set s_Val to g_SteeringDelegate:Call().
        set g_ActiveEngines_Data to GetEnginesPerformanceData(GetActiveEngines()).
        DispLaunchTelemetry().
        wait 0.01.
    }
}
unlock Throttle.
unlock Steering.

OutInfo().
OutMsg("circAtApo complete").