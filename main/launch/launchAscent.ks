@LazyGlobal off.
clearscreen.

parameter params is list().

RunOncePath("0:/lib/depLoader.ks").
RunOncePath("0:/lib/launch.ks").
RunOncePath("0:/lib/log.ks").
RunOncePath("0:/kslib/lib_navball.ks").
RunOncePath("0:/kslib/lib_l_az_calc.ks").

// Local vars
local ascShaper to 1.
local MECO to -1.
local meSpoolTime to 0.
local tgtAlt to Ship:Body:SOIRadius.
local tgtInc to 30.
local launchTS to list().

// Param parsing
if params:Length > 0
{
    set tgtInc to ParseStringScalar(params[0], tgtInc).
    if params:length > 1 set tgtAlt to ParseStringScalar(params[1], tgtAlt).
    if params:length > 2 set ascShaper to ParseStringScalar(params[2], ascShaper).
}


// Ship systems initialization
SetProgram(1).
local mainEngs to list().
local multistage to false.
local padStage to Stage:Number.

// Hydrate the engine object
SetProgram(2).
set g_ShipEngines to GetShipEnginesSpecs(Ship).

// Find the launch clamp stage if any are found
for m in Ship:ModulesNamed("LaunchClamp")
{
    SetProgram(3).
    set padStage to min(padStage, m:Part:Stage).
}

// Parse through the engine object and separate the main engine. If other engines are detected, toggle the multistage flag.
SetProgram(4).
for engStg in g_ShipEngines:IGNSTG:Keys
{
    SetRunmode(2).
    if engStg >= padStage 
    {
        SetRunmode(4).
        for engUID in g_ShipEngines:IGNSTG[engStg]:UID
        {
            SetRunmode(6).
            local eng to g_ShipEngines:ENGUID[engUID]:ENG.
            mainEngs:Add(eng).
            
            // While we have the MEs handy, we should determine MECO and spool time
            set MECO to Max(MECO, g_ShipEngines:ENGUID[engUID]:TARGETBURNTIME).
            if eng:Tag:MatchesPattern("Ascent\|MECO\|\d*")
            {
                set MECO to ParseStringScalar(eng:Tag:Split("|")[2], -1).
                set g_MECO_Armed to true.
            }
            if engStg > padStage 
            {
                SetRunmode(8).
                set MESpoolTime to Max(MESpoolTime, g_ShipEngines:ENGUID[engUID]:SPOOLTIME * 1.04).
            }
        }
    }
    else
    {
        SetRunMode(9).
        set multiStage to True.
    }
}

SetProgram(8, true).
InitStateCache().

CopyPath("state.txt", "0:/test/data/state.txt").

