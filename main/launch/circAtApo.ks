@LazyGlobal off.
ClearScreen.

parameter params is list().

RunOncePath("0:/lib/libLoader.ks").
RunOncePath("0:/lib/launch.ks").

set g_MainProcess to ScriptPath().
DispMain().

set g_TS to Time:Seconds + 3.

until g_TermChar = Terminal:Input:Enter or Time:Seconds >= g_TS
{
    GetTermChar().
    if not g_Debug
    {
        CheckKerbaliKode().
    }
    else
    {
        Break.
    }
    wait 0.01.
}

set g_MissionTag to ParseCoreTag(Core:Part:Tag).

local azData    to g_azData.
local tgtAp     to Ship:Apoapsis.
local tgtPe     to Ship:Apoapsis.
local tgtInc    to g_MissionTag:Params[0].
local transferBurn to False.

if g_MissionTag:Params:Length > 2
{
    if g_MissionTag:Params[2] > tgtAp * 1.1 set transferBurn to True.
    set tgtAp to g_MissionTag:Params[2].
}

if params:length > 0
{
    if params[0] > tgtAp * 1.1 set transferBurn to True.
    set tgtAp to params[0].
    if params:length > 1 set tgtPe to params[1].
    if params:length > 2 set azData to params[2].
}

if azData:Length = 1
{
    set azData to l_az_calc_init(tgtAp, tgtInc, azData[0]).
    set g_azData to azData.
}
else if azData:Length = 0
{
    set azData to l_az_calc_init(tgtAp, tgtInc, Ship:Latitude).
    set g_azData to azData.
}
set g_AngDependency to InitAscentAng_Next(tgtInc, tgtAp, 1, 2.5, 22.5, True, list(0.0125, 0.000925, 0.0005, 1)). // P, I, D, ChangeRate (upper / lower bounds for PID)

//local dvNeeded to CalcDvHoh(Ship:Periapsis, 0, Ship:Apoapsis, Ship:Body)[0].
local dvNeeded to CalcDvBE(Ship:Periapsis, Ship:Apoapsis, tgtPe, tgtAp, Ship:Apoapsis, "PE")[1].
OutInfo("dvNeeded: {0}":Format(Round(dvNeeded, 1)), 1).
local burnDur  to CalcBurnDur(dvNeeded).

// TODO Experimental
if false
{
    local burnObj to CalcBurnStageData(dvNeeded).
}

local burnTS to choose (Time:Seconds + ETA:Apoapsis - burnDur[3]) if ETA:Apoapsis < ETA:Periapsis else Time:Seconds + 10.
local mecoTS to burnTS + burnDur[1].
local burnLeadTime to 15.
local warpToTS to burnTS - burnLeadTime.

local tgtCheckDelAP to { return (Ship:Apoapsis >= tgtAp and Ship:Periapsis >= Max(Ship:Body:Atm:Height + 5000, tgtPe * 0.9875)). }.
local tgtCheckDelPE to { return Ship:Periapsis >= tgtPe.}.
local tgtCheckDel to choose tgtCheckDelAP@ if transferBurn else tgtCheckDelPE@.

set g_ActiveEngines to GetActiveEngines().
set g_ActiveEngines_Data to GetEnginesPerformanceData(g_ActiveEngines).
set g_ActiveEngines_Spec to GetEnginesSpecs(g_ActiveEngines).

set g_SteeringDelegate to GetOrbitalSteeringDelegate("Flat:Sun", 0.9925).

OutMsg("Waiting until timestamp").
SAS Off.

set s_Val to g_SteeringDelegate:Call().
lock steering to s_Val.

local warpFlag to False.

until Time:Seconds >= burnTS - g_UllageDefault
{
    // set s_Val to heading(compass_for(Ship, Ship:Prograde), 0, 0).
    GetTermChar().

    set s_Val to g_SteeringDelegate:Call().
    
    local burnETA to Round(burnTS - Time:Seconds, 2).

    if Kuniverse:TimeWarp = 0 set warpFlag to False.
    // if g_TermChar = Terminal:Input:HomeCursor
    // {
    //     OutMsg("Warping to timestamp - 30s").
    //     wait 0.01.
    //     set warp to 1.
    //     wait until KUniverse:TimeWarp:IsSettled.
    //     WarpTo(burnTS - 30).
    // }
    // else if g_TermChar = Terminal:Input:EndCursor
    // {
    //     set warp to 0.
    //     OutMsg("Warp Cancelled").
    //     wait until KUniverse:TimeWarp:IsSettled.
    // }
    if not warpFlag OutMsg("Press Shift+W to warp to [maneuver - {0}s]":Format(burnLeadTime)).
    
    if g_termChar = ""
    {
    }
    else if g_termChar = Char(87)
    {
        if burnETA > burnLeadTime 
        {
            set warpFlag to True. 
            OutMsg("Warping to maneuver").
            OutInfo().
            OutInfo("", 1).
            OutInfo("", 2).
            WarpTo(warpToTS).
        }
        else
        {
            OutMsg("Maneuver <= {0}s, skipping warp":Format(burnLeadTime)).
        }
        set g_termChar to "".
    }
    
    if not warpFlag 
    {
        set burnLeadTime to UpdateTermScalar(burnLeadTime, list(1, 5, 15, 30)).
        set warpToTS to (burnTS - burnLeadTime).
    }
    set g_TermChar to "".

    OutInfo("Time Remaining: {0}s  ":Format(burnETA), 2).
    DispLaunchTelemetry().
}
OutInfo("",-1).
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

