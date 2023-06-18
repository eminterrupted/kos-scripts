// #include "0:/lib/libLoader.ks"
@lazyGlobal off.

// *~ Dependencies ~* //
// Required libraries not loaded by libLoader by default go here
// #region
// #endregion


// *~ Variables ~* //
// Local and global variables used in this library
// #region
    // *- Local
    // #region
    // #endregion

    // *- Global
    // #region
    // #endregion
// #endregion


// *~ Functions ~* //
// #region
  
    /// *- Pre-Launch Configuration
// #region

    // ConfigureLaunchPad
    //
    global function ConfigureLaunchPad
    {
        local CurrentTimeSpan to TimeSpan(TIME:SECONDS).
        local lpClamps to Ship:ModulesNamed("LaunchClamp").
        local lpLights to choose lpClamps[0]:Part:PartsDubbedPattern("Light") if lpClamps:Length > 0 else list().

        if lpLights:Length > 0
        {
            for p in lpLights 
            { 
                if p:HasModule("ModuleLight") 
                {
                    local m to p:GetModule("ModuleLight"). 

                    if CurrentTimeSpan:HOUR > 11 and CurrentTimeSpan:HOUR <= 23
                    {
                        DoAction(m, "Turn Light Off", true).
                    }
                    else
                    {
                        DoAction(m, "Turn Light On", true).
                    }
                }
            }
        }

        local lpEventList to list(
            "Raise Walkway"
            ,"Lower Safety Gate"
            ,"Open Upper Clamp"
            ,"Partial Retract Tower Step 1"
        ).
        for m in Ship:ModulesNamed("ModuleAnimateGenericExtra")
        {
            if m:Part:Name:MatchesPattern("^AM.MLP.*")
            {
                for lpEvent in lpEventList
                {
                    if DoEvent(m, lpEvent) = 1
                    {
                        wait 1.
                    }
                }
                if m:HasField("Car Height Adjust")
                {
                    m:SetField("Car Height Adjust", 0).
                }
            }
        }
    }

// #endregion

