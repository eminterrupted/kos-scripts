@LazyGlobal off.
ClearScreen.

parameter params to list().

RunOncePath("0:/lib/libLoader.ks").
RunOncePath("0:/lib/launch.ks").

set g_MainProcess to ScriptPath().
DispMain().

local engineCounter      to 0.
local rcsPresent         to Ship:ModulesNamed("ModuleRCSFX"):Length > 0.
local stagingCheckResult to 0.

// Parameter default values.
local _tgtAlt        to -1.
local _tgtInc        to 0.
local _azObj         to list().

if g_MissionTag:Params:Length > 0
{
    set _tgtInc to g_MissionTag:Params[0].
    if g_MissionTag:Params:Length > 1 set _tgtAlt to g_MissionTag:Params[1].
}

if params:length > 0
{
    set _tgtInc to params[0].
    if params:length > 1 set _tgtAlt to params[1].
    if params:length > 2 set _azObj to params[2].
}

if _tgtAlt < 0
{
    set _tgtAlt to 250000.
}

wait until Ship:Unpacked.
local towerHeight to (Ship:Bounds:Size:Mag + 100).

// Set the steering delegate
if _azObj:Length = 0 and g_GuidedAscentMissions:Contains(g_MissionTag:Mission)
{
    set _azObj to l_az_calc_init(_tgtAlt, _tgtInc).
}

set g_azData to _azObj.
set g_SteeringDelegate to GetAscentSteeringDelegate(_tgtAlt, _tgtInc, _azObj).

ConfigureLaunchPlatform().

if rcsPresent
{
    local rcsCheckDel to { parameter _params to list(). if _params:length = 0 { set _params to list(0.001, 5).} return Ship:Body:ATM:AltitudePressure(Ship:Altitude) <= _params[0] or g_ActiveEngines_Data:BurnTimeRemaining <= _params[1].}.
    local rcsActionDel to { parameter _params is list(). RCS on. set g_RCSArmed to False. return false.}.
    local rcsEventData to CreateLoopEvent("RCSEnable", "RCS", list(0.0025, 3), rcsCheckDel@, rcsActionDel@).
    set g_RCSArmed to RegisterLoopEvent(rcsEventData).
}

set g_FairingsArmed     to ArmFairingJettison("ascent").
set g_LESArmed          to ArmLESTower().
set g_HotStagingArmed   to ArmHotStaging().

if g_FairingsArmed 
{
    MsgInfoString("INFO","ArmFairingJettison() result: {0}":Format(g_FairingsArmed)).
}
else if g_LESArmed
{
    MsgInfoString("INFO","ArmLESTower() result: {0}":Format(g_LESArmed)).
}



// Check if we have any special MECO engines to handle
local ascentEventParts to Ship:PartsTaggedPattern("^Ascent\|.*").

if g_Debug local dcCounter to 0.
if ascentEventParts:Length > 0
{
    for eventPart in ascentEventParts
    {
        local epTag to eventPart:Tag:Replace("Ascent|","").
        local epTagSplit to epTag:Split("|").
        if epTag:MatchesPattern("MECO\|\d*")
        {
            if not g_LoopDelegates:Events:HasKey("MECO")
            {
                set g_MECOArmed to SetupMECOEventHandler("Ascent").
            }
        }

        if epTagSplit[0] = "Decouple"
        {   
            if epTagSplit:Length > 1 
            {
                if epTagSplit[1]:ToNumber(-808) = -808
                {
                    if epTagSplit[1]:Split(";"):length > 1
                    {
                    }
                    else if epTagSplit[1] = "MECO"
                    {
                        if not g_LoopDelegates:Events:HasKey("DC_MECO")
                        {
                            // if g_Debug OutDebug("[g_LoopDelegates][DC{0}] Event cache miss [MECO_DC]":Format(dcCounter)).
                            local dcList to Ship:PartsTaggedPattern("Ascent\|Decouple\|MECO").
                            MsgInfoString("INFO","Arming DecouplerEvent [Count:{0}]":Format(dcList:Length)).
                            local dcEventRegistrationResult to SetupDecoupleEventHandler(dcList).
                            MsgInfoString("INFO","***Arming DecouplerEvent Result: [{0}]":Format(dcEventRegistrationResult)).
                            set g_DecouplerEventArmed to choose g_DecouplerEventArmed if g_DecouplerEventArmed else dcEventRegistrationResult.
                            MsgInfoString("INFO","g_DecouplerEventArmed[{0}]: {1}":Format("DC_MECO", g_DecouplerEventArmed)).
                        }
                        else
                        {
                        // if g_Debug OutDebug("[g_LoopDelegates][DC{0}] Event cache hit [MECO_DC]":Format(dcCounter)).
                        }
                    }
                    else
                    {
                    // if g_Debug OutDebug("[g_LoopDelegates][DC{0}] Event cache error (123) [MECO_DC]":Format(dcCounter)).
                    }
                }
                else
                {
                    local dcMET to ParseStringScalar(epTag:Replace("Decouple|",""), -1).
                    // if g_Debug OutDebug("[soundingLaunch] dcMET Parsed [{0}]":Format(dcMET)).
                    wait 1.
                    local dcEventId to "DC_{0}":Format(dcMET).
                    if not g_LoopDelegates:Events:HasKey(dcEventId)
                    {
                        local dcList to Ship:PartsTaggedPattern("Ascent\|Decouple\|{0}":Format(dcMET:ToString:Replace(".","\."))).
                        MsgInfoString("INFO","Arming DecouplerEvent [Count:{0}]":Format(dcList:Length)).
                        local dcEventRegistrationResult to SetupDecoupleEventHandler(dcList).
                        MsgInfoString("INFO","***Arming DecouplerEvent Result: [{0}]":Format(dcEventRegistrationResult)).
                        wait 0.5.
                        set g_DecouplerEventArmed to choose g_DecouplerEventArmed if g_DecouplerEventArmed else dcEventRegistrationResult.
                        MsgInfoString("INFO","g_DecouplerEventArmed[{0}]: {1}":Format(dcEventID, g_DecouplerEventArmed)).
                    }
                }
            set dcCounter to dcCounter + 1.
            }
        }
    }
}

