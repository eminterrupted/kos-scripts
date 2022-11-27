// #include "0:/lib/loadDep.ks"
@lazyGlobal off.

// *~ Dependencies ~* //
// #region
// #endregion


// *~ Variables ~* //
// #region
    // *- Local
    local countdown to 10.
    
    // *- Global
    global g_la_turnAltStart to 500. // Altitude at which the vessel will begin a gravity turn
    global g_la_turnAltEnd   to body:atm:height * 0.75. // Altitude at which the vessel will begin a gravity turn

// #endregion


// *~--- Functions ---~* //
// #region

// *- Countdown
// #region

    // Countdown :: [<scalar>IgnitionSequenceStartSec] -> none
    // Performs the countdown
    global function LaunchCountdown
    {
        parameter t_engStart to -2.75.

        local arm_engStartFlag  to true.
        local t_launch          to time:seconds + countdown.
        local launchCommit      to false.

        set t_engStart          to t_launch - abs(t_engStart).
        OutMsg("LAUNCH: T{0}s":format(round(time:seconds - t_launch, 2))).

        until time:seconds >= t_launch or launchCommit
        {
            if time:seconds >= t_engStart 
            {
                if arm_engStartFlag
                {
                    EngineIgnitionSequence().
                    OutInfo("Ignition!").
                    set arm_engStartFlag to false.
                }
                else
                {
                    LaunchCommitValidation(t_launch).
                    OutMsg("Liftoff!").
                    OutInfo("",0).
                    OutInfo("",1).
                }
            }
            OutMsg("LAUNCH: T{0}s":format(round(time:seconds - t_launch, 2))).
        }
    }

    local function LaunchCommitValidation
    {
        parameter t_liftoff to time:seconds,
                  launchThrustThreshold to 0.975.

        local t_engPerfAbort    to t_liftoff + 5.
        local launchCommit to false.
        
        OutInfo("Validating engine performance...").
        set g_activeEngines to ActiveEngines().
        local thrustPerf to 0.
        set tVal to 1.
        until time:seconds > t_engPerfAbort or launchCommit
        {
            set g_activeEngines to ActiveEngines().
            set thrustPerf to g_activeEngines["CURTHRUST"] / g_activeEngines["AVLTHRUST"].

            if time:seconds > t_liftoff
            {
                 if thrustPerf > launchThrustThreshold
                {
                    set launchCommit to true.
                }
                else
                {
                    DispEngineTelemetry().
                    wait 0.01.
                }
            }
            wait 0.01.
            OutMsg("LAUNCH: T{0}s":format(round(time:seconds - t_liftoff, 2))).
        }
        wait 0.01.

        // If we are good, send it! If not, kill throt and trigger a breakpoint
        if launchCommit 
        {
            stage.
        }
        else
        {
            set tVal to 0.
            OutMsg("*** ENGINE UNDERPERF ABORT ***").
            OutInfo().
            Breakpoint().
            print 1 / 0.
        }
        DispClr().
    }


    local function EngineIgnitionSequence
    {
        set tVal to 1.
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
                  f_shape is 1. // TODO: Implement this 'shape' factor to provide a way to control the steepness of the trajectory

        local tgt_effAng to 90.
        
        if ship:altitude < g_la_turnAltStart
        {
        }
        else
        {
            local cur_pitAng to pitch_for(ship).
            local tgt_effAlt to tgt_alt - g_la_turnAltStart.
            local cur_effAlt to 0.1 + ship:altitude - g_la_turnAltStart.
            local tgt_pitAng to max(-10, 90 * (1 - (cur_effAlt / tgt_effAlt))).
            set   tgt_effAng to max(cur_pitAng - 3.5, min(cur_pitAng + 3.5, tgt_pitAng)) * f_shape.
        }
        return tgt_effAng.
    }
// #endregion


// #endregion