set g_HotStagingArmed   to ArmHotStaging().
set g_SpinArmed         to SetupSpinStabilizationEventHandler().

local onStageParts to Ship:PartsTaggedPattern("^OnStage").
if onStageParts:Length > 0
{
    set g_OnStageEventArmed to SetupOnStageEventHandler(onStageParts).
}

// #TODO: Implement circ event handlers
// local eventParts to Ship:PartsTaggedPattern("^Circ\|.*").
// local eventPartCount to 0.
// if eventParts:Length > 0 
// {
//     set eventPartCount to ArmAscentEvents(eventParts).
// }

local autoStageResult to ArmAutoStagingNext(g_StageLimit, 0, 2).
set g_AutoStageArmed  to choose True if autoStageResult = 1 else False.

wait 0.01.
set Ship:Control:Fore to 0.

set g_SteeringDelegate to choose GetOrbitalSteeringDelegate("Flat:Sun") if transferBurn else GetOrbitalSteeringDelegate("PIDApoErr:Sun").

local rollFlag to false.
local doneFlag to false.

until Stage:Number <= g_StageLimit or doneFlag// or Time:Seconds >= mecoTS or apoFlag
{
    set g_ActiveEngines to GetActiveEngines().
    set g_ActiveEngines_Data to GetEnginesPerformanceData(GetActiveEngines()).
    if g_LoopDelegates:HasKey("Staging")
    {
        if g_HotStagingArmed and g_NextHotStageID = Stage:Number - 1
        { 
            if g_LoopDelegates:Staging:HotStaging:HasKey(g_NextHotStageID)
            {
                if g_LoopDelegates:Staging:HotStaging[g_NextHotStageID]:Check:CALL()
                {
                    g_LoopDelegates:Staging:HotStaging[g_NextHotStageID]:Action:CALL().
                }
            }
        }
        else
        {
            if g_LoopDelegates:Staging:Check:Call() = 1
            {
                g_LoopDelegates:Staging["Action"]:Call().
            }
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

    // if (Ship:Periapsis >= tgtPe - 5000 and Ship:Periapsis <= tgtPe + 5000)
    if tgtCheckDel:Call() // Ship:Periapsis >= tgtPe - 5000
    {
        set doneFlag to true.
    }
    else 
    {
        OutInfo("TIME TO MECO: {0} ":Format(Round(mecoTS - Time:Seconds))).
    }

    set s_Val to choose g_SteeringDelegate:Call():Vector if rollFlag else choose Ship:Prograde if doneFlag else g_SteeringDelegate:Call().
    
    DispLaunchTelemetry().
    wait 0.01.
}
OutInfo().
wait 0.05.
OutMsg("Final Stage").
set g_ActiveEngines to GetActiveEngines().

local MECOFlag to False.

until MECOFlag or doneFlag
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
        if g_ActiveEngines_Data:Thrust = 0 and g_ActiveEngines:Length > 0
        {
            if g_Debug { OutDebug("g_ActiveEngines_Data:Thrust ({0}) < 0.001":Format(g_ActiveEngines_Data:Thrust), 5).}
            set MECOFlag to true.
        }
    }

    if tgtCheckDel:Call()// Ship:Periapsis >= (tgtPe * 0.995)
    {
        if g_Debug 
        { 
            if transferBurn
            {
                OutDebug("ShipApoapsis >= {0} ":Format(tgtAp), 5).
            }
            else
            {
                OutDebug("ShipPeriapsis >= {0} ":Format(tgtPe), 5).
            }
        }
        set MECOFlag to True.
    }
    // else if Time:Seconds >= mecoTS
    // {
    //     if g_Debug { OutDebug("Time:Seconds({0}) >= mecoTS({1})":Format(Time:Seconds, mecoTS), 5). }
    //     // set MECOFlag to True.
    // }
    else 
    {
        OutInfo("TIME TO MECO: {0} ":Format(Round(mecoTS - Time:Seconds))).
    }
    
    DispLaunchTelemetry().
    wait 0.01.
}
set t_Val to 0.
OutInfo().
wait 0.25.

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