@LazyGlobal off.
ClearScreen.

parameter params is list().

RunOncePath("0:/lib/libLoader.ks").
RunOncePath("0:/lib/launch.ks").

set g_MainProcess to ScriptPath().
DispMain().

set Core:Part:Tag to Core:Part:Tag:Replace("Orbit", "Circularize").
set g_MissionTag to ParseCoreTag(core:Part:Tag).
set g_MissionTag:Params to g_MissionTag:PARAMS.

local _azData   to g_azData.
local _stgAtETA to ETA:Apoapsis - 60.
local _stpStg   to g_StageLimit.

if params:length > 0
{
    set _stpStg to params[0].
    if params:length > 1 set _stgAtETA to params[1].
    if params:length > 2 set _azData to params[2].
}

if _azData:Length = 1
{
    set _azData to l_az_calc_init(g_MissionTag:Params[1], g_MissionTag:Params[0], _azData[0]).
}
else if _azData:Length = 0
{
    set _azData to l_az_calc_init(g_MissionTag:Params[1], g_MissionTag:Params[0], Ship:Latitude).
}
// else
// {
//     set _azData to l_az_calc_init(g_MissionTag:Params[1], g_MissionTag:Params[0]).
// }

set g_StageLimit to _stpStg.

set g_SteeringDelegate to GetOrbitalSteeringDelegate("AngErr:Sun").

OutMsg("Waiting until timestamp").
set s_Val to g_SteeringDelegate:Call().
lock steering to s_Val.
set t_Val to 0.
lock throttle to t_Val.
OutInfo("Home: Warp | End: CancelWarp | Arrows (L/R): -/+ 1s | (U/D): -/+ 5s", 1).
until ETA:Apoapsis <= _stgAtETA + 5
{
    // set s_Val to heading(compass_for(Ship, Ship:Prograde), 0, 0).
    set s_Val to g_SteeringDelegate:Call().

    GetTermChar().
    if g_TermChar = Terminal:Input:HomeCursor
    {
        OutInfo("Warping to timestamp - 30s", 1).
        wait 0.01.
        set warp to 1.
        wait until KUniverse:TimeWarp:IsSettled.
        WarpTo(Time:Seconds + _stgAtETA - 30).
    }
    else if g_TermChar = Terminal:Input:EndCursor
    {
        set warp to 0.
        OutInfo("Warp Cancelled", 1).
        wait until KUniverse:TimeWarp:IsSettled.
    }
    else if g_TermChar = Terminal:Input:RightCursorOne
    {
        set _setAtETA to _stgAtETA + 1.
    }
    else if g_TermChar = Terminal:Input:UpCursorOne
    {
        set _stgAtETA to _stgAtETA + 5.
    }
    else if g_TermChar = Terminal:Input:LeftCursorOne
    {
        set _stgAtETA to _stgAtETA - 1.
    }
    else if g_TermChar = Terminal:Input:DownCursorOne
    {
        set _stgAtETA to _stgAtETA - 5.
    }
    set g_TermChar to "".

    OutInfo("Time Remaining: {0}s  ":Format(round(ETA:Apoapsis - _stgAtETA, 2))).
    DispLaunchTelemetry().
}
OutInfo().
OutInfo("", 1).
local nextEngs to GetNextEngines().
local nextStageIsSep to false.
if nextEngs:Length > 0
{
    for eng in nextEngs
    {
        if eng:tag = "" and g_PartInfo:Engines:SepRef:Contains(eng:name)
        {
            set nextStageIsSep to true.
        }
    }
}

if not nextStageIsSep
{
    rcs on.
    OutMsg("Performing ullage manuever").
    set t_Val to 1.
}
else
{
    OutMsg("Sep motors detected, awaiting ignition").
    wait 1.
}

until ETA:Apoapsis <= _stgAtETA
{
    set s_Val to g_SteeringDelegate:Call().
    OutInfo("Time Remaining: {0}s  ":Format(round(ETA:Apoapsis - _stgAtETA, 2))).
    DispLaunchTelemetry().
}

OutMsg("Arming AutoStaging to {0}":Format(_stpStg)).
OutInfo().

set t_Val to 1.
ArmAutoStagingNext(_stpStg, 1, 1).

until Stage:Number = g_StageLimit
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

    set s_Val to g_SteeringDelegate:Call().
    DispLaunchTelemetry().
    wait 0.01.
}
wait 1.
set g_ActiveEngines_Data to GetEnginesPerformanceData(GetActiveEngines()).
until g_ActiveEngines_Data:Thrust <= 0.01
{
    set s_Val to g_SteeringDelegate:Call().
    set g_ActiveEngines_Data to GetEnginesPerformanceData(GetActiveEngines()).
    DispLaunchTelemetry().
    wait 0.01.
}
set t_Val to 0.
unlock Throttle.
unlock Steering.

OutInfo().
OutMsg("circAtApo complete").