@LazyGlobal off.
clearscreen.

parameter _params is list().

RunOncePath("0:/lib/depLoader.ks").
RunOncePath("0:/lib/launch.ks").
RunOncePath("0:/lib/abort.ks").
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
local ts0 to 0.



// Param parsing
if _params:Length > 0
{
    set tgtInc to ParseStringScalar(_params[0], tgtInc).
    if _params:length > 1 set tgtAlt to ParseStringScalar(_params[1], tgtAlt).
    if _params:length > 2 set ascShaper to ParseStringScalar(_params[2], ascShaper).
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
SetProgram(3).
for m in Ship:ModulesNamed("LaunchClamp")
{
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
            
            // While we have the MEs handy, we should determine spool time
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
    if g_Program < 4
    {
        PrepLaunchPad().
        SetProgram(4).
    }
    else if g_Program = 4
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
        SetProgram(6).
    }
    else if g_Program = 6
    {
        SetProgram(8).
    }

    // Setup control
    if g_Program = 8
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
            OutMsg("LAUNCH COUNTDOWN: T{0}  ":Format(Round(Time:Seconds - launchTS[1], 2)), g_line).
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
                OutMsg("LAUNCH COUNTDOWN: T{0}  ":Format(Round(Time:Seconds - launchTS[1], 2)), g_line).
                OutMsg("ENGINE IGNTION  : T{0}  ":Format(Round(engIgnitionETA, 2)), cr()).
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
        OutMsg("LAUNCH COUNTDOWN: T{0}  ":Format(Round(Time:Seconds - launchTS[1], 2)), g_line).
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
            set g_ActiveEngines_PerfData to GetEnginesPerformanceData(g_ActiveEngines, false, "11100000").
            if g_Runmode < 6 and Time:Seconds >= launchTS[1]
            {
                SetRunmode(6).
            }
            local aggThrustModifier to 0.
            set g_line to 7.
            for eng in mainEngs
            {
                OutMsg(" - {0} THRUST: {1} [{2}%]   ":Format(eng:CONFIG, Round(eng:Thrust, 2), Round(100 * (eng:Thrust / eng:MaxPossibleThrustAt(Ship:Altitude)), 2)), cr()).
                if eng:HasModule("TestFlightReliability_EngineCycle") set aggThrustModifier to aggThrustModifier + GetField(eng:GetModule("TestFlightReliability_EngineCycle"), "thrust modifier", 1).
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
        set g_ActiveEngines_PerfData to GetEnginesPerformanceData(g_ActiveEngines, true, "11100000").
        OutMsg("LAUNCH COUNTDOWN: T{0}  ":Format(Round(Time:Seconds - launchTS[1], 2)), 5).
        if g_RunMode = 0
        {
            OutMsg("* LIFTOFF *", 6).
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

    OutMsg("C:[{0,-1}] | P:[{1,-3}] | R:[{2,-2}] | SL:[{3,-1}]  ":Format(g_Context, g_Program, g_Runmode, g_StageLimit), 0).
}

set g_NextEngines to GetNextEngines("1110").

// Now we arm auto and hot staging if needed
if multistage
{
    if Ship:PartsTaggedPattern("HS|HotStage"):Length > 0 
    {
        // ArmHotStaging(g_StageLimit, MECO).
        OutInfo("Arming Hot-Staging Subroutine").
        ArmHotStaging(g_StageLimit).
    }
    if Ship:PartsTaggedPattern("SpinDC"):Length > 0
    {
        OutInfo("Arming Spin-Stabilization Subroutine").
        ArmSpinStabilization(g_StageLimit).
    }
    OutInfo("Arming Auto-Staging Subroutine").
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

// Arm Abort System
local AbortSysResult to ArmAbortSystem().
local AbortSysArmed to AbortSysResult[0].
local AbortSysCheck  to AbortSysResult[1].
local AbortSysAction to AbortSysResult[2].

// Arm LES Jettison
local LESResult to list().
local LESArmed to false.
local LESCheck  to { return true.}.
local LESAction to { return false.}.
local LESParts to Ship:PartsDubbedPattern("(.*LES.*|.*Launch.*Escape.*)").
if LESParts:Length > 0
{
    set LESResult to ArmLESJettison(LESParts).
    set LESArmed to LESResult[0].
    set LESCheck  to LESResult[1].
    set LESAction to LESResult[2].
}

// Arm MECO
local MECOAction to { return false.}.
local MECOArmed  to false.
local MECOCheck  to { return true.}.
local MECOResult to list().
local MECORunning to false.
local MECOStage  to Stage:Number.
local MECOEngs to Ship:PartsTaggedPattern("Ascent\|MECO\|\d*").
if MECOEngs:Length > 0
{
    set MECO to ParseStringScalar(MECOEngs[0]:Tag:Split("|")[2], -1).

    set MECOResult to ArmMECO(Ship:PartsTaggedPattern("Ascent\|MECO.*")).
    set MECOArmed  to MECOResult[0].
    set MECOCheck  to MECOResult[1].
    set MECOAction to MECOResult[2].
}

// Arm RCS
local rcsModules to Ship:ModulesNamed("ModuleRCSFX").
set g_RCS_Armed to false.
set g_RCS_Stage to -2.
for m in rcsModules
{
    set g_RCS_Stage to Max(g_RCS_Stage, m:Part:Stage).
}
set g_RCS_Armed to g_RCS_Stage >= g_StageLimit.


OutLog("ArmHotStaging Result: {0}":Format(g_HS_Armed), 1).
OutLog("ArmSpinStabilization Result: {0}":Format(g_Spin_Armed), 1).
OutLog("ArmAutoStaging Result: {0}":Format(g_HS_Armed), 1).
OutLog("ArmBoosterStaging Result: {0}":Format(boosterArmed), 1).
OutLog("ArmFairingJettison Result: {0}":Format(fairingsArmed), 1).
OutLog("ArmRCS Result: {0}":Format(g_RCS_Armed), 1).
OutLog("ArmMECO Result: {0}":Format(MECOArmed), 1).


local ascAngDel to GetAscentAngle@:Bind(tgtAlt):Bind(ascShaper).

local rollFlag to false.
local rollVal to choose 0 if Ship:Crew:Length = 0 else 180.
local rollVec to choose -Body:Position if rollVal = 0 else Body:Position.

SetProgram(21).
SetRunmode(0).
ClearScreen.
// * Main Loop
until g_Program >= 36 or g_Abort
{
    GetTermChar().
    set g_ActiveEngines to GetActiveEngines(Ship, False).
    set g_ActiveEngines_PerfData to GetEnginesPerformanceData(g_ActiveEngines, true, "11100000").

    set g_line to 4.
    if g_Program < 22
    {
        if g_Runmode = 1
        {
            OutMsg("Alt:Radar":Format(Round(Alt:Radar, 1)), cr()).
            OutMsg("g_DRTurnStartAlt: {0}":Format(g_DRTurnStartAlt), cr()).

            if Alt:Radar >= g_DRTurnStartAlt
            {
                OutMsg("PASSING ALT:RADAR >= {0}":Format(g_DRTurnStartAlt), cr()).
                SetRunmode(2).
            }
            else
            {
                OutMsg("MISSING ALT:RADAR [{0}] >= {1}":Format(Round(Alt:Radar), g_DRTurnStartAlt), cr()).
            }
        }
        else if g_Runmode = 2
        {
            if Ship:VerticalSpeed >= g_PitchMinSpeed
            {
                OutMsg("MIN PITCH PROGRAM SPEED MET ({0} >= {1}":Format(Ship:VerticalSpeed, g_PitchMinSpeed), cr()).
                SetProgram(22).
            }
            else
            {
                OutMsg("MIN PITCH PROGRAM SPEED MISSED ({0} >= {1}":Format(Ship:VerticalSpeed, g_PitchMinSpeed), cr()).
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
            OutMsg("VERTICAL ASCENT", cr()).
            SetRunmode(1).
        }
    }
    else if g_Program = 22
    {
        if g_Runmode = 1
        {
            OutMsg("ROLL PROGRAM", g_termH - 14).
            // set rollFlag to true.
            SetRunmode(2).
        }
        else if g_RunMode = 2
        {
            if Ship:Apoapsis >= tgtAlt
            {
                if Stage:Number = MECOStage 
                {
                    SetProgram(24).
                }
                else if Stage:Number > g_StageLimit
                {
                    SetProgram(26).
                }
                else
                {
                    set g_AS_Armed to false.
                    SetProgram(28).
                }
            }
            else if Stage:Number = g_StageLimit
            {
                if Ship:AvailableThrust <= 0.01
                {
                    if g_Throt > 0 and Stage:Number = g_StageLimit
                    {
                        SetProgram(30).
                    }
                }
            }
        }
        else if g_Runmode = 3
        {

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
            OutMsg("PITCH PROGRAM", cr()).
            SetRunmode(1).
        }
        
        set g_Steer to choose Ship:Facing:Vector if g_Spin_Active else heading(l_az_calc(g_AzData), Min(90, Max(-11.25, ascAngDel:Call())), rollVal).
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
                if Stage:Number > g_StageLimit
                {
                    SetProgram(26).
                }
                else
                {
                    set g_AS_Armed to false.
                    SetProgram(30).
                }
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
            OutMsg("BURNING TO MECO", cr()).
            SetRunmode(1).
        }
        
        set g_Steer to choose Ship:Facing:Vector if g_Spin_Active else heading(l_az_calc(g_AzData), Min(90, Max(-11.25, ascAngDel:Call())), rollVal).
    }

    else if g_Program = 26
    {
        if g_RunMode > 0
        {
            if Ship:AvailableThrust <= 0.01
            {
                clr(g_line).
                clr(cr()).
                RCS on.
                if Stage:Number > g_StageLimit
                {
                    SetProgram(28).
                }
                else
                {
                    set g_AS_Armed to false.
                    SetProgram(30).
                }
            }
            else
            {
                cr().
                OutMsg("TIME TO SECO: {0}            ":Format(Round(g_ActiveEngines_PerfData:BURNTIMEREMAINING, 2)), cr()).
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
            OutMsg("BURNING TO SECO", cr()).
            SetRunmode(1).
        }
        
        set g_Steer to choose Ship:Facing:Vector if g_Spin_Active else heading(l_az_calc(g_AzData), Min(90, Max(-11.25, ascAngDel:Call())), rollVal).
    }

    else if g_Program = 28
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
                OutMsg("TIME TO TECO: {0}            ":Format(Round(g_ActiveEngines_PerfData:BURNTIMEREMAINING, 2)), cr()).
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
            OutMsg("BURNING TO TECO", cr()).
            SetRunmode(1).
        }
        
        set g_Steer to choose Ship:Facing:Vector if g_Spin_Active else heading(l_az_calc(g_AzData), Min(90, Max(-11.25, ascAngDel:Call())), rollVal).
    }

    else if g_Program = 30
    {
        if g_RunMode = 1
        {
            SetRunmode(4).
            // if Ship:AvailableThrust <= 0.01
            // {
            //     if Stage:Number <= g_StageLimit
            //     {
            //         SetRunMode(4).
            //     }
            //     else
            //     {
            //         set ts0 to Time:Seconds + 3.
            //         SetRunMode(2).
            //     }
            // }
        }
        else if g_RunMode = 2
        {
            if Stage:Number > g_StageLimit
            {
                OutInfo("STAGING").
                if Time:Seconds >= ts0 and Stage:Ready
                {
                    stage.
                }
            }
            else
            {
                clr(cr()).
                SetRunmode(4).
            }
        }
        else if g_Runmode = 4
        {
            SetProgram(32).
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
            OutMsg("FINAL STAGING PROGRAM", cr()).
            SetRunmode(1).
        }
        
        set g_Steer  to heading(l_az_calc(g_AzData), Min(90, Max(0, ascAngDel:Call())), rollVal).
    }

    else if g_Program = 32
    {
        if g_RunMode >= 1
        {
            if Ship:Altitude >= Ship:Body:Atm:Height
            {
                clr(cr()).
                SetProgram(36).
            }
            else
            {
                OutInfo("DIST TO TGT: {0}":Format(Round(Ship:Body:Atm:Height, 1))).
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
            OutMsg("COAST PROGRAM", cr()).
            SetRunmode(1).
        }
        
        set g_Steer  to heading(l_az_calc(g_AzData), Min(90, Max(0, ascAngDel:Call())), rollVal).
    }


    UpdateState(True).

        
    // TODO: Write Abort Handler here
    if AbortSysArmed
    {
        if AbortSysCheck:Call()
        {
            AbortSysAction:Call().
        }
    }

    OutMsg("C:[{0,-1}] | P:[{1,-3}] | R:[{2,-2}] | SL:[{3,-1}]  ":Format(g_Context, g_Program, g_Runmode, g_StageLimit), 0).

    DispLaunchTelemetry().

    cr().
    local btRem to GetActiveBurnTimeRemaining().
    if g_HS_Armed 
    {
        set g_HS_Armed to RunHotStageSubroutine(btrem).
    }
    else if g_AS_Armed 
    {
        if g_AS_Check:Call()
        {
            if g_RCS_Armed
            {
                if Stage:Number - 1 = g_RCS_Stage 
                {
                    RCS on.
                    set g_RCS_Armed to false.
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
        if g_SpinStab:STG = Stage:Number - 1
        {
            if btRem > 0 //  or Ship:AvailableThrust > 0
            {
                if g_Spin_Check:Call(btrem)
                {
                    OutStr("Passed g_Spin_Check", g_termH - 10).
                    OutStr("Values: [btrem:{0}]":Format(btrem), g_termH - 9).
                    g_Spin_Action:Call().
                }
                else
                {
                    OutInfo("SpinStabilization [Armed]").
                    OutInfo("T{0})":Format(Round(g_SpinStab:LEADTIME - btRem, 2))).
                }
            }
            else
            {
                OutInfo("SpinStabilization [Waiting]").
                clr(cr()).
            }
        }
        else
        {
            OutInfo("SpinStabilization [Ready]").
            OutInfo("g_SpinStab Stage: [{0}]":Format(g_SpinStab:STG)).
        }
    }
    else if rollFlag
    {
        if VAng(Ship:Up:Vector, rollVec) <= 2.5
        {
            set SteeringManager:RollTorqueFactor to 0.25.
            set rollFlag to false.
            OutMsg("ROLL COMPLETE", g_termH - 14).
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

    if LESArmed
    {
        if LESCheck:Call()
        {
            set LESArmed to LESAction:Call().
            clr(cr()).
        }
        else
        {
            OutMsg("LES jettison: Armed", cr()).
        }
    }

    if MECOArmed
    {
        if MECORunning
        {
            set MECOArmed to MECOAction:Call().
            set MECORunning to false.
            OutMsg("MECO: Complete", cr()).
        }
        else if MECOCheck:Call()
        {
            set MECORunning to true.
            OutMsg("MECO: Running", cr()).
        }
        else
        {
            OutInfo("MECO: T-{0} ":Format(Round(MECO - MissionTime, 2)), cr()).
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

    set g_TermChar to "".
}
set g_Throt to 0.
SetProgram(0).
SetRunmode(0).
UpdateState(True).

OutMsg("THAT'S ALL FOLKS", 5).