// *- Launch Countdown
// #region

    // LaunchCountdown :: [<scalar>IgnitionSequenceStartSec] -> none
    // Performs the countdown
    global function LaunchCountdown
    {
        parameter t_engStart to -2.75.

        local launchStage to 99.
        for p in Ship:PartsDubbedPattern("Clamp|AM\.MLP")
        {
            set launchStage to min(launchStage, p:stage).
        }

        local arm_engStartFlag   to true.
        local engSpoolLex to Lexicon().
        local totalSpoolTime to 0.
        local maxSpoolTime to 0.
        from { local i to Stage:Number - 1.} until i < launchStage step { set i to i - 1.} do 
        {
            local stgMaxSpool to 0.
            local stgEngSpecs to GetEnginesSpecs(GetEnginesForStage(i)).
            for eng in stgEngSpecs:Values
            {
                if eng:IsType("Lexicon")
                {
                    set stgMaxSpool  to max(stgMaxSpool, eng:SpoolTime).
                    set maxSpoolTime to max(eng:SpoolTime, maxSpoolTime).
                }
            }
            set totalSpoolTime to totalSpoolTime + stgMaxSpool.
            set engSpoolLex[i] to stgMaxSpool.
        }
        local countdown            to maxSpoolTime + 3.
        local t_launch           to Time:Seconds + countdown.
        local launchCommit       to false.
        //local hasSpool           to engSpoolLex[Stage:Number - 1][0].
        // print engSpoolLex at (5, 10).
        // Breakpoint().
        //local spoolTime          to engSpoolLex[Stage:Number - 1].
        set t_engStart           to t_launch - (maxSpoolTime * 1.025).
        
        OutMsg("LAUNCH: T{0}s":format(round(Time:Seconds - t_launch, 2))).

        local l_TS to 0.

        until Time:Seconds >= t_launch or launchCommit
        {
            if Time:Seconds >= t_engStart 
            {
                if arm_engStartFlag
                {
                    if Time:Seconds > l_TS
                    {
                        EngineIgnitionSequence().
                        set l_TS to Time:Seconds + (engSpoolLex[Stage:Number] / 1.50).
                    }

                    if Stage:Number = launchStage + 1
                    {
                        set arm_engStartFlag to false.
                    }
                }
                else
                {
                    if LaunchCommitValidation(t_launch, maxSpoolTime)
                    {
                        // for p in Ship:PartsDubbedPattern("AM\.MLP.*swing.*arm.*")
                        // {
                        //     RetractSwingArms(p).
                        // }
                        until Stage:Number = launchStage 
                        { 
                            wait until Stage:Ready. 
                            stage.
                        }
                        OutMsg("Liftoff!").
                        OutInfo().
                    }
                    else
                    {
                        OutMsg("*** ABORT ***").
                        OutInfo().
                        Breakpoint().
                        wait 10.
                        return false.
                    }
                }
                wait 0.01.
            }

            OutMsg("LAUNCH: T{0}s":format(round(Time:Seconds - t_launch, 2))).
        }
        return true.
    }



    local function LaunchCommitValidation
    {
        parameter t_liftoff to Time:Seconds,
                  t_spoolTime to 0.1,
                  launchThrustThreshold to 0.985.

        // local abortFlag         to false.
        // local launchCommit      to false.
        local engPerfAbort    to t_liftoff + 5.
        local thrustPerf        to 0.
        set t_spoolTime         to max(0.09, t_spoolTime).

        // OutInfo("Validating engine performance...").
        wait 0.01.
        set g_activeEngines to GetActiveEngines().
        set t_val to 1.
        wait 0.01.

        if ship:status = "PRELAUNCH" or ship:status = "LANDED"
        {
            until Time:Seconds > engPerfAbort
            {  
                wait 0.01.
                if t_spoolTime > 0.1
                {
                    set g_ActiveEngines to GetActiveEngines().
                    set g_ActiveEngines_Data to GetEnginesPerformanceData(g_ActiveEngines).
                    set thrustPerf to max(0.0001, g_ActiveEngines_Data["ThrustPct"]).

                    if Time:Seconds > t_liftoff
                    {
                        //OutInfo("EngStatus: {0}":Format(_engMod:GetField("Status")), 1).
                        OutInfo("[Ignition Status]: {0}":Format(g_ActiveEngines_Data["Ignition"])).
                        // if g_ActiveEngines["ENGSTATUS"]["Status"] = "Failed"
                        // {
                        //     set t_val to 0.
                        //     return false.
                        // }
                        if thrustPerf > launchThrustThreshold
                        {
                            return true.
                        }
                    }
                    DispEngineTelemetry(g_ActiveEngines_Data).
                }
                else if Time:Seconds > t_liftoff
                {
                    return true.
                }
                OutMsg("LAUNCH: T{0}s":format(round(Time:Seconds - t_liftoff, 1))).
                PrintDisp().
            }
        }
        else
        {
            OutMsg("ERROR: Tried to validate launch, but already airborne!").
            OutInfo("Line 239").
            return false.
        }
        
        // Performance not validated by abort time, so return false.
        OutInfo("Line 244").
        return false.
    }

    local function EngineIgnitionSequence
    {
        set t_Val to 1.
        stage.
        wait 0.025.
        set g_ActiveEngines to GetActiveEngines().
    }
    // #endregion


    // *- Part Module Manipulation
    // #region

    // Retract Swing Arms
    global function RetractSwingArms
    {
        parameter _part.

        if _part:Tag:MatchesPattern("left")
        {
            from { local i to 0.} until i = _part:modules:length step { set i to i + 1.} do
            {
                local m to _part:GetModuleByIndex(i).
                if DoEvent(m, "retract arm left")
                {
                    break.
                }
                else if DoAction(m, "retract arm left", true)
                {
                    break.
                }
            }
        }
        else
        {
            from { local i to 0.} until i = _part:modules:length step { set i to i + 1.} do
            {
                local m to _part:GetModuleByIndex(i).
                if DoEvent(m, "retract arm right")
                {
                    break.
                }
                else if DoAction(m, "retract arm right", true)
                {
                    break.
                }
            }
        }
    }
    // #endregion
// #endregion