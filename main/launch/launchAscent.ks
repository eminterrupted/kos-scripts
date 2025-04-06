@LazyGlobal off.
ClearScreen.

parameter params to list().

RunOncePath("0:/lib/libLoader.ks").
RunOncePath("0:/lib/launch.ks").

set g_MainProc to ScriptPath().
DispMain().

local engineCounter      to 0.
local stagingCheckResult to 0.

// Parameter default values.
local _tgtAp         to -1.
local _tgtInc        to 0.
local _tgtPe         to -1.
local _azObj         to g_AzData.

// P2: Setting up params 
set g_Program to 2.


if defined g_MissionTag
{
    if g_MissionTag:Keys:Length = 0 set g_MissionTag to ParseCoreTag().
}

if g_MissionTag:Params:Length > 0
{
    set _tgtInc to g_MissionTag:Params[0].
    if g_MissionTag:Params:Length > 1 set _tgtAp to g_MissionTag:Params[1].
    if g_MissionTag:Params:Length > 2 set _tgtPe to g_MissionTag:Params[2].
    if g_MissionTag:Params:Length > 3 set _azObj to g_MissionTag:Params[3].
}

if params:length > 0
{
    set _tgtInc to params[0].
    if params:length > 1 set _tgtAp to params[1].
    if params:length > 2 set _tgtPe to params[2].
    if params:length > 3 set _azObj to params[3].
}

if _tgtAp <= 0
{
    set _tgtAp to 250000.
}
if _tgtPe <= 0
{
    set _tgtPe to _tgtAp.
}

wait until Ship:Unpacked.
wait until KUniverse:Timewarp:IsSettled.

local towerHeight to Min(g_PresetTurnAlt, Max(100, Ship:Altitude + Ship:Bounds:Size:Z)). // Altitude at which the vessel will begin a gravity turn
                                                                                         // taken from the bounding box of the ship on the launch pad

global g_launchParams to list(g_MissionTag:STGSTOPSET, g_MissionTag:PARAMS, g_MissionTag:STGSTOPSET).

set   g_BoostersArmed to False.
local boosterCheckDel  to { return True.}.
local boosterActionDel to { return False.}.
local boosterResult to list(false, boosterCheckDel, boosterActionDel).

set g_ShipEngines_Spec to GetShipEnginesSpecs(Ship).

local termCount to GetTerminalCountdown().
local letsgoTS to WaitForLaunchCommit(termCount).
local launchObj to PreLaunchInit(_tgtAp, _tgtInc).

set g_BoostersArmed to launchObj:BoosterResult[0].
set boosterCheckDel to launchObj:BoosterResult[1].
set boosterActionDel to launchObj:BoosterResult[2].

// set g_HotStagingArmed to launchObj:HotStagingResult[0].
// set g_OnStageEventArmed to launchObj:OSPResult[0].

ClearScreen.
DispMain(ScriptPath()).

SendCoreMessage("P03_COUNTDOWN").

OutMsg("GO for launch! Resuming countdown").
// wait 0.125.
set t_val to 0.
lock Throttle to t_val.

// for p in Ship:PartsNamedPattern("AM.MLP.SoyuzLaunchBaseArm(SM|LG)")
// {
//     OutInfo("[{0}] Commencing retract on countdown":Format(count:ToString)).
//     RetractSwingArm(p).
//     set count to count + 1.
//     set termCount to Min(10, termCount + count).
// }
// for p in Ship:PartsTaggedPattern("RetractOnCountdown")
// {
//     OutInfo("[{0}] Commencing retract on countdown":Format(count:ToString)).
//     RetractSwingArm(p).
//     set count to count + 1.
//     set termCount to Min(10, termCount + count).
// }

LaunchCountdown(termCount).
OutInfo().
OutInfo("",1).

local asr to ArmAutoStagingNext(g_StageLimit, 1, 2).
set launchObj["autoStageResult"] to asr.
set g_AutoStageArmed to asr = 1.



set s_Val to Ship:Facing.
lock steering to s_Val.

OutMsg().
OutInfo().
OutInfo("g_DecouplerEventArmed: {0}":Format(g_DecouplerEventArmed),1).
OutMsg("Liftoff! ").
wait 0.125.

set g_ActiveEngines to GetActiveEngines(Ship, "NoBooster").
set g_ActiveEngines_Data to GetEnginesPerformanceData(g_ActiveEngines).
set g_NextEngines   to GetNextEngines().

set g_SpinArmed to SetupSpinStabilizationEventHandler().
DispMain(ScriptPath()).
ClearDispBlock().

OutMsg("Vertical Ascent").
until Alt:Radar >= towerHeight
{
    set g_ActiveEngines to GetActiveEngines(Ship, "NoBooster").
    set g_ActiveEngines_Data to GetEnginesPerformanceData(g_ActiveEngines).

    if g_BoostersArmed
    {
        if boosterCheckDel:Call()
        {
            set boosterResult to boosterActionDel:Call().
            set g_BoostersArmed to boosterResult[0].
            if g_BoostersArmed
            {
                set boosterCheckDel  to boosterResult[1].
                set boosterActionDel to boosterResult[2].
            }
            else
            {
                set boosterResult to list(false, g_NulCheckDel, g_NulActionDel).
                clr(cr()).
            }
        }
        else
        {
            OutInfo("Booster staging: Armed").
        }
    }
    if g_LoopDelegates:HasKey("Staging")
    {
        if g_HotStagingArmed and g_NextHotStageID = Stage:Number - 1 and not g_BoostersArmed and not g_MECOArmed
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
            set stagingCheckResult to g_LoopDelegates:Staging:Check:Call().
            // OutInfo("Checking staging delegate {0}":Format(stagingCheckResult), 2).
            if stagingCheckResult = 1
            {
                OutInfo("Staging", 2).
                g_LoopDelegates:Staging["Action"]:Call().
            }
        }
    }
    
    DispEngineTelemetry().
    DispLaunchTelemetry().
    DispStateFlags().
}
ClearDispBlock().

local nextFlag to False.

OutMsg("Gravity Turn").
until Stage:Number <= g_StageLimit// or Ship:Apoapsis >= Max(Body:ATM:Height, _tgtAp * 0.75)
{
    set g_ActiveEngines to GetActiveEngines(Ship, "NoBooster").
    set g_ActiveEngines_Data to GetEnginesPerformanceData(g_ActiveEngines).
    set s_Val to g_SteeringDelegate:Call().

    if g_BoostersArmed
    {
        if boosterCheckDel:Call()
        {
            set boosterResult to boosterActionDel:Call().
            set g_BoostersArmed to choose boosterResult[0] if boosterResult:IsType("List") else False.
            if g_BoostersArmed
            {
                set boosterCheckDel  to boosterResult[1].
                set boosterActionDel to boosterResult[2].
            }
            else
            {
                set boosterResult to list(false, g_NulCheckDel, g_NulActionDel).
                set g_BoostersArmed to false.
                clr(cr()).
            }
        }
        else
        {
            OutInfo("Booster staging: Armed").
        }
    }

    if g_LoopDelegates:HasKey("Staging")
    {
        // if g_HotStagingArmed and g_NextHotStageID = Stage:Number - 1 and not g_BoostersArmed and not g_MECOArmed
        if g_NextHotStageID = Stage:Number - 1 and not g_BoostersArmed and not g_MECOArmed
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
            set stagingCheckResult to g_LoopDelegates:Staging["Check"]:Call().
            // OutInfo("Checking staging delegate [{0}]":Format(stagingCheckResult), 2).
            if stagingCheckResult = 1
            {
                if g_Debug OutDebug("Checking staging delegate [{0}]":Format(stagingCheckResult), 1).
                g_LoopDelegates:Staging["Action"]:Call().
            }
        }
    }
    
    if g_LoopDelegates["Events"]:Keys:Length > 0 
    {
        ExecGLoopEvents().
    }

    DispEngineTelemetry().
    DispStateFlags().
    DispLaunchTelemetry().
    if g_PID_Enabled 
    {
        DispPIDLoopValues(g_PIDS["TurnApo"]).
    }
    else if g_GridAssignments:Keys:Contains("PID_VALUES")
    {
        ClearDispBlock("PID_VALUES").
    }
}
ClearDispBlock().

// if Stage:Number <= g_StageLimit
// {
//     OutInfo("Disabling Autostaging").
//     set g_AutoStageArmed to DisableAutoStaging().
// }

OutMsg("Final Burn").
wait 0.05.

set nextFlag to False.
until nextFlag
{
    GetTermChar().

    if g_TermChar:Length > 0
    {
        if g_TermChar = Terminal:Input:DeleteRight
        {
            OutMsg("** Manual launch burn cutoff engaged **").
            OutInfo().
            OutInfo("", 1).
            OutInfo("", 2).
            set nextFlag to True.
        }
    }

    set s_Val to g_SteeringDelegate:Call().
    set g_ActiveEngines to GetActiveEngines(Ship, "NoBooster").
    set g_ActiveEngines_Data to GetEnginesPerformanceData(g_ActiveEngines).

    if Stage:Number <= g_StageLimit
    {
        OutInfo("Disabling Autostaging").
        set g_AutoStageArmed to DisableAutoStaging().
    }

    if Ship:AvailableThrust <= 0.1
    {
        if g_Debug OutDebug("Ship:AvailableThrust thresh met").
        if Ship:Apoapsis >= _tgtAp * 1.025
        {
            if g_Debug OutDebug("nextFlag set (Apo[{0}] >= _tgtAp[{1}]) thresh met":Format(Round(Ship:Apoapsis, Round(_tgtAp * 1.025)))).
            set nextFlag to True.
        }
        else if not g_AutoStageArmed
        {
            if g_Debug OutDebug("nextFlag set (Autostage disabled)").
            set nextFlag to True.
        }
        else
        {
            if g_Debug OutDebug("nextFlag not set (Below apo thresh and Autostage enabled)").
            set nextFlag to True.
        }
    }
    else if Ship:Periapsis >= _tgtPe * 0.999
    {
        if g_Debug OutDebug("nextFlag set (Pe{0}] >= _tgtPe[{1}]) thresh met":Format(Round(Ship:Periapsis, Round(_tgtPe * 0.999)))).
        set nextFlag to True.
    }
    else
    {    
        if g_BoostersArmed
        {
            if boosterCheckDel:Call()
            {
                if g_BoostersArmed
                {
                    set boosterResult to boosterActionDel:Call().
                    set g_BoostersArmed to boosterResult[0].
                    set boosterCheckDel  to boosterResult[1].
                    set boosterActionDel to boosterResult[2].
                }
                else
                {
                    set boosterResult to list(false, g_NulCheckDel, g_NulActionDel).
                    OutInfo("Arming Hot Stage", 1).
                    set g_HotStagingArmed to ArmHotStaging().
                    clr(cr()).
                }
            }
            else
            {
                OutInfo("Booster staging: Armed").
            }
        }
    }

    if g_LoopDelegates["Events"]:Keys:Length > 0 
    {
        if g_Debug OutDebug("Events executed this loop: {0}":Format(g_LoopDelegates:Events:Keys:Length)).
        ExecGLoopEvents().
    }

    DispEngineTelemetry().
    DispStateFlags().
    DispLaunchTelemetry().
    if g_PID_Enabled
    {
        DispPIDLoopValues(g_PIDS["TurnApo"]).
    }
    else if g_GridAssignments:Keys:Contains("PID_VALUES")
    {
        ClearDispBlock("PID_VALUES").
    }
}
ClearDispBlock().

set t_Val to 0.
unlock throttle.

OutInfo("Disabling Autostaging").
set g_AutoStageArmed to DisableAutoStaging().

OutMsg("Coasting out of atmosphere").

// Coast out of atmosphere
until Ship:Altitude >= Body:ATM:Height or Ship:VerticalSpeed < 0
{
    set s_Val to Ship:Prograde.

    if g_LoopDelegates["Events"]:Keys:Length > 0 
    {
        if g_Debug OutDebug("Events executed this loop: {0}":Format(g_LoopDelegates:Events:Keys:Length)).
        ExecGLoopEvents().
    }

    DispLaunchTelemetry().
    DispStateFlags().
    wait 0.01.
}

if g_FairingsArmed
{
    JettisonFairings(Ship:PartsTaggedPattern("Fairing|Ascent.*")).
}

OutMsg("Launch script complete, performing exit actions").
wait 0.25.