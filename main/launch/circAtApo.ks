@LazyGlobal off.
ClearScreen.

parameter params is list().

RunOncePath("0:/lib/libLoader.ks").
RunOncePath("0:/lib/launch.ks").

DispMain().

set g_MissionTag to ParseCoreTag(core:Part:Tag).

local _stgAtTS to Time:Seconds + ETA:Apoapsis - 30.
local _stpStg  to 0.

if params:length > 0
{
    set _stpStg to params[0].
    if params:length > 1 set _stgAtTS to params[1].
}

set g_StageLimit to _stpStg.

local steeringDelegate to GetOrbitalSteeringDelegate().

OutMsg("Waiting until timestamp").
set s_Val to ship:facing.
lock steering to s_Val.
set t_Val to 0.
lock throttle to t_Val.

until Time:Seconds >= _stgAtTS
{
    // set s_Val to heading(compass_for(Ship, Ship:Prograde), 0, 0).
    GetTermChar().
    if g_TermChar = Terminal:Input:HomeCursor
    {
        OutMsg("Warping to timestamp - 15s").
        wait 0.01.
        set warp to 1.
        wait until KUniverse:TimeWarp:IsSettled.
        WarpTo(_stgAtTS - 15).
        set g_TermChar to "".
    }
    else if g_TermChar = Terminal:Input:EndCursor
    {
        set warp to 0.
        OutMsg("Warp Cancelled").
        wait until KUniverse:TimeWarp:IsSettled.
    }
    steeringDelegate:Call().
    OutInfo("Time Remaining: {0}s  ":Format(round(_stgAtTS - Time:Seconds, 2))).
    DispLaunchTelemetry().
}

OutInfo().
OutMsg("Arming AutoStaging to {0}":Format(_stpStg)).
set t_Val to 1.

ArmAutoStagingNext(_stpStg, 1, 0).

until Stage:Number <= g_StageLimit
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
        ExecLoopEventDelegates().
    }

    steeringDelegate:Call().
    DispLaunchTelemetry().
    wait 0.01.
}

set g_ActiveEngines_Data to GetEnginesPerformanceData(GetActiveEngines()).
until g_ActiveEngines_Data:Thrust >= 0.2
{
    set g_ActiveEngines_Data to GetEnginesPerformanceData(GetActiveEngines()).
    DispLaunchTelemetry().
    wait 0.01.
}