// * Launch Countdown Loop 
until g_Program >= 20 or g_Abort
{   
    set g_line to 4.
    if g_Program < 8
    {
        SetProgram(8).
    }
    else if g_Program = 8
    {
        OutMsg("TgtInc: {0} | TgtAlt: {1} | AscShaper: {2}":Format(tgtInc, tgtAlt, ascShaper), g_line).
        OutMsg("Stage Limit: {0}":Format(g_StageLimit), cr()).
        OutMsg("Go to space?", cr()).
        until g_TermChar = Terminal:Input:Enter
        {
            set g_TermChar to "".
            GetTermChar().
            wait 0.01.
        }
        OutMsg("Okay, we're gonna do it, we're gonna ", cr()).
        OutMsg("go to space today!!! Hold on to your butts!", cr()).
        wait 2.
        ClearScreen.
        SetProgram(9).
    }

    // Setup control
    if g_Program = 9
    {
        set g_AzData to l_az_calc_init(tgtAlt, tgtInc).

        set g_Throt to 0.
        lock Throttle to g_Throt.

        set g_Steer to Ship:Facing.
        lock Steering to g_Steer.

        SetProgram(10).
    }
    // Setup the countdown timers
    else if g_Program = 10
    {
        if g_Runmode = 1
        {
            set launchTS to GetCountdownTimers(meSpoolTime).
            OutMsg("LAUNCH COUNTDOWN: T{0}  ":Format(Round(Time:Seconds - launchTS[1], 2)):PadRight(Terminal:Width - 24), g_line).
            SetProgram(12).
        }
        else if g_Runmode < 0
        {
            if g_ErrorCodeRef:CODES[g_ErrorCode]:Type = "FATAL"
            {
                set g_Abort     to True.
                set g_AbortCode to g_Program.
            }
        }
        else
        {
            SetRunmode(1).
        }
    }

    // Wait for engine ignition
    else if g_Program = 12
    {
        if g_Runmode = 1
        {
            local engIgnitionETA to Time:Seconds - launchTS[2].
            if engIgnitionETA >= 0
            {
                SetProgram(14).
            }
            else
            {
                OutMsg("LAUNCH COUNTDOWN: T{0}  ":Format(Round(Time:Seconds - launchTS[1], 2)):PadRight(Terminal:Width - 24), g_line).
                OutMsg("ENGINE IGNTION  : T{0}  ":Format(Round(engIgnitionETA, 2)):PadRight(Terminal:Width - 24), cr()).
            }

        }
        else if g_Runmode < 0
        {
            if g_ErrorCodeRef:CODES[g_ErrorCode]:Type = "FATAL"
            {
                set g_Abort     to True.
                set g_AbortCode to g_Program.
            }
        }
        else
        {
            SetRunmode(1).
        }
    }

    // Engine ignition
    else if g_Program = 14
    {
        OutMsg("LAUNCH COUNTDOWN: T{0}  ":Format(Round(Time:Seconds - launchTS[1], 2)):PadRight(Terminal:Width - 24), g_line).
        if g_Runmode = 1
        {
            set g_Throt to 1.

            if Stage:Ready
            {
                if Stage:Number > padStage + 1
                {
                    stage.
                }
                else if Stage:Number > padStage
                {
                    SetRunmode(3).
                }
            }
        }
        else if g_Runmode > 1
        {
            set g_ActiveEngines to GetActiveEngines().
            set g_ActiveEngines_PerfData to GetEnginesPerformanceData(g_ActiveEngines, "11100000").
            if g_Runmode < 6 and Time:Seconds >= launchTS[1]
            {
                SetRunmode(6).
            }
            local aggThrustModifier to 0.
            set g_line to 7.
            for eng in mainEngs
            {
                OutMsg(" - {0} THRUST: {1} [{2}%]   ":Format(eng:CONFIG, Round(eng:Thrust, 2), Round(100 * (eng:Thrust / eng:MaxPossibleThrustAt(Ship:Altitude)), 2)), cr()).
                set aggThrustModifier to aggThrustModifier + GetField(eng:GetModule("TestFlightReliability_EngineCycle"), "thrust modifier", 1).
            }
            
            if g_Runmode = 6
            {
                OutMsg(aggThrustModifier, cr()).
                if aggThrustModifier >= 0.925
                {
                    SetRunmode(9).
                }
            }
            else if g_Runmode = 9
            {
                SetProgram(16).
            }
        }
        else if g_Runmode < 0
        {
            if g_ErrorCodeRef:CODES[g_ErrorCode]:Type = "FATAL"
            {
                set g_Abort     to True.
                set g_AbortCode to g_Program.
            }
        }
        else
        {
            OutMsg("* ENGINE IGNITION SEQUENCE START *", cr()).
            SetRunmode(1).
        }
    }

    // Liftoff
    else if g_Program = 16
    {
        set g_ActiveEngines_PerfData to GetEnginesPerformanceData(g_ActiveEngines, "11100000").
        OutMsg("LAUNCH COUNTDOWN: T{0}  ":Format(Round(Time:Seconds - launchTS[1], 2)), 5).
        if g_RunMode = 0
        {
            OutMsg("* LIFTOFF *":PadRight(29), 6).
            SetRunmode(1).
        }
        else if g_Runmode = 1
        {
            set g_line to 7.
            for eng in mainEngs
            {
                clr(cr()).
            }
            SetRunmode(2).
        }
        else if g_Runmode = 2
        {
            if Stage:Number > padStage 
            {
                if Stage:Ready stage.
            }
            else
            {
                SetProgram(20).
            }
        }
        else if g_Runmode < 0
        {
            if g_ErrorCodeRef:CODES[g_ErrorCode]:Type = "FATAL"
            {
                set g_Abort     to True.
                set g_AbortCode to g_Program.
            }
        }
    }

    UpdateState(True).

    // TODO: Write Abort Handler here
    if g_Abort
    {

    }

    OutMsg("C:[{0,-1}] | P:[{1,-3}] | R:[{2,-2}] | SL:[{3,-1}]  ":Format(g_Context, g_Program, g_Runmode, g_StageLimit):PadRight(20), 0).
}

set g_NextEngines to GetNextEngines("1110").

