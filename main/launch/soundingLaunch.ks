@LazyGlobal off.
clearscreen.

parameter _params is list().

RunOncePath("0:/lib/depLoader.ks").
RunOncePath("0:/lib/launch.ks").
RunOncePath("0:/lib/log.ks").
RunOncePath("0:/kslib/lib_navball.ks").
RunOncePath("0:/kslib/lib_l_az_calc.ks").

// Local vars
local ascAng to 89.25.
local MECO to -1.
local meSpoolTime to 0.
local tgtHdg to 30.
local launchTS to list().

// Param parsing
if _params:Length > 0
{
    set tgtHdg to ParseStringScalar(_params[0], tgtHdg).
    if _params:length > 1 set ascAng to ParseStringScalar(_params[1], ascAng).
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
        print "TgtHdg: {0} | AscAng: {1}":Format(tgtHdg, ascAng).
        print "Go to space?" at (0, g_line).
        until g_TermChar = Terminal:Input:Enter
        {
            set g_TermChar to "".
            GetTermChar().
            wait 0.01.
        }
        print "Okay, we're gonna do it, we're gonna " at (0, g_line).
        print "go to space today!!! Hold on to your butts!" at (0, cr()).
        wait 2.
        ClearScreen.
        SetProgram(9).
    }

    // Setup control
    if g_Program = 9
    {
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
            print "LAUNCH COUNTDOWN: T{0}  ":Format(Round(Time:Seconds - launchTS[1], 2)):PadRight(Terminal:Width - 24) at (0, g_line).
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
                print "LAUNCH COUNTDOWN: T{0}  ":Format(Round(Time:Seconds - launchTS[1], 2)):PadRight(Terminal:Width - 24) at (0, g_line).
                print "ENGINE IGNTION  : T{0}  ":Format(Round(engIgnitionETA, 2)):PadRight(Terminal:Width - 24) at (0, cr()).
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
        print "LAUNCH COUNTDOWN: T{0}  ":Format(Round(Time:Seconds - launchTS[1], 2)):PadRight(Terminal:Width - 24) at (0, g_line).
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
                print " - {0} THRUST: {1} [{2}%]   ":Format(eng:CONFIG, Round(eng:Thrust, 2), Round(100 * (eng:Thrust / eng:MaxPossibleThrustAt(Ship:Altitude)), 2)) at (0, cr()).
                set aggThrustModifier to aggThrustModifier + GetField(eng:GetModule("TestFlightReliability_EngineCycle"), "thrust modifier", 1).
            }
            
            if g_Runmode = 6
            {
                print aggThrustModifier at (20, 0).
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
            print "* ENGINE IGNITION SEQUENCE START *" at (0, cr()).
            SetRunmode(1).
        }
    }

    // Liftoff
    else if g_Program = 16
    {
        set g_ActiveEngines_PerfData to GetEnginesPerformanceData(g_ActiveEngines, "11100000").
        print "LAUNCH COUNTDOWN: T{0}  ":Format(Round(Time:Seconds - launchTS[1], 2)) at (0, 5).
        if g_RunMode = 0
        {
            print "* LIFTOFF *":PadRight(29) at (0, 6).
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

    print "C:[{0,-1}] | P:[{1,-3}] | R:[{2,-2}] | SL:[{3,-1}]  ":Format(g_Context, g_Program, g_Runmode, g_StageLimit):PadRight(20) at (0, 0).
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
        OutStr("Next Spin Stage: [{0}]":Format(g_SpinStab:STG)).
    }
    OutInfo("Arming Auto-Staging Subroutine").
    ArmAutoStaging(g_StageLimit).
}

// Arm Boosters
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
            print "Alt:Radar":Format(Round(Alt:Radar, 1)) at (0, cr()).
            print "g_DRTurnStartAlt: {0}":Format(g_DRTurnStartAlt) at (0, cr()).

            if Alt:Radar >= g_DRTurnStartAlt
            {
                print "PASSING ALT:RADAR >= {0}":Format(g_DRTurnStartAlt) at (0, cr()).
                SetProgram(22).
            }
            else
            {
                print "MISSING ALT:RADAR [{0}] >= {1}":Format(Round(Alt:Radar), g_DRTurnStartAlt) at (0, cr()).
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
            print "VERTICAL ASCENT":PadRight(g_termW - 15) at (0, cr()).
            SetRunmode(1).
        }
    }
    else if g_Program = 22
    {
        if g_RunMode > 0
        {
            if Ship:Altitude >= 40000 or (Ship:AvailableThrust <= 0.01 and g_Throt > 0)
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
            print "PITCH PROGRAM":PadRight(g_termW - 15) at (0, cr()).
            SetRunmode(1).
        }
        
        set g_Steer to choose Ship:Facing:Vector if g_Spin_Active else heading(tgtHdg, ascAng, 0).
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
                print "TIME TO MECO: {0}            ":Format(Round(g_ActiveEngines_PerfData:BURNTIMEREMAINING, 2)) at (0, cr()).
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
            print "BURNING TO MECO":PadRight(g_termW - 15) at (0, cr()).
            SetRunmode(1).
        }
        
        set g_Steer to choose Ship:Facing:Vector if g_Spin_Active else heading(tgtHdg, ascAng, 0).
    }

    else if g_Program = 30
    {
        if g_RunMode >= 1
        {
            set g_Throt to 0.
            if Ship:Altitude >= Ship:Body:Atm:Height
            {
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
            print "COAST PROGRAM":PadRight(g_termW - 15) at (0, cr()).
            SetRunmode(1).
        }
        
        set g_Steer to heading(tgtHdg, ascAng, 0).
    }
    UpdateState(True).

    // TODO: Write Abort Handler here
    if g_Abort
    {

    }

    print "C:[{0,-1}] | P:[{1,-3}] | R:[{2,-2}] | SL:[{3,-1}]  ":Format(g_Context, g_Program, g_Runmode, g_StageLimit):PadRight(20) at (0, 0).

    DispLaunchTelemetry().

    cr().
    local btRem to GetActiveBurnTimeRemaining(GetActiveEngines(Ship, False)).
    if g_HS_Armed 
    {

        print "HotStaging [Armed] {0}":Format(Round(btRem, 2)) at (0, cr()).
        set g_HS_Armed to RunHotStageSubroutine(btrem).

        // if g_HS_Check:Call(GetActiveBurnTimeRemaining(g_ActiveEngines))
        // if g_HS_Check:Call(btrem)
        // {
        //     g_HS_Action:Call().
        // }
    }
    if g_AS_Armed 
    {
        print "Autostaging: Armed" at (0, cr()).
        if g_AS_Check:Call()
        {
            g_AS_Action:Call().
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
    // if g_Spin_Armed
    // {
    //     // print "SpinStabilization: Armed" at (0, cr()).
    //     print "SpinStabilization [Armed] {0}":Format(Round(btRem - g_SpinStab:LEADTIME, 2)) at (0, cr()).
    //     if g_Spin_Check:Call(btRem)
    //     {
    //         OutInfo("SpinCheckPassed").
    //         g_Spin_Action:Call().
    //     }
    //     else
    //     {
    //         clr(cr()).
    //     }
    // }
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
    if fairingsArmed
    {
        OutInfo("Fairing jettison: Armed").
        if fairingCheck:Call()
        {
            if fairingAction:Call() 
            {
                set fairingsArmed to Ship:PartsTaggedPattern("Ascent\|Fairings.*").
            }
        }
    }
}


print "THAT'S ALL FOLKS             " at (0, 5).