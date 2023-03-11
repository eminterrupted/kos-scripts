// #include "0:/lib/libLoader.ks"
@lazyGlobal off.

// *~ Dependencies ~* //
// #region
// #endregion


// *~ Variables ~* //
// #region
    // *- Local
    local countdown                 to 5.
    local lc_MinAoA                 to -45.
    local lc_MaxAoA                 to 45.
    local proSrfObtBlendStartAlt    to 100000.
    local atmBlendDiv               to Body:ATM:Height - proSrfObtBlendStartAlt.

    // *- Global
    global g_la_turnAltStart        to Ship:Altitude + (Ship:Bounds:Size:Z * 2).    // Altitude at which the vessel will begin a gravity turn
                                                                                    // taken from the bounding box of the ship on the launch pad
                                                                                    // and is 2x the height of the vessel/launch pad tower
    global g_la_turnAltEnd          to body:Atm:height * 0.925. // Altitude at which the vessel will end a gravity turn
    

// #endregion


// *~--- Functions ---~* //
// #region

// *- Guidance
// #region

    // GetAscentAngle :: <scalar>tAlt (Target Altitude), [<scalar>shapeFactor] -> <scalar>AscentAngle (-10.0 - 90.0)
    // Returns a valid launch angle for the current vessel during an ascent 
    // based on current altitude and target altitude. Used to provide continuous 
    // guidance as the vessel ascends. 
    global function GetAscentAngle
    {
        parameter tgt_alt is body:Atm:height * 0.86,
                  tgt_ap is body:Atm:height * 0.86,
                  _fShape is 1.125. // 'shape' factor to provide a way to control the steepness of the trajectory. Values < 1 = steeper, > 1 = flatter

        local tgt_effAng to 90.
        // local tgt_effAP  to tgt_ap. // max(body:Atm:Height, tgt_ap / 2).
        if Ship:Altitude < g_la_turnAltStart
        {
        }
        else // if g_ConsumedResources:HasKey("TimeRemaining")
        {
            // if g_ConsumedResources["TimeRemaining"] < 5
            // {
            //     local pitFacing to pitch_for(Ship, Ship:Facing).
            //     local pitPro    to pitch_for(Ship, Ship:SrfPrograde).
            //     set tgt_EffAng to pitFacing + ((pitFacing - pitPro) * Body:Atm:AltitudePressure(Ship:Altitude)).
            // }
            // else
            // {
            local srfProPit to pitch_for(Ship, Ship:SrfPrograde).
            local obtProPit to pitch_for(Ship, Ship:Prograde).
            // local pitDiff   to VAng(Ship:SrfPrograde:Vector, Ship:Prograde:Vector).
            local nrmlzdAlt to Ship:Altitude - proSrfObtBlendStartAlt.
            // local cur_pitAng to choose srfProPit if ship:Altitude < 100000 else 
            //     choose ((srfProPit + obtProPit) / 2) if ship:altitude < body:Atm:Height else 
            //     obtProPit.
            local cur_pitAng to choose srfProPit if Ship:Altitude <= proSrfObtBlendStartAlt else
                (srfProPit * (1 - (nrmlzdAlt / atmBlendDiv))) + (obtProPit * (nrmlzdAlt / atmBlendDiv)).
            local tgt_effAlt to tgt_alt - g_la_turnAltStart.
            local cur_effAlt to 0.1 + ship:Altitude - g_la_turnAltStart.
            local cur_altErr to cur_effAlt / (tgt_effAlt / 2).
            local tgt_pitAng to max(-5, 90 * (1 - cur_altErr)).// * abs(f_shape - 1).
            // local cur_pitRatio to Round(Ship:Altitude / (Body:Atm:Height + 25000), 4).
            // local tgt_pitRatio to Round(Ship:Apoapsis / tgt_effAP, 4).
            //local eff_pitRatio to choose cur_pitRatio if Ship:Altitude < Body:Atm:Height * 0.625 else tgt_pitRatio.
            local eff_pitRatio to (1 - Body:Atm:AltitudePressure(Ship:Altitude)) * _fShape.
            //local tgt_angErr to min(10, max(lc_MaxAoA * eff_pitRatio, 10 * min(1, eff_pitRatio * lc_MinAoA))) * f_shape.
            // local tgt_angErr to min((30 * eff_pitRatio) , max(-30, (90 * eff_pitRatio))).
            local tgt_angErr to min(15, max(-15, 90 * eff_pitRatio)).
            // if Ship:Altitude > Body:Atm:Height 
            // {
            //     set tgt_angErr to tgt_angErr / (1 + g_ActiveEnginesLex:CURTWR).
            // }
            set   tgt_effAng to max(tgt_pitAng, cur_pitAng - tgt_angErr). // min(90, max(cur_pitAng - tgt_angErr, min(cur_pitAng + tgt_angErr, tgt_pitAng)) * f_shape).
            if tgt_effAng < 0 
            {
                set tgt_effAng to tgt_effAng / -4.
            }
            // }
        }
        // OutInfo("Current Pitch Angle: {0}":Format(Round(tgt_effAng, 2)), 1).
        return tgt_effAng.
    }

    // WIP, AltitudePressure based version of Ascent Angle vs. purely height
    // global function GetAscentAng2
    // {
    //     parameter tgt_alt is body:Atm:height,
    //               tgt_ap is body:Atm:height * 2,
    //               f_shape is 1.0375. // 'shape' factor to provide a way to control the steepness of the trajectory. Values < 1 = steeper, > 1 = flatter

    //     local tgt_effAng to 90.
    //     local tgt_effAP  to max(body:Atm:Height, tgt_ap / 2).
    //     if ship:Altitude < g_la_turnAltStart
    //     {
    //     }
    //     else if g_ConsumedResources:HasKey("TimeRemaining")
    //     {
    //         if g_ConsumedResources["TimeRemaining"] < 5
    //         {
    //             set tgt_EffAng to pitch_for(ship, ship:srfPrograde).
    //         }
    //         else
    //         {
    //             local cur_pitAng to choose pitch_for(ship, ship:srfprograde) if ship:Altitude < 75000 else 
    //                 choose ((pitch_for(ship, ship:SrfPrograde) + pitch_for(ship, ship:Prograde)) / 2) if ship:altitude < body:Atm:Height else 
    //                 pitch_for(ship, ship:Prograde).
    //             local tgt_effAlt to tgt_alt - g_la_turnAltStart.
    //             local cur_effAlt to 0.1 + ship:Altitude - g_la_turnAltStart.
    //             local cur_altErr to cur_effAlt / (tgt_effAlt / 2).
    //             local tgt_pitAng to max(-5, 90 * (1 - cur_altErr)).// * abs(f_shape - 1).
    //             local cur_pitRatio to Round(Ship:Altitude / (Body:Atm:Height + 25000), 4).
    //             local tgt_pitRatio to Round(Ship:Apoapsis / tgt_effAP, 4).
    //             local eff_pitRatio to choose cur_pitRatio if Ship:Altitude < Body:Atm:Height * 0.625 else tgt_pitRatio.
    //             //local tgt_angErr to min(10, max(lc_MaxAoA * eff_pitRatio, 10 * min(1, eff_pitRatio * lc_MinAoA))) * f_shape.
    //             local tgt_angErr to min(12.5, max(-12.5, ((100 * eff_pitRatio) / 2))) * f_shape.
    //             set   tgt_effAng to max(tgt_pitAng, cur_pitAng - tgt_angErr). // min(90, max(cur_pitAng - tgt_angErr, min(cur_pitAng + tgt_angErr, tgt_pitAng)) * f_shape).
    //         }
    //     }
    //     return tgt_effAng.
    // }

    // Local helper function
    global function DispAscentAngleStats
    {
        parameter _statLex,
                  _line is 25.

        set g_line to _line.
        print "ASCENT STATS" at (0, g_line).
        print "------------" at (0, cr()).
        for key in _statLex:keys
        {
            print "{0,-10}: {1}":format(key, _statLex[key]) at (0, cr()).
        }
    }
// #endregion

// *- Countdown
// #region

    // Countdown :: [<scalar>IgnitionSequenceStartSec] -> none
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
        from { local i to Stage:Number - 1.} until i = launchStage step { set i to i - 1.} do 
        {
            local stgMaxSpool to 0.
            local stgEngSpecs to GetEnginesSpecs(GetEnginesForStage(i)).
            for eng in stgEngSpecs:Values
            {
                set stgMaxSpool  to max(stgMaxSpool, eng:SpoolTime).
                set maxSpoolTime to max(eng:SpoolTime, maxSpoolTime).
            }
            set totalSpoolTime to totalSpoolTime + stgMaxSpool.
            set engSpoolLex[i] to stgMaxSpool.
        }
        set countdown            to maxSpoolTime + 3.
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
                            wait until Stage:READY. 
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
                        print 0 / 1.
                    }
                }
                wait 0.01.
            }

            OutMsg("LAUNCH: T{0}s":format(round(Time:Seconds - t_launch, 2))).
        }
    }



    local function LaunchCommitValidation
    {
        parameter t_liftoff to Time:Seconds,
                  t_spoolTime to 0.1,
                  launchThrustThreshold to 0.975.

        // local abortFlag         to false.
        // local launchCommit      to false.
        local engPerfObj        to lexicon().
        local engPerfAbort    to t_liftoff + 5.
        local thrustPerf        to 0.
        set t_spoolTime         to max(0.09, t_spoolTime).

        OutInfo("Validating engine performance...").
        set g_activeEngines to GetActiveEngines().
        set t_val to 1.

        if ship:status = "PRELAUNCH" or ship:status = "LANDED"
        {
            until Time:Seconds > engPerfAbort
            {  
                wait 0.01.
                if t_spoolTime > 0.1
                {
                    set g_ActiveEngines to GetActiveEngines().
                    set engPerfObj to GetEnginesPerformanceData(g_ActiveEngines).
                    set thrustPerf to max(0.0001, engPerfObj["ThrustPct"]).
                    
                    if Time:Seconds > t_liftoff
                    {
                        //OutInfo("EngStatus: {0}":Format(_engMod:GetField("Status")), 1).
                        OutInfo("[Ignition Status]: {0}":Format(engPerfObj["Ignition"]), 1).
                        // if g_ActiveEngines["ENGSTATUS"]["Status"] = "Failed"
                        // {
                        //     set t_val to 0.
                        //     return false.
                        // }
                        if thrustPerf > launchThrustThreshold
                        {
                            return true.
                        }
                        else
                        {
                            OutInfo("Engine Thrust (Pct): {0} ({1}%)":Format(engPerfObj["Thrust"], engPerfObj["ThrustPct"]), 1).
                        }
                    }
                }
                else if Time:Seconds > t_liftoff
                {
                    return true.
                }
                OutMsg("LAUNCH: T{0}s":format(round(Time:Seconds - t_liftoff, 1))).
            }
        }
        else
        {
            OutMsg("ERROR: Tried to validate launch, but already airborne!").
            OutInfo("Line 300", 1).
            return false.
        }
        
        // Performance not validated by abort time, so return false.
        OutInfo("Line 305", 1).
        return false.
    }


    local function EngineIgnitionSequence
    {
        set t_Val to 1.
        stage.
        wait 0.05.
        set g_ActiveEngines to GetActiveEngines().
    }

// #endregion


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