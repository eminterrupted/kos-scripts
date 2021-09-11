@lazyGlobal off.
clearScreen.

parameter launchPlan.

// load dependencies
runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_launch").
runOncePath("0:/lib/lib_mnv").
runOncePath("0:/lib/lib_util").
runOncePath("0:/lib/lib_vessel").
runOncePath("0:/kslib/lib_l_az_calc").
runOncePath("0:/kslib/lib_navigation").

// runmode
local runmode to util_init_runmode().

// variables
// User params
local maxAcc    to 35.
local maxQ      to 0.145.
local stTurn    to 1500.
local stSpeed   to 125.

// Calc params
local azCalcObj to launchPlan:lazObj.
local tgtAp     to launchPlan:tgtAp.
local tgtPe     to launchPlan:tgtPe.
local turnAlt   to max(body:atm:height - 10000, min(body:atm:height, tgtAp * 0.2)).

// Init vars
local burnDur   to 0.
local burnETA   to 0.
local burnTime  to list().
local curAcc    to 0.
local dv        to 0.
local endPitch  to 0.
local finalAlt  to 0.
local mecoTS    to 0.
local mnvTime   to 0.
local stAlt     to 0.
local stPe      to 0.
local tgtVelocity to 0.

// Control vars
local rVal      to 0.
local sVal      to up.
local tVal      to 0.
local tValLim   to 0.67.

// throttle pid controllers
local accPid    to pidLoop().
local qPid      to pidLoop().

// Triggers
// Setup the fairing trigger
local hasFairing to choose true if ship:modulesNamed("ProceduralFairingDecoupler"):length > 0 or ship:modulesNamed("ModuleProceduralFairing"):length > 0 else false.
if hasFairing 
{
    when ship:altitude > body:atm:height + 250 then
    {
        ves_jettison_fairings().
    }
}

// Staging trigger
when ship:availablethrust <= 0.1 and tVal > 0 and missionTime > 0 then
{
        disp_info("Staging").
        ves_safe_stage().
        disp_info().
        accPid:reset.
        if stage:number > 0 preserve.
}

// Set up the display
disp_terminal().
disp_main(scriptPath():name).

// Lock steering and throttle to vars
lock steering to sVal.
lock throttle to tVal.

// Main program loop
until runmode = -1 
{

    // Countdown
    if runmode = 0 
    {
        // Toggle AG8 for relay_planner tracking
        ag8 off.

        // Control
        set sVal to heading(90, 90, -90).
        set tVal to 0.
        
        // Setup countdown
        local cdStamp   to time:seconds + 10.
        lock  countdown to time:seconds - cdStamp.

        //-- Main --//

        // Countdown
        until countdown >= -4 
        {
            disp_msg("COUNTDOWN T" + round(countdown, 1)).
            wait 0.05.
        }
        launch_pad_gen(false).

        until countdown >= -1.5
        {
            disp_msg("COUNTDOWN T" + round(countdown, 1)).
            wait 0.05.
        }
        launch_engine_start(cdStamp).
        set tVal to 1.
        lock throttle to tVal.

        until countdown >= -0.25 
        {
            disp_msg("COUNTDOWN T" + round(countdown, 1)).
            wait 0.05.
        }
        launch_pad_arms_retract().

        until countdown >= 0
        {
            disp_msg("COUNTDOWN T" + round(countdown, 1)).
            wait 0.05.
        }
        launch_pad_holdowns_retract().
        if missionTime <= 0.01 stage.  // Release launch clamps at T-0.
        ag8 on.     // Action group cue for liftoff
        ag10 off.   // Reset ag10 (is true to initiate launch)
        unlock countdown.
        disp_info().
        disp_info2().
        // End countdown

        set runmode to util_set_runmode(10).
    }

    // Clearing the tower
    else if runmode = 10
    {
        disp_msg("Vertical ascent").
        if alt:radar >= 250
        {
            set runmode to util_set_runmode(20).
        }
        else
        {
            disp_telemetry().
            wait 0.01.
        }

    }

    // Roll program
    else if runmode = 20 
    {
        disp_info("Roll program").
        set sVal to heading(l_az_calc(azCalcObj), 90, rVal).
        if ship:altitude >= stTurn or ship:verticalspeed >= stSpeed
        {
        set stAlt to ship:altitude.
        disp_info().   
        set runmode to util_set_runmode(30).
        }
        else
        {
            if ves_roll_settled() disp_info().
            disp_telemetry().
            wait 0.01.
        }
    }

    // Gravity turn
    else if runmode = 30
    {
        disp_msg("Gravity turn").

        set qPid to pidLoop(5, 0, 0, -1, 1).
        set qPid:setpoint to maxQ.
        set accPid to pidLoop(0.02, 0, 0, -1, 1).
        set accPid:setpoint to maxAcc.
        set curAcc to ship:maxThrust / ship:mass.

        if ship:altitude >= turnAlt or ship:apoapsis >= tgtAp * 0.975
        {
            set runmode to util_set_runmode(40).
        }
        else
        {
            qPid:update(time:seconds, ship:q).
            accPid:update(time:seconds, curAcc).
            if ship:q >= maxQ or curAcc >= maxAcc 
            {
                local qVal to max(0.33, min(1, 1 + qPid:update(time:seconds, ship:q))).
                local aVal to max(0.33, min(1, 1 + accPid:update(time:seconds, curAcc))).
                set tVal to min(qVal, aVal).
            }
            else
            {
                set tVal to 1.
            }

            set sVal to heading(l_az_calc(azCalcObj), launch_ang_for_alt(turnAlt, stAlt, endPitch), rVal).
            disp_telemetry().
            wait 0.01.
        }

    }

    // Leveled out, burning against the horizon
    else if runmode = 40
    {
        disp_msg("Post-turn burning to apoapsis").
        if ship:apoapsis >= tgtAp * 0.995
        {
            disp_msg().
            set runmode to util_set_runmode(50).
        }
        else
        {
            set sVal to heading(l_az_calc(azCalcObj), launch_ang_for_alt(turnAlt, stAlt, endPitch), rVal).
            set tVal to max(tValLim, min(1, 1 + accPid:update(time:seconds, curAcc))).
            disp_telemetry().
        }

    }

    // Slowing down on the burn
    else if runmode = 50
    {
        disp_msg("Slow burn to apoapsis").
        set finalAlt to choose tgtAp * 1 if ship:altitude >= body:atm:height else tgtAp * 1.00125.
        if ship:apoapsis >= finalAlt
        {
            set tVal to 0.
            disp_info("SECO").
            wait 1.
            disp_info().
            set runmode to util_set_runmode(60).
        }
        else
        {
            set sVal to heading(l_az_calc(azCalcObj), launch_ang_for_alt(turnAlt, stAlt, endPitch), rVal).
            set tVal to max(tValLim, min(1, 1 - (ship:apoapsis / tgtAp))).
            disp_telemetry().
            wait 0.01.
        }
    }

    // Coasting to space
    else if runmode = 60
    {
        disp_msg("Coasting to space").
        if ship:altitude >= body:atm:height or ship:verticalspeed < 0
        {
            set runmode to util_set_runmode(100).
            clearScreen.
        }
        else
        {
            set sVal to ship:prograde.
            // Correction burn if needed
            if ship:apoapsis <= tgtAp * 0.995
            {
                disp_info("Correction burn").
                until ship:apoapsis >= tgtAp * 1.0015
                {
                    set tVal to max(tValLim, min(1, 1 - (ship:apoapsis / tgtAp))).
                }
                disp_info().
            }
            set tVal to 0.
            disp_telemetry().
            wait 0.01.
        }
    }

    // Circ burn
    else if runmode = 100
    {
        disp_main(scriptPath).
        disp_msg("Calculating circ burn data").
        set mnvTime     to time:seconds + eta:apoapsis.
        set stPe        to ship:periapsis.
        //local dv            to mnv_dv_hohmann(stAlt, tgtPe)[1].
        //local dv            to mnv_dv_bi_elliptic(ship:periapsis, 0, tgtPe, tgtPe, tgtAp, ship:body)[1].
        set dv          to mnv_dv_hohmann_velocity(stPe, tgtPe, tgtAp, ship:body)[1].
        set burnTime    to mnv_burn_dur(dv).
        set burnETA     to mnvTime - burnTime["Half"].
        set burnDur     to burnTime["Full"].
        set mecoTS      to burnETA + burnDur.
        set tgtVelocity to velocityAt(ship, mnvTime):orbit:mag + dv.
        lock  dvToGo    to abs(tgtVelocity - ship:velocity:orbit:mag).

        disp_msg("dv needed: " + round(dv, 2)).
        disp_info("Burn duration: " + round(burnDur, 1)).

        set runmode to util_set_runmode(110).
    }

    // Wait until the burn
    else if runmode = 110
    {
        util_warp_trigger(burnETA).
        if time:seconds >= burnETA
        {
            set runmode to util_set_runmode(120).
        }
        else
        {
            set sVal to heading(l_az_calc(azCalcObj), 0, 0).
            disp_mnv_burn(burnETA, dvToGo, burnDur).
        }
    }

    // execute the burn
    else if runmode = 120
    {
        disp_msg("Executing burn").
        if dvToGo > 10 
        {
            set sVal to heading(l_az_calc(azCalcObj), 0, 0).
            set tVal to 1.
            disp_mnv_burn(burnETA, dvToGo, mecoTS - time:seconds).
        }
        else if dvToGo > 0.1
        {
            set sVal to heading(l_az_calc(azCalcObj), 0, 0).
            set tVal to dvToGo / 10.
            disp_mnv_burn(burnETA, dvToGo, mecoTS - time:seconds).
        }
        else 
        {
            set tVal to 0.
            set runmode to util_set_runmode(-1).
            disp_msg("Maneuver complete!").
        }
    }

    wait 0.01.
}

unlock steering.
unlock throttle.
//-- End Main --//