// Now we arm auto and hot staging if needed
if multistage
{
    if Ship:PartsTaggedPattern("HS|HotStage"):Length > 0 
    {
        // ArmHotStaging(g_StageLimit, MECO).
        ArmHotStaging(g_StageLimit).
    }
    if Ship:PartsTaggedPattern("SpinDC"):Length > 0
    {
        ArmSpinStabilization(g_StageLimit).
    }
    ArmAutoStaging(g_StageLimit).
}

if g_AzData:Length = 0
{
    set g_AzData to l_az_calc_init(tgtAlt, tgtInc).
}

local boosterArmed to false.
local boosterCheckDel  to { return true.}.
local boosterActionDel to { return false.}.
local boosterResult to list(false, boosterCheckDel, boosterActionDel).
if Ship:PartsTaggedPattern("Ascent\|Booster\|"):Length > 0
{
    set boosterResult to ArmBoosterStaging("Ascent").
    set boosterArmed to boosterResult[0].
    set boosterCheckDel  to boosterResult[1].
    set boosterActionDel to boosterResult[2].
}

// Arm fairings
local fairingResult to list().
local fairingsArmed to false.
local fairingCheck  to { return true.}.
local fairingAction to { return false.}.
if Ship:PartsTaggedPattern("Ascent\|Fairing.*"):Length > 0
{
    set fairingResult to ArmFairingJettison(Ship:PartsTaggedPattern("Ascent\|Fairing.*")).
    set fairingsArmed to fairingResult[0].
    set fairingCheck  to fairingResult[1].
    set fairingAction to fairingResult[2].
}

// Arm RCS
local rcsModules to Ship:ModulesNamed("ModuleRCSFX").
local rcsArmed to false.
local rcsStage to -2.
for m in rcsModules
{
    set rcsStage to Max(rcsStage, m:Part:Stage).
}
set rcsArmed to rcsStage >= g_StageLimit.



local ascAngDel to GetAscentAngle@:Bind(tgtAlt):Bind(ascShaper).
local rollDel to { return 0. }.


