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
    global g_la_turnAltEnd   to body:atm:height * 0.90. // Altitude at which the vessel will begin a gravity turn

// #endregion


// *~--- Functions ---~* //
// #region

// *- Countdown
// #region

    // Given a stage number, it will determine if any engines in that stage have engine spool properties
    global function CheckEngineSpool
    {
        parameter stgNum to stage:number - 1.

        local hasSpoolTime to false.
        local maxSpoolTime to 0.001.

        for _e in ship:engines 
        {
            if _e:stage = stgNum
            {
                local _m to _e:getModule("ModuleEnginesRF").
                if _m:hasField("effective spool-up time") 
                {
                    set hasSpoolTime to true.
                    set maxSpoolTime to max(maxSpoolTime, _m:getField("effective spool-up time")).
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
        local t_launch           to time:seconds + countdown.
        local launchCommit       to false.
        local engSpool           to CheckEngineSpool(stage:number - 1). 
        local hasSpool           to engSpool[0].
        local spoolTime          to engSpool[1].
        set t_engStart           to t_launch - spoolTime.
        
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
                    LaunchCommit_validation(t_launch, spoolTime).
                    OutMsg("Liftoff!").
                    OutInfo("",0).
                    OutInfo("",1).
                }
                wait 0.01.
            }

            OutMsg("LAUNCH: T{0}s":format(round(time:seconds - t_launch, 2))).
        }
    }

    local function LaunchCommit_validation
    {
        parameter t_liftoff to time:seconds,
                  t_spoolTime to 0.1,
                  launchThrustThreshold to 0.975.

        local launchCommit      to false.
        local t_engPerfAbort    to t_liftoff + 5.
        local thrustPerf to 0.
        set t_spoolTime to max(0.09, t_spoolTime).

        OutInfo("Validating engine performance...").
        set g_activeEngines to ActiveEngines().
        set t_val to 1.

        if ship:status = "PRELAUNCH" or ship:status = "LANDED"
        {
            until time:seconds > t_engPerfAbort or launchCommit
            {   
                if t_spoolTime > 0.1
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
                        }
                    }
                }
                else if time:seconds > t_liftoff
                {
                    set launchCommit to true.
                    wait 0.01.
                }
                OutMsg("LAUNCH: T{0}s":format(round(time:seconds - t_liftoff, 2))).
            }

            // If we are good, send it! If not, kill throt and trigger a breakpoint
            if launchCommit 
            {
                stage.
            }
            else
            {
                set t_val to 0.
                OutMsg("*** ENGINE UNDERPERF ABORT ***").
                OutInfo().
                Breakpoint().
                print 1 / 0.
            }
            DispClr().
        }
        else
        {
            OutMsg("ERROR: Tried to validate launch, but already airborne!").
        }
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