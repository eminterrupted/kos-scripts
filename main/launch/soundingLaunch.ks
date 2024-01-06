@LazyGlobal off.
ClearScreen.

parameter params to list().

RunOncePath("0:/lib/libLoader.ks").
RunOncePath("0:/lib/launch.ks").

set g_MainProcess to ScriptPath().
DispMain().

local engineCounter      to 0.
local stagingCheckResult to 0.

// Parameter default values.
local _tgtAp         to -1.
local _tgtInc        to 0.
local _tgtPe         to -1.
local _azObj         to g_AzData.

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

if _tgtAp < 0
{
    set _tgtAp to 250000.
}
if _tgtPe < 0
{
    set _tgtPe to _tgtAp.
}

wait until Ship:Unpacked.
local towerHeight to (Ship:Bounds:Size:Mag + (Ship:Bounds:Size:Mag * 0.50)).

local launchConfig to list(g_MissionTag:STGSTOPSET, g_MissionTag:PARAMS, g_MissionTag:STGSTOPSET).
PreLaunchInit().

OutMsg("Waiting for launch command").
set g_TS to Time:Seconds.
local launchStr to "Press [ENTER] to hopefully go to space today".
local launchChars to list(
    ""
    ,"*"
    ,"**"
    ,"***"
).

local launchCommit to False.
local reInitLaunchConfig to False.
local updateConfig to False.
until launchCommit
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

    if g_TermChar = Terminal:Input:Enter
    {
        set launchCommit to True.
    }
    else if g_TermChar = Terminal:Input:DeleteRight
    {
        set g_TS to Time:Seconds + 3.

        OutInfo().
        until Time:Seconds > g_TS
        {
            OutMsg("Rebooting in {0,-4}...":Format(Round(g_TS - Time:Seconds, 2))).
            wait 0.01.
        }
        reboot.
    }

    // #TODO : Figure out UpdateLaunchConfig
    // else if g_TermChar = Terminal:Input:Backspace
    // {
    //     // Provide a UI for updating values in tag
    //     OutMsg("Update launch configuration? (Press [Y / N])").
    //     OutInfo("", -1).
        
    //     set g_TermChar to "".
    //     Terminal:Input:Clear.

    //     until g_TermChar:Length > 0
    //     {
    //         GetTermChar().
    //         wait 0.01.
    //         // OutDebug("g_TermChar: {0}":Format(g_TermChar)).
    //     }

    //     if g_TermChar:MatchesPattern("(Y|y)")
    //     {
    //         OutInfo("* Y *").
    //         set updateConfig to True.
    //     }
    //     else if g_TermChar:MatchesPattern("(N|n)")
    //     {
    //         OutInfo("* N *").
    //         set updateConfig to False.
    //     }
    // }
    // if updateConfig
    // {
    //     set reInitLaunchConfig to UpdateLaunchConfig().
    // }
    
    if g_TermChar = Terminal:Input:HomeCursor or reInitLaunchConfig
    {
        OutMsg("Reinitializing launch configuration").
        print " ":PadRight(Terminal:Width) at (0, Terminal:Height - 5).

        PreLaunchInit().
        set reInitLaunchConfig to False.
        wait 0.25.
        OutInfo().
        OutMsg("Waiting for launch command").
    }
    else if g_TermChar = Terminal:Input:DeleteRight
    {
        ResetLaunchPlatform().
        set g_TS2 to Time:Seconds + 5.
        set g_TermChar to "".
        print " ":PadRight(Terminal:Width) at (0, Terminal:Height - 5).

        local doneFlag to False.
        until doneFlag
        {
            GetTermChar().
            if g_TermChar = Terminal:Input:DeleteRight or g_TermChar = Terminal:Input:EndCursor
            {
                set doneFlag to True.
            }
            else if g_TS2 - Time:Seconds < 0
            {
                set doneFlag to True.
            }
            else
            {
                OutMsg("[{0,-4}s] Resetting launch pad configuration...":Format(Round(g_TS2 - Time:Seconds, 2))).
            }
            OutInfo().
            set g_TermChar to "".
        }
        unset doneFlag.
        
        OutMsg("Waiting for launch command").
    }
    
    set g_TermChar to "".
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
            set stagingCheckResult to g_LoopDelegates:Staging:Check:Call().
            OutInfo("Checking staging delegate {0}":Format(stagingCheckResult), 2).
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
until Ship:AvailableThrust <= 0.1 or Ship:Periapsis >= _tgtPe
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
unlock throttle.
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

    DispStateFlags().
    DispLaunchTelemetry().
    wait 0.01.
}

if g_FairingsArmed
{
    JettisonFairings(Ship:PartsTaggedPattern("Fairing|Ascent.*")).
}

OutMsg("Launch script complete, performing exit actions").
wait 0.25.



// Launch event setup
local function PreLaunchInit
{
    // If this is a re-init, clear the existing variables
    if g_TermChar = Terminal:Input:HomeCursor
    {
        if g_LoopDelegates:Events:Keys:Length > 0
        {
            g_LoopDelegates:Events:Clear.
            g_LoopDelegates:Program:Clear.
            if g_LoopDelegates:HasKey("Staging") 
            {
                g_LoopDelegates:Remove("Staging").  
            }
        }

        set _azObj to list().
        set g_AzData to list().
    }

    ConfigureLaunchPlatform().
    // Set the steering delegate
    if _azObj:Length = 0 and g_GuidedAscentMissions:Contains(g_MissionTag:Mission)
    {
        set _azObj to l_az_calc_init(_tgtAp, _tgtInc).
        set g_AzData to _azObj.
    }
    else
    {
        set g_AzData to _azObj.
    }

    set g_SteeringDelegate to GetAscentSteeringDelegate(_tgtAp, _tgtInc, g_AzData).

    if Ship:ModulesNamed("ModuleRCSFX"):Length > 0
    {
        local rcsCheckDel to { parameter _params to list(). if _params:length = 0 { set _params to list(0.001, 5).} return Ship:Body:ATM:AltitudePressure(Ship:Altitude) <= _params[0] or g_ActiveEngines_Data:BurnTimeRemaining <= _params[1].}.
        local rcsActionDel to { parameter _params is list(). RCS on. set g_RCSArmed to False. return False.}.
        local rcsEventData to CreateLoopEvent("RCSEnable", "RCS", list(0.0025, 3), rcsCheckDel@, rcsActionDel@).
        set g_RCSArmed to RegisterLoopEvent(rcsEventData).
    }

    set g_FairingsArmed     to ArmFairingJettison("ascent").
    set g_LESArmed          to ArmLESTower().
    set g_HotStagingArmed   to ArmHotStaging().
    set g_BoostersArmed     to ArmBoosterStaging_NewShinyNext().
    set g_SpinArmed         to SetupSpinStabilizationEventHandler().

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
}