SetProgram(21).
SetRunmode(0).
ClearScreen.
// * Main Loop
until g_Program >= 36 or g_Abort
{
    set g_ActiveEngines to GetActiveEngines().
    set g_ActiveEngines_PerfData to GetEnginesPerformanceData(g_ActiveEngines, "11100000").

    set g_line to 4.
    if g_Program < 22
    {
        if g_Runmode > 0
        {
            OutMsg("Alt:Radar":Format(Round(Alt:Radar, 1)), cr()).
            OutMsg("g_DRTurnStartAlt: {0}":Format(g_DRTurnStartAlt), cr()).

            if Alt:Radar >= g_DRTurnStartAlt
            {
                OutMsg("PASSING ALT:RADAR >= {0}":Format(g_DRTurnStartAlt), cr()).
                SetProgram(22).
            }
            else
            {
                OutMsg("MISSING ALT:RADAR [{0}] >= {1}":Format(Round(Alt:Radar), g_DRTurnStartAlt), cr()).
            }
        }
        else if g_Runmode < 0
        {
            if g_ErrorCodeRef:CODES[g_ErrorCode]:Type = "FATAL"
            {
                set g_Abort     to True.
                set g_AbortCode to g_Program.
            }
        }
        else
        {
            OutMsg("VERTICAL ASCENT":PadRight(g_termW - 15), cr()).
            SetRunmode(1).
        }
    }
    else if g_Program = 22
    {
        if g_RunMode > 0
        {
            if Ship:Apoapsis >= tgtAlt or (Ship:AvailableThrust <= 0.01 and g_Throt > 0)
            {
                SetProgram(24).
            }
        }
        else if g_Runmode < 0
        {
            if g_ErrorCodeRef:CODES[g_ErrorCode]:Type = "FATAL"
            {
                set g_Abort     to True.
                set g_AbortCode to g_Program.
            }
        }
        else
        {
            OutMsg("PITCH PROGRAM":PadRight(g_termW - 15), cr()).
            SetRunmode(1).
        }
        
        set g_Steer to choose Ship:Facing:Vector if g_Spin_Active else heading(l_az_calc(g_AzData), Min(90, Max(-11.25, ascAngDel:Call())), 0).
    }

    else if g_Program = 24
    {
        if g_RunMode > 0
        {
            if Ship:AvailableThrust <= 0.01
            {
                clr(g_line).
                clr(cr()).
                RCS on.
                SetProgram(30).
            }
            else
            {
                cr().
                OutMsg("TIME TO MECO: {0}            ":Format(Round(g_ActiveEngines_PerfData:BURNTIMEREMAINING, 2)), cr()).
            }
        }
        else if g_Runmode < 0
        {
            if g_ErrorCodeRef:CODES[g_ErrorCode]:Type = "FATAL"
            {
                set g_Abort     to True.
                set g_AbortCode to g_Program.
            }
        }
        else
        {
            OutMsg("BURNING TO MECO":PadRight(g_termW - 15), cr()).
            SetRunmode(1).
        }
        
        set g_Steer to choose Ship:Facing:Vector if g_Spin_Active else heading(l_az_calc(g_AzData), Min(90, Max(-11.25, ascAngDel:Call())), 0).
    }

    else if g_Program = 30
    {
        if g_RunMode > 0
        {
            if Ship:Altitude >= Ship:Body:Atm:Height and Ship:AvailableThrust <= 0.01 and Stage:Number <= g_StageLimit
            {
                SetProgram(36).
            }
            else
            {
                SetRunMode(2).
            }
        }
        else if g_Runmode < 0
        {
            if g_ErrorCodeRef:CODES[g_ErrorCode]:Type = "FATAL"
            {
                set g_Abort     to True.
                set g_AbortCode to g_Program.
            }
        }
        else
        {
            OutMsg("COAST PROGRAM":PadRight(g_termW - 15), cr()).
            SetRunmode(1).
        }
        
        set g_Steer  to heading(l_az_calc(g_AzData), Min(90, Max(0, ascAngDel:Call())), 0).
    }
    UpdateState(True).

    // TODO: Write Abort Handler here
    if g_Abort
    {

    }

    OutMsg("C:[{0,-1}] | P:[{1,-3}] | R:[{2,-2}] | SL:[{3,-1}]  ":Format(g_Context, g_Program, g_Runmode, g_StageLimit):PadRight(20), 0).

    DispLaunchTelemetry().

    cr().
    if g_HS_Armed 
    {
        // if g_HS_Check:Call(GetActiveBurnTimeRemaining(g_ActiveEngines))
        local btrem to choose g_ActiveEngines_PerfData:BURNTIMEREMAINING if g_ActiveEngines_PerfData:HasKey("BURNTIMEREMAINING") else GetActiveBurnTimeRemaining(g_ActiveEngines).
        if g_HS_Check:Call(btrem)
        {
            if rcsArmed
            {
                if Stage:Number - 1 = rcsStage 
                {
                    RCS on.
                    set rcsArmed to false.
                }
            }
            set g_HS_Active to g_HS_Action:Call().

            if g_HS_Active
            {
                OutMsg("HotStaging: Action").
                clr(cr()).
            }
            else
            {
                OutMsg("HotStaging: Complete").
                clr(cr()).
            }
        }
        else
        {
            OutMsg("HotStaging: Armed", cr()).
            clr(cr()).
        }
    }
    
    if g_AS_Armed 
    {
        if g_AS_Check:Call()
        {
            if rcsArmed
            {
                if Stage:Number - 1 = rcsStage 
                {
                    RCS on.
                    set rcsArmed to false.
                }
            }
            g_AS_Action:Call().
            clr(cr()).
        }
        else
        {
            OutMsg("Autostaging: Armed", cr()).
        }
    }
    if boosterArmed
    {
        if boosterCheckDel:Call()
        {
            set boosterResult to boosterActionDel:Call().
            set boosterArmed to boosterResult[0].
            if boosterArmed
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
            OutMsg("Booster staging: Armed", cr()).
        }
    }
    if g_Spin_Armed
    {
        if g_Spin_Check:Call()
        {
            g_Spin_Action:Call().
            clr(cr()).
        }
        else
        {
            OutMsg("SpinStabilization: Armed", cr()).
        }
    }
    if fairingsArmed
    {
        if fairingCheck:Call()
        {
            set fairingsArmed to fairingAction:Call().
            clr(cr()).
        }
        else
        {
            OutMsg("Fairing jettison: Armed", cr()).
        }
    }
    if g_MECO_Armed
    {
        if MissionTime >= MECO
        {
            for eng in Ship:PartsDubbedPattern("MECO")
            {
                eng:Shutdown.
            }
            set g_MECO_Armed to false.
        }
    }
    if not HomeConnection:IsConnected()
    {
        if Ship:ModulesNamed("ModuleDeployableAntenna"):Length > 0
        {
            for m in Ship:ModulesNamed("ModuleDeployableAntenna")
            {
                DoEvent(m, "extend antenna").
            }
        }
    }
}


OutMsg("THAT'S ALL FOLKS", 5).