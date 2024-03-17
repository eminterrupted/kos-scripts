@LazyGlobal off.
clearscreen.

parameter params is list().

RunOncePath("0:/lib/depLoader.ks").
RunOncePath("0:/lib/launch.ks").


Core:DoEvent("Open Terminal").

// Local vars
local ascAngle to 88.25.
local launchCommit to false.
local MECO to -1.
local meSpoolTime to 0.
local rollFlag to false.
local seIgnitionTime to -1.
local sePresent to false.
local hsSpoolTime to 0.
local seSpinAt to 0.
local tgtAlt to Ship:Body:SOIRadius.
local tgtHdg to 30.
local launchTS to list().

// TODO: Create some sort of display output


// Ship systems initialization
SetProgram(1).
local mainEngs to list().
local multistage to false.
local padStage to Stage:Number.
local upperEngs to list().

// Hydrate the engine object
SetProgram(2).
set g_ShipEngines to GetShipEngines().

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

SetProgram(8).

InitStateCache().

// * Launch Countdown Loop 
until g_Program >= 20 or g_Abort
{   
    if g_Program = 8
    {
        print "Go to space?" at (0, 2).
        until g_TermChar = Terminal:Input:Enter
        {
            set g_TermChar to "".
            GetTermChar().
            wait 0.01.
        }
        print "Okay, we'll go to space today!" at (0, 2).
        wait 1.
        SetProgram(9).
    }

    // Initialize and increment Program
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
            print "LAUNCH COUNTDOWN: T-{0}  ":Format(Round(Time:Seconds - launchTS[1], 2)) at (0, 5).
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
            print engIgnitionETA at (2, 25).
            if engIgnitionETA >= 0
            {
                SetProgram(14).
            }
            else
            {
                print "LAUNCH COUNTDOWN: T{0}  ":Format(Round(Time:Seconds - launchTS[1], 2)) at (0, 5).
                print "ENGINE IGNTION  : T{0}  ":Format(Round(engIgnitionETA, 2)) at (0, 6).
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
        print "LAUNCH COUNTDOWN: T{0}  ":Format(Round(Time:Seconds - launchTS[1], 2)) at (0, 5).
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
            if g_Runmode < 6 and Time:Seconds >= launchTS[1]
            {
                SetRunmode(6).
            }
            print "LAUNCH COUNTDOWN: T{0}  ":Format(Round(Time:Seconds - launchTS[1], 2)) at (0, 5).
            local aggThrustModifier to 0.
            set g_line to 7.
            for eng in mainEngs
            {
                print " - {0} THRUST: {1} [{2}%]   ":Format(eng:CONFIG, Round(eng:Thrust, 2), Round(100 * (eng:Thrust / eng:MaxPossibleThrustAt(Ship:Altitude)), 2)) at (0, cr()).
                set aggThrustModifier to aggThrustModifier + PMGetField(eng:GetModule("TestFlightReliability_EngineCycle"), "thrust modifier", 1).
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
            print "* ENGINE IGNITION SEQUENCE START *" at (0, 6).
            SetRunmode(1).
        }
    }

    // Liftoff
    else if g_Program = 16
    {
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

    print "P{0,-3}:R{1,3}":Format(g_Program, g_Runmode):PadRight(8) at (0, 40).
}

// Now we arm auto and hot staging if needed
if multistage
{
    if Ship:PartsTaggedPattern("HS|HotStage"):Length > 0 
    {
        ArmHotStaging(g_StageLimit, MECO).
    }
    if Ship:PartsTaggedPattern("SpinDC"):Length > 0
    {
        ArmSpinStabilization(g_StageLimit).
    }
    ArmAutoStaging(g_StageLimit, "MECOTS", MECO).
}
wait 0.01.

SetRunmode(0).
// * Main Loop
until g_Program > 199 or g_Abort
{
    set g_ActiveEngines to GetActiveEngines().

    if g_Program = 20
    {
        if g_RunMode > 1
        {
            if Ship:AvailableThrust <= 0.01 and Ship:Altitude >= Ship:Body:Atm:Height
            {
                SetProgram(30).
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
    else if g_Program = 30
    {
        print "TIME TO AP: {0}            ":Format(Round(ETA:Apoapsis, 2)) at (0, 5).
        if ETA:Apoapsis <= 5 
        {
            SetProgram(199). 
        }
    }
    UpdateState(True).

    // TODO: Write Abort Handler here
    if g_Abort
    {

    }

    print "P{0,-3}:R{1,3}":Format(g_Program, g_Runmode):PadRight(8) at (0, 0).

    DispLaunchTelemetry().

    cr().
    if g_HS_Armed 
    {
        print "HotStaging: Armed" at (0, cr()).
        if g_HS_Check:Call(GetActiveBurnTimeRemaining(g_ActiveEngines))
        {
            g_HS_Act:Call().
        }
    }
    if g_AS_Armed 
    {
        print "Autostaging: Armed" at (0, cr()).
        if g_AS_Check:Call()
        {
            g_AS_Act:Call().
        }
    }
    if g_Spin_Armed
    {
        print "SpinStabilization: Armed" at (0, cr()).
        if g_Spin_Check:Call()
        {
            g_Spin_Act:Call().
        }
    }
}


print "THAT'S ALL FOLKS             " at (0, 5).

















// // Calculate MECO
// local mainEngs to list().
// local shipEngs to GetShipEngines().
// local padStage to Stage:Number - 1.
// for m in Ship:ModulesNamed("LaunchClamp")
// {
//     set padStage to min(padStage, m:Part:Stage).
// }

// for eng in Ship:Engines
// {
//     if eng:stage > padStage
//     {
//         print "[{0}] GettingBurnTime":Format(eng:Config).
//         mainEngs:Add(eng).
//         set MECO to Max(MECO, GetEngineBurnTime(eng)).
//         set meSpoolTime to Max(meSpoolTime, eng:GetModule("ModuleEnginesRF"):GetField("Effective Spool-Up Time")).
//     }
//     else
//     {
//         set sePresent to true.
//     }

//     if eng:Tag:MatchesPattern("HS|HotStage")
//     {
//         if hsEngs:HasKey(eng:Stage) 
//         {
//             hsEngs[eng:Stage]:Add(eng).
//         }
//         else
//         {
//             set hsEngs[eng:Stage] to list(eng).
//         }
//         set hsFlag to true.
//         set hsSpoolTime to Max(hsSpoolTime, eng:GetModule("ModuleEnginesRF"):GetField("Effective Spool-Up Time")).
//     }
// }
// if sePresent
// {
//     set seIgnitionTime to MECO - (hsSpoolTime * 1.08).
//     set seSpinAt to seIgnitionTime - 12.
// }
// else
// {
//     set seIgnitionTime to 999999999.
// }

// print "MECO values: ".
// print " - MECO: {0}":Format(MECO).

// print "Press Enter to go to space!".
// print "Or backspace to not go to space".
// until false
// {
//     GetTermChar().
    
//     if g_TermChar = Terminal:Input:Enter
//     {
//         set launchCommit to true.
//         break.
//     }
//     else if g_TermChar = Terminal:Input:Backspace
//     {
//         break.
//     }
//     else
//     {
//         set g_TermChar to "".
//     }
// }

// if launchCommit
// {
//     set g_Program to 10.


//     local sVal to Ship:Facing. //heading(tgtHdg, ascAngle, 0).
//     lock Steering to sVal.
//     print "P1: Setting up throttle".
//     local tVal to  1.
//     lock throttle to tVal.
//     print "P2: Engine ignition".
//     // until stage:number = 1

//     until Ship:VerticalSpeed > 0.1 
//     {
//         stage.
//         wait meSpoolTime + 0.05.
//     }
//     print "P3: Liftoff".
//     print "P4: Waiting for MECO".
//     local continueFlag to false.
//     local steerFlag to true.

//     set sVal to heading(tgtHdg, ascAngle, 0).

//     until continueFlag
//     {
//         if MissionTime >= seIgnitionTime
//         {
//             if hsEngs:HasKey(Stage:Number - 1)
//             {
//                 for eng in hsEngs[Stage:Number - 1]
//                 {
//                     eng:Activate.
//                 }
//             }
//             set seIgnitionTime to Time:Seconds + 999999.
//         }
//         else if MissionTime >= MECO or Ship:AvailableThrust <= 0.001
//         {
//             if Stage:Number > g_StageLimit
//             {
//                 set tVal to 1.
//                 for eng in mainEngs
//                 {
//                     eng:Shutdown.
//                 }
//                 until Stage:Number = g_StageLimit
//                 {
//                     print "P5: Staging".
//                     stage.
//                     wait 0.25.
//                 }
//                 print "P6: Waiting until alt target or SECO".
//             }
//             else
//             {
//                 set continueFlag to true.
//             }
//         }
//         else if MissionTime > seSpinAt and steerFlag
//         {
//             print "P6.5: Unlocking steering".
//             unlock Steering.
//             set Ship:Control:Roll to 1.
//             set steerFlag to false.
//             set rollFlag to true.
//         }
//     }
//     print "P7: Waiting until Apoapsis".

//     wait until ETA:Apoapsis <= 5.
// }
// else
// {
//     print " ".
//     print "* * * * * * * * * *".
//     print "* Aborting launch *".
//     print "* * * * * * * * * *".
//     print " ".
// }