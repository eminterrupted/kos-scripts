@LazyGlobal off.
ClearScreen.

parameter params to list().

RunOncePath("0:/lib/libLoader.ks").
RunOncePath("0:/lib/launch.ks").

DispMain().

local engineCounter      to 0.
local rcsPresent         to Ship:ModulesNamed("ModuleRCSFX"):Length > 0.
local stagingCheckResult to 0.

// Parameter default values.
local _tgtAlt        to -1.
local _tgtInc        to 0.
local _azObj         to g_azData.

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


ConfigureLaunchPlatform().

// Launch event setup
// Set the steering delegate
if _azObj:Length = 0 and g_GuidedAscentMissions:Contains(g_MissionTag:Mission)
{
    set g_azData to l_az_calc_init(_tgtAlt, _tgtInc).
}
else
{
    set g_azData to _azObj.
}

set g_SteeringDelegate to GetAscentSteeringDelegate(_tgtAlt, _tgtInc, g_azData).

if rcsPresent
{
    local rcsCheckDel to { parameter _params to list(). if _params:length = 0 { set _params to list(0.001, 5).} return Ship:Body:ATM:AltitudePressure(Ship:Altitude) <= _params[0] or g_ActiveEngines_Data:BurnTimeRemaining <= _params[1].}.
    local rcsActionDel to { parameter _params is list(). RCS on. return false.}.
    local rcsEventData to CreateLoopEvent("RCSEnable", "RCS", list(0.0025, 3), rcsCheckDel@, rcsActionDel@).
    set g_RCSArmed to RegisterLoopEvent(rcsEventData).
}

set g_FairingsArmed     to ArmFairingJettison("ascent").
set g_LESArmed          to ArmLESTower().
set g_HotStagingArmed   to ArmHotStaging().
set g_BoostersArmed     to ArmBoosterStaging_NextReally().

local onStageParts to Ship:PartsTaggedPattern("^OnStage").
if onStageParts:Length > 0
{
    set g_OnStageEventArmed to SetupOnStageEventHandler(onStageParts).
}

local autoStageResult to ArmAutoStagingNext().
set g_AutoStageArmed  to choose True if autoStageResult = 1 else False.

// Check if we have any special MECO engines to handle
local ascentEventParts to Ship:PartsTaggedPattern("^Ascent\|.*").
local ascentEventCount to 0.
if ascentEventParts:Length > 0 
{
    set ascentEventCount to ArmAscentEvents(ascentEventParts).
}

if g_Debug
{
    OutInfo("ArmFairingJettison() result: {0}":Format(g_FairingsArmed)).
    OutInfo("ArmLESTower() result: {0}":Format(g_LESArmed)).
    OutInfo("ArmAscentEvents() ascentEventCount: [{0}]":Format(ascentEventCount)).
    OutInfo("Registered Events: {0}":Format(g_LoopDelegates:Events:Keys:Join(";"))).
}

DispStateFlags().

OutMsg("Waiting for launch command").
set g_TS to Time:Seconds.
local launchStr to "Press [ENTER] to hopefully go to space today".
local launchChars to list(
    ""
    ,"*"
    ,"**"
    ,"***"
).

until g_TermChar = Terminal:Input:Enter
{
    local idx to Mod(Round(Time:Seconds - g_TS), launchChars:Length).
    local launchChar to launchChars[idx].
    local tempStr to "{0,3} {1} {0,-3}":Format(launchChar, launchStr).
    print tempStr at (Round((Terminal:Width - tempStr:Length) / 2), Terminal:Height - 5).
    GetTermChar().
    if not g_Debug
    {
        CheckKerbaliKode().
    }
}

ClearScreen.
DispMain(ScriptPath()).

lock Throttle to 1.
OutMsg("GO for launch! Commencing countdown").
wait 0.05.
LaunchCountdown().
OutInfo().
OutInfo("",1).

set g_ActiveEngines to GetActiveEngines().
set g_NextEngines   to GetNextEngines().

set s_Val to Ship:Facing.
lock steering to s_Val.

OutMsg().
OutInfo().
OutInfo("g_DecouplerEventArmed: {0}":Format(g_DecouplerEventArmed),1).

OutMsg("Liftoff! ").
wait 1.
OutMsg("Vertical Ascent").
set g_ActiveEngines to GetActiveEngines().

DispMain(ScriptPath()).
ClearDispBlock().

until Alt:Radar >= towerHeight
{
    set g_ActiveEngines to GetActiveEngines().
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
            OutInfo("Checking staging delegate", 2).
            set stagingCheckResult to g_LoopDelegates:Staging:Check:Call().
            if stagingCheckResult = 1
            {
                OutInfo("Staging", 2).
                g_LoopDelegates:Staging["Action"]:Call().
            }
        }
    }
    
    DispStateFlags().
    DispLaunchTelemetry().
    DispEngineTelemetry().
}
ClearDispBlock().

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
            set stagingCheckResult to g_LoopDelegates:Staging["Check"]:Call().
            if stagingCheckResult = 1
            {
                g_LoopDelegates:Staging["Action"]:Call().
            }
        }
    }
    
    if g_LoopDelegates["Events"]:Keys:Length > 0 
    {
        ExecGLoopEvents().
    }

    set s_Val to g_SteeringDelegate:Call().
    DispStateFlags().
    DispLaunchTelemetry().
    DispEngineTelemetry().
}
ClearDispBlock().

OutInfo("Disabling Autostaging").
DisableAutoStaging().

OutMsg("Final Burn").
wait 0.05.
until Ship:AvailableThrust <= 0.1
{
    set s_Val to g_SteeringDelegate:Call().
    set g_ActiveEngines to GetActiveEngines().
    set g_ActiveEngines_Data to GetEnginesPerformanceData(g_ActiveEngines).
    if g_BoostersArmed { CheckBoosterStageCondition().}

    if g_LoopDelegates["Events"]:Keys:Length > 0 
    {
        if g_Debug OutDebug("Events executed this loop: {0}":Format(g_LoopDelegates:Events:Keys:Length)).
        ExecGLoopEvents().
    }

    DispStateFlags().
    DispLaunchTelemetry().
    DispEngineTelemetry().
}
ClearDispBlock().

set t_Val to 0.
OutMsg("Coasting out of atmosphere").
unlock throttle.

// Coast out of atmosphere
until Ship:Altitude >= Body:ATM:Height
{
    set s_Val to Ship:Prograde.

    if g_LoopDelegates["Events"]:Keys:Length > 0 
    {
        if g_Debug OutDebug("Events executed this loop: {0}":Format(g_LoopDelegates:Events:Keys:Length)).
        ExecGLoopEvents().
    }

    DispStateFlags().
    DispLaunchTelemetry().
    wait 0.01.
}

OutMsg("Launch script complete, performing exit actions").
unlock throttle.
wait 0.25.