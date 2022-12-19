// #include "0:/lib/loadDep.ks"
@lazyGlobal off.

// *~ Dependencies ~* //
// #region
// #endregion


// *~ Variables ~* //
// #region
    // *- Local
    local countdown to 5.
    
    // *- Global
    global g_la_turnAltStart to 500. // Altitude at which the vessel will begin a gravity turn
    global g_la_turnAltEnd   to body:atm:height * 0.90. // Altitude at which the vessel will begin a gravity turn

// #endregion


// *~--- Functions ---~* //
// #region

// *- Countdown
// #region

    // Given a stage number, it will determine if any engines in that stage have engine spool properties
    global function CheckEngineSpool
    {
        parameter stgNum.

        local hasSpoolTime to false.
        local maxSpoolTime to 0.0001.

        for _e in ship:engines 
        {
            if _e:stage = stgNum
            {
                local _m to _e:getModule("ModuleEnginesRF").
                if _m:hasField("effective spool-up time") 
                {
                    set maxSpoolTime to max(_m:getField("effective spool-up time"), maxSpoolTime).
                }
                else
                {
                    set maxSpoolTime to maxSpoolTime.
                }
            }
        }
        return list(hasSpoolTime, maxSpoolTime).
    }

    // Countdown :: [<scalar>IgnitionSequenceStartSec] -> none
    // Performs the countdown
    global function LaunchCountdown
    {
        parameter t_engStart to -2.75.

        local arm_engStartFlag   to true.
        local t_launch           to Time:Seconds + countdown.
        local launchCommit       to false.
        local engSpool           to CheckEngineSpool(stage:number - 1). 
        local hasSpool           to engSpool[0].
        local spoolTime          to engSpool[1].
        set t_engStart           to t_launch - (spoolTime * 1.1).
        
        OutMsg("LAUNCH: T{0}s":format(round(Time:Seconds - t_launch, 2))).

        until Time:Seconds >= t_launch or launchCommit
        {
            if Time:Seconds >= t_engStart 
            {
                if arm_engStartFlag
                {
                    EngineIgnitionSequence().
                    OutInfo("Ignition!").
                    set arm_engStartFlag to false.
                }
                else
                {
                    if LaunchCommitValidation(t_launch, spoolTime)
                    {
                        stage.
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
        local t_engPerfAbort    to t_liftoff + 5.
        local thrustPerf to 0.
        set t_spoolTime to max(0.09, t_spoolTime).

        OutInfo("Validating engine performance...").
        set g_activeEngines to ActiveEngines().
        set t_val to 1.

        if ship:status = "PRELAUNCH" or ship:status = "LANDED"
        {
            until Time:Seconds > t_engPerfAbort
            {  
                if t_spoolTime > 0.1
                {
                    set g_activeEngines to ActiveEngines().
                    set thrustPerf to max(0.0001, g_activeEngines["CURTHRUST"]) / max(0.0001, g_activeEngines["AVLTHRUST"]).
                    
                    if Time:Seconds > t_liftoff
                    {
                        if g_activeEngines["ENGSTATUS"] = "Failed"
                        {
                            set t_val to 0.
                            return false.
                        }
                        else if thrustPerf > launchThrustThreshold
                        {
                            return true.
                        }
                        else
                        {
                            DispEngineTelemetry().
                        }
                    }
                }
                else if Time:Seconds > t_liftoff
                {
                    wait 0.01.
                    return true.
                }
                OutMsg("LAUNCH: T{0}s":format(round(Time:Seconds - t_liftoff, 2))).
            }
        }
        else
        {
            OutMsg("ERROR: Tried to validate launch, but already airborne!").
            return false.
        }
        
        // Performance not validated by abort time, so return false.
        return false.
    }


    local function EngineIgnitionSequence
    {
        set t_val to 1.
        stage.
        wait 0.05.
        set g_activeEngines to ActiveEngines().
    }

// #endregion

// *- Guidance
// #region

    // GetAscentAngle :: <scalar>tAlt (Target Altitude), [<scalar>shapeFactor] -> <scalar>AscentAngle (-10.0 - 90.0)
    // Returns a valid launch angle for the current vessel during an ascent 
    // based on current altitude and target altitude. Used to provide continuous 
    // guidance as the vessel ascends. 
    global function GetAscentAngle
    {
        parameter tgt_alt is body:atm:height * 0.86,
                  tgt_ap is body:atm:height * 0.86,
                  f_shape is 1.025. // 'shape' factor to provide a way to control the steepness of the trajectory. Values > 1 = steeper, < 1 = flatter

        local tgt_effAng to 90.
        local tgt_effAP  to tgt_ap / 2.
        if ship:altitude < g_la_turnAltStart
        {
        }
        else
        {
            local cur_pitAng to choose pitch_for(ship, ship:srfprograde) if ship:altitude > 100000 else pitch_for(ship, ship:prograde).
            local tgt_effAlt to tgt_alt - g_la_turnAltStart.
            local cur_effAlt to 0.1 + ship:altitude - g_la_turnAltStart.
            local cur_altErr to cur_effAlt / (tgt_effAlt / 2).
            local tgt_pitAng to max(-2, 90 * (1 - cur_altErr)).// * abs(f_shape - 1).
            local tgt_angErr to min(15, max(4, 15 * min(1, (Ship:Apoapsis / (tgt_ap / 2))))) * f_shape.
            set   tgt_effAng to max(tgt_pitAng, cur_pitAng - tgt_angErr). // min(90, max(cur_pitAng - tgt_angErr, min(cur_pitAng + tgt_angErr, tgt_pitAng)) * f_shape).

            local ascentStatObj to lexicon(
                "cur_pitAng",  round(cur_pitAng, 5)
                ,"tgt_alt",    round(tgt_alt)
                ,"tgt_ap",     round(tgt_ap)
                ,"tgt_effAlt", round(tgt_effAlt)
                ,"cur_effAlt", round(cur_effAlt)
                ,"cur_altErr", round(cur_altErr, 5)
                ,"tgt_pitAng", round(tgt_pitAng, 5)
                ,"tgt_angErr", round(tgt_angErr, 5)
                ,"tgt_effAng", round(tgt_effAng, 5)
            ).
            DispAscentAngleStats(ascentStatObj).
            //Breakpoint().
        }
        return tgt_effAng.
    }

    // Local helper function
    local function DispAscentAngleStats
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


// #endregion