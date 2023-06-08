@LazyGlobal off.
ClearScreen.

parameter params to list().

RunOncePath("0:/lib/libLoader.ks").
RunOncePath("0:/lib/launch.ks").

DispMain().

local cb                 to Ship:Engines[0]. // Initialized to any old engine for now
local curBoosterTag      to "".
local engineCounter      to 0.
local fairingJetAlt      to 100000.
local RCSAlt             to 32500.

local FairingsArmed      to false.
local LESArmed           to false.
local RCSArmed           to false.
local RCSPresent         to Ship:ModulesNamed("ModuleRCSFX"):Length > 0.
local HotStagePresent    to Ship:PartsTaggedPattern("(HotStage|HotStg|HS)"):Length > 0.
local stagingCheckResult to 0.
local steeringDelegate   to { return ship:facing.}.
local ThrustThresh       to 0.

// Parameter default values.
local _tgtAlt        to 100.
local _tgtInc        to 0.
local _azObj         to list().

if params:length > 0
{
    set _tgtAlt to params[0].
    if params:length > 1 set _tgtInc to params[1].
    if params:length > 2 set _azObj to params[2].
}

wait until Ship:Unpacked.
local towerHeight to (Ship:Bounds:Size:Mag + 100).

// Set the steering delegate
if _azObj:Length = 0 and g_GuidedAscentMissions:Contains(g_MissionTag:Mission)
{
    set _azObj to l_az_calc_init(_tgtAlt, _tgtInc).
}

set g_azData to _azObj.
set g_LoopDelegates["Steering"] to GetAscentSteeringDelegate(_tgtAlt, _tgtInc, _azObj).

ConfigureLaunchPad().

Breakpoint(Terminal:Input:Enter, "*** Press ENTER to launch ***").
ClearScreen.
// DispTermGrid().
DispMain(ScriptPath()).

if RCSPresent
{
    local rcsCheckDel to { parameter _params to list(). if _params:length = 0 { set _params to list(0.001, 5).} return Ship:Body:ATM:AltitudePressure(Ship:Altitude) <= _params[0] or g_ActiveEngines_Data:BurnTimeRemaining <= _params[1].}.
    local rcsActionDel to { parameter _params is list(). RCS on. return false.}.
    local rcsEventData to CreateLoopEvent("RCSEnable", "RCS", list(0.0025, 3), rcsCheckDel@, rcsActionDel@).
    set RCSArmed to RegisterLoopEvent(rcsEventData).
}

set FairingsArmed to ArmFairingJettison("ascent").
set LESArmed      to ArmLESTower().

if FairingsArmed 
{
    OutInfo("ArmFairingJettison() result: {0}":Format(FairingsArmed)).
}
else if LESArmed
{
    OutInfo("ArmLESTower() result: {0}":Format(LESArmed)).
}

lock Throttle to 1.
OutMsg("Launch initiated!").
wait 0.25.
LaunchCountdown().
OutInfo().
OutInfo("",1).

set g_ActiveEngines to GetActiveEngines().
set g_NextEngines   to GetNextEngines().

// Check if we have any special MECO engines to handle
local MECO_Engines to Ship:PartsTaggedPattern("MECO\|ascent").
if MECO_Engines:Length > 0
{
    SetupMECOEventHandler(MECO_Engines).
}
// local AutoStageResult to ArmAutoStaging().
ArmAutoStaging().

// Arm hot staging if present
set g_HotStagingArmed to ArmHotStaging().

// if AutoStageResult = 1
// {
//     set stagingDelegateCheck  to g_LoopDelegates:Staging["Check"].
//     set stagingDelegateAction to g_LoopDelegates:Staging["Action"].
// }

set g_BoostersArmed to ArmBoosterStaging().

set s_Val to Ship:Facing.
lock steering to s_Val.

OutMsg().
OutInfo().
OutInfo("", 1).

OutMsg("Liftoff! ").
wait 1.
OutMsg("Vertical Ascent").
set g_ActiveEngines to GetActiveEngines().

until Alt:Radar >= towerHeight
{
    if engineCounter <> g_ActiveEngines:Length
    {
        set g_ActiveEngines to GetActiveEngines().
    } 
    set g_ActiveEngines_Data to GetEnginesPerformanceData(g_ActiveEngines).
    if g_BoostersArmed { CheckBoosterStageCondition().}
    if g_LoopDelegates:HasKey("Staging")
    {
        if g_HotStagingArmed 
        { 
            local doneFlag to false.
            from { local i to Stage:Number.} until i < 0 or doneFlag step { set i to i - 1.} do
            {
                if g_LoopDelegates:Staging:HotStaging:HasKey(i)
                {
                    if g_LoopDelegates:Staging:HotStaging[i]:HasKey("Check")
                    {
                        if g_LoopDelegates:Staging:HotStaging[i]:Check:CALL()
                        {
                            g_LoopDelegates:Staging:HotStaging[i]:Action:CALL().
                            set doneFlag to true.
                        }
                    }
                }
            }
        }
        else
        {
            set stagingCheckResult to g_LoopDelegates:Staging:Check:Call().
            if stagingCheckResult = 1
            {
                g_LoopDelegates:Staging["Action"]:Call().
            }
        }
    }

    DispLaunchTelemetry().
    // DispEngineTelemetry().
}

OutMsg("Gravity Turn").
until Stage:Number <= g_StageLimit
{
    set g_ActiveEngines to GetActiveEngines().
    set g_ActiveEngines_Data to GetEnginesPerformanceData(g_ActiveEngines).
    if g_BoostersArmed { CheckBoosterStageCondition().}
    if g_LoopDelegates:HasKey("Staging")
    {
        if g_HotStagingArmed 
        { 
            local doneFlag to false.
            from { local i to Stage:Number - 1.} until i < 0 or doneFlag step { set i to i - 1.} do
            {
                if g_LoopDelegates:Staging:HotStaging:HasKey(i)
                {
                    if g_LoopDelegates:Staging:HotStaging[i]:Check:CALL()
                    {
                        g_LoopDelegates:Staging:HotStaging[i]:Action:CALL().
                    }
                    set doneFlag to true.
                }
            }
        }
        else
        {
            set stagingCheckResult to g_LoopDelegates:Staging:Check:Call().
            if stagingCheckResult = 1
            {
                g_LoopDelegates:Staging["Action"]:Call().
            }
        }
    }
    
    // if fairingsArmed
    // {
    //     if Ship:Altitude >= fairingJetAlt
    //     {
    //         if g_LoopDelegates:Events:HasKey("Fairings")
    //         {
    //             if g_LoopDelegates:Events:Fairings:HasKey("Check")
    //             {
    //                 g_LoopDelegates:Events:Fairings:Check:Call().
    //             }
    //             else
    //             {
    //                 JettisonFairings(Ship:PartsTaggedPattern("fairing|ascent")).
    //             }
    //         }
    //         set fairingsArmed to g_LoopDelegates:Events:HasKey("fairing").
    //     }
    // }
    if RCSPresent
    {
        if Ship:Body:ATM:AltitudePressure(Ship:Altitude) <= 0.001 or g_ActiveEngines_Data:BurnTimeRemaining <= 5
        {
            RCS on.
            set RCSPresent to False.
        }
    }
    
    if g_LoopDelegates["Events"]:Keys:Length > 0 
    {
        // OutDebug("Events executed this loop: {0}":Format(g_LoopDelegates:Events:Keys:Length)).
        ExecGLoopEvents().
    }

    set s_Val to g_LoopDelegates:Steering:Call().
    DispLaunchTelemetry().
    // DispEngineTelemetry().
    wait 0.01.
}

// set g_ActiveEngines_Data to GetEnginesPerformanceData(GetActiveEngines()).
// until g_ActiveEngines_Data:Thrust >= 0.2
// {
//     if g_BoostersArmed { CheckBoosterStageCondition().}
//     set g_ActiveEngines_Data to GetEnginesPerformanceData(GetActiveEngines()).

//     if fairingsArmed
//     {
//         if Ship:Altitude >= fairingJetAlt
//         {
//             g_LoopDelegates:Events["fairing"]:Delegate:Call().
//             set fairingsArmed to g_LoopDelegates:Events:HasKey("fairing").
//         }
//     }

//     DispLaunchTelemetry().
//     // DispEngineTelemetry().
//     wait 0.01.
// }

DisableAutoStaging().

OutMsg("Final Burn").
wait 0.25.
local doneFlag to false.
until doneFlag or Ship:AvailableThrust <= 0.1
{
    set s_Val to g_LoopDelegates:Steering:Call().
    set g_ActiveEngines to GetActiveEngines().
    set g_ActiveEngines_Data to GetEnginesPerformanceData(g_ActiveEngines).
    if g_BoostersArmed { CheckBoosterStageCondition().}
    // if fairingsArmed
    // {
    //     g_LoopDelegates:Events["Fairings"]:Check:Call().
    //     set fairingsArmed to g_LoopDelegates:Events:HasKey("fairing").
    // }

    if g_LoopDelegates["Events"]:Keys:Length > 0 
    {
        // OutDebug("Events executed this loop: {0}":Format(g_LoopDelegates:Events:Keys:Length)).
        ExecGLoopEvents().
    }

    DispLaunchTelemetry().
    // DispEngineTelemetry().
    wait 0.01.
    // if g_ActiveEngines_Data:Thrust <= 0.1
    // {
    //     set doneFlag to true.
    //     OutDebug("[289]: DoneFlag triggered").
    // }
}
ClearDispBlock("ENGINE_TELEMETRY").

set t_Val to 0.
OutMsg("Coasting out of atmosphere").
Until Ship:Altitude >= Body:ATM:Height
{
    set s_Val to Ship:Prograde.
    DispLaunchTelemetry().
    wait 0.01.
}

if g_StageLimitSet:Length > 0
{
    set core:tag to SetNextStageLimit(core:tag).
}

OutMsg("Launch script complete, performing exit actions").
unlock throttle.
wait 1.




// Test Functions