DispStateFlags().
MsgInfoString("INFO","Registered Events: {0}":Format(g_LoopDelegates:Events:Keys:Join(";"))).

MsgInfoString("MSG","Waiting for launch command").
Breakpoint(Terminal:Input:Enter, "Press [ENTER] to hopefully go to space today").
ClearScreen.
// DispTermGrid().
DispMain(ScriptPath()).

lock Throttle to 1.
MsgInfoString("MSG","GO for launch! Commencing countdown").
wait 0.25.
LaunchCountdown().
OutInfo().
OutInfo("",1).

set g_ActiveEngines to GetActiveEngines().
set g_NextEngines   to GetNextEngines().

// local MECO_Engines to Ship:PartsTaggedPattern("Ascent\|MECO\|\d*").
// if MECO_Engines:Length > 0
// {
//     SetupMECOEventHandler(MECO_Engines, "Ascent").
// }
// local AutoStageResult to ArmAutoStaging().
// ArmAutoStagingNext(g_StageLimit, 0, 1).
MsgInfoString("INFO","g_StageLimit = {0}":Format(g_StageLimit), 1).

local autoStageResult to ArmAutoStaging().
set g_AutoStageArmed  to choose True if autoStageResult = 1 else False.

// set g_BoostersArmed to ArmBoosterStaging().
set g_BoostersArmed to False.
MsgInfoString("INFO","g_BoostersArmed: {0}":Format(g_BoostersArmed)).
set s_Val to Ship:Facing.
lock steering to s_Val.

//OutMsg().
//OutInfo().
MsgInfoString("INFO","g_DecouplerEventArmed: {0}":Format(g_DecouplerEventArmed),1).

MsgInfoString("MSG","Liftoff! ").
wait 1.
MsgInfoString("MSG","Vertical Ascent").
set g_ActiveEngines to GetActiveEngines().

ClearDispBlock().

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
            MsgInfoString("INFO","Checking staging delegate", 2).
            set stagingCheckResult to g_LoopDelegates:Staging:Check:Call().
            if stagingCheckResult = 1
            {
                MsgInfoString("INFO","Staging", 2).
                g_LoopDelegates:Staging["Action"]:Call().
            }
        }
    }
    
    if g_MsgInfoLoopActive MsgInfoLoop().
    DispStateFlags().
    DispLaunchTelemetry().
    // DispEngineTelemetry().
}

MsgInfoString("MSG","Gravity Turn").
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
            set stagingCheckResult to g_LoopDelegates:Staging["Check"]:Call().
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
    if rcsPresent
    {
        if Ship:Body:ATM:AltitudePressure(Ship:Altitude) <= 0.001 or g_ActiveEngines_Data:BurnTimeRemaining <= 5
        {
            RCS on.
            set rcsPresent to False.
        }
    }
    
    if g_LoopDelegates["Events"]:Keys:Length > 0 
    {
        // OutDebug("Events executed this loop: {0}":Format(g_LoopDelegates:Events:Keys:Length)).
        ExecGLoopEvents().
    }

    set s_Val to g_SteeringDelegate:Call().
    if g_MsgInfoLoopActive MsgInfoLoop().
    DispStateFlags().
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

MsgInfoString("INFO","Disabling Autostaging").
DisableAutoStaging().

MsgInfoString("MSG","Final Burn").
wait 0.25.
until Ship:AvailableThrust <= 0.1
{
    set s_Val to g_SteeringDelegate:Call().
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

    if g_MsgInfoLoopActive MsgInfoLoop().
    DispStateFlags().
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
ClearDispBlock("SYSTEMS ARMED STATUS").

set t_Val to 0.
MsgInfoString("MSG","Coasting out of atmosphere").
unlock throttle.
Until Ship:Altitude >= Body:ATM:Height
{
    set s_Val to Ship:Prograde.
    if g_MsgInfoLoopActive MsgInfoLoop().
    DispLaunchTelemetry().
    wait 0.01.
}

if g_StageLimitSet:Length > 0
{
    set core:tag to SetNextStageLimit().
    if g_MsgInfoLoopActive MsgInfoLoop().
}

OutMsg("Launch script complete, performing exit actions").
unlock throttle.
wait 1.




// Test Functions
