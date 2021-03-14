@lazyGlobal off.
clearScreen.

parameter launchPlan.

// load dependencies
runOncePath("0:/lib/lib_file").
runOncePath("0:/lib/lib_launch").
runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_vessel").
runOncePath("0:/kslib/lib_l_az_calc").

// variables
local azCalcObj to launchPlan:lazObj.
local tgtAlt    to launchPlan:tgtAp.

local endPitch  to 1.
local finalAlt  to 0.
local maxAcc    to 25.
local maxQ      to 0.10.
local stAlt     to 0.
local stTurn    to 1000.
local stSpeed   to 100.
local turnAlt   to max(52500, min(67500, tgtAlt * 0.2)).

// Flags
local hasFairing to choose true if ship:modulesNamed("ProceduralFairingDecoupler"):length > 0 or ship:modulesNamed("ModuleProceduralFairing"):length > 0 else false.

// Control values
local rVal      to choose 180 if ship:crew():length > 0 else 0.
local sVal      to heading(90, 90, -90).
local tVal      to 0.

// throttle pid controllers
local accPid    to pidLoop().
local qPid      to pidLoop().

// Setup countdown
local cdStamp   to time:seconds + 10.
lock  countdown to time:seconds - cdStamp.
ag8 off.

// Set up the display
disp_terminal().
disp_main().

// Staging trigger
when ship:availablethrust <= 0.1 and tVal > 0 and missionTime > 1 then
{
    if stage:number > 2
    {
        disp_info("Staging").
        ves_safe_stage().
        disp_info().
        accPid:reset.
        preserve.
    }
}

// Fairing trigger
if hasFairing 
{
    when ship:altitude > 70500 then
    {
        disp_info("Fairing jettison").
        ves_jettison_fairings().
    }
}

//-- Main --//
lock steering to sVal.
lock throttle to tVal.

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
stage.  // Release launch clamps at T-0.
ag8 on. // Action group cue for liftoff
ag10 off.   // Reset ag10 (is true to initiate launch)
unlock countdown.
disp_info().
disp_info2().
// End countdown


disp_msg("Vertical ascent").
until alt:radar >= 100
{
    disp_telemetry().
    wait 0.01.
}

// Roll program at 250m - rotates from 270 degrees to 0 or 180 based on
// whether a crew member is present. 
set sVal to heading(l_az_calc(azCalcObj), 90, rVal).

disp_info("Roll program").
until ship:altitude >= stTurn or ship:verticalspeed >= stSpeed
{
    if ves_roll_settled() disp_info().
    disp_telemetry().
    wait 0.01.
}
disp_info().
// Store the altitude at which we reached the turn threshold
set stAlt to ship:altitude.

// Set up gravity turn pids
set qPid to pidLoop(5, 0, 0, -1, 1).
set qPid:setpoint to maxQ.
set accPid to pidLoop(0.02, 0, 0, -1, 1).
set accPid:setpoint to maxAcc.
lock curAcc to ship:maxThrust / ship:mass.

disp_msg("Gravity turn").
until ship:altitude >= turnAlt
{
    qPid:update(time:seconds, ship:q).
    accPid:update(time:seconds, curAcc).
    if ship:q >= maxQ or curAcc >= maxAcc {
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

disp_msg("Post-turn burning to apoapsis").
accPid:reset.
until ship:apoapsis >= tgtAlt * 0.975
{
    set sVal to heading(l_az_calc(azCalcObj), launch_ang_for_alt(turnAlt, stAlt, endPitch), rVal).
    set tVal to max(0.33, min(1, 1 + accPid:update(time:seconds, curAcc))).
    disp_telemetry().
    wait 0.01.
}
disp_msg().

set finalAlt to choose tgtAlt * 1 if ship:altitude >= body:atm:height else tgtAlt * 1.00125.

disp_msg("Slow burn to apoapsis").
until ship:apoapsis >= finalAlt
{
    set sVal to heading(l_az_calc(azCalcObj), launch_ang_for_alt(turnAlt, stAlt, endPitch), rVal).
    set tVal to max(0.33, min(1, 1 - (ship:apoapsis / tgtAlt))).
    disp_telemetry().
    wait 0.01.
}
set tVal to 0.

disp_info("SECO").
wait 1.
disp_info().

disp_msg("Coasting to space").
until ship:altitude >= body:atm:height + 2500 or ship:verticalspeed < 0
{
    set sVal to ship:prograde.
    // Correction burn if needed
    if ship:apoapsis <= tgtAlt * 0.995
    {
        disp_info("Correction burn").
        until ship:apoapsis >= tgtAlt * 1.0015
        {
            set tVal to max(0.33, min(1, 1 - (ship:apoapsis / tgtAlt))).
        }
        disp_info().
    }
    set tVal to 0.
    disp_telemetry().
    wait 0.01.
}
disp_info().

disp_msg("Handing off to circ burn").
wait 2.5.
clearScreen.
//-- End Main --//