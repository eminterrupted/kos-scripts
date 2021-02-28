@lazyGlobal off.
clearScreen.

runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_launch").
runOncePath("0:/lib/lib_sci").
runOncePath("0:/lib/lib_util").

parameter tgtAlt is 100000.

local endPitch  to 1.
local maxAcc    to 25.
local maxQ      to 0.10.
local stAlt     to 0.
local sun       to body("sun").
local turnAlt   to 57500.

// lock control values
local sVal      to heading(90, 90, -90).
local tVal      to 0.

// throttle pid controllers
local accPid    to pidLoop().
local qPid      to pidLoop().

// Setup countdown
local cdStamp   to time:seconds + 10.
lock  countdown to time:seconds - cdStamp.

// Set up the terminal
disp_terminal().
disp_main().

// Triggers for countdown, staging and fairing jettison
when countdown >= -4 then
{
    launch_pad_gen(false).
}

// Set throttle
when countdown >= -2 then
{
    set tVal to 1.
}

// Start engine
when countdown >= -1 then
{
    stage.
}

when ship:availablethrust <= 0.1 and tVal > 0 and missionTime > 1 then
{
    if stage:number >= 1
    {
        disp_info("Staging").
        util_stage().
        disp_info().
        accPid:reset.
        preserve.
    }
}

when ship:altitude > 72500 then
{
    disp_info("Fairing jettison").
    util_jettison_fairings().
}

//-- Main --//
lock steering to sVal.
lock throttle to tVal.

// Countdown
until countdown >= 0
{
    disp_msg("COUNTDOWN T" + round(countdown, 1)).
    wait 0.1.
}
stage.  // Release launch clamps at T-0.
unlock countdown.

disp_msg("Vertical ascent").
until ship:altitude >= 250
{
    disp_telemetry().
    wait 0.01.
}

// Roll program at 250m - rotates from 90 degrees to 0.
set sVal to heading(90, 90, 0).

disp_info("Roll program").
until ship:altitude >= 1000 or ship:verticalspeed >= 100
{
    if util_roll_settled() disp_info().
    disp_telemetry().
    wait 0.01.
}

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
    if ship:q >= maxQ {
        set tVal to max(0.66, min(1, 1 + qPid:update(time:seconds, ship:q))).
    }
    else if curAcc >= maxAcc
    {
        set tVal to max(0.66, min(1, 1 + accPid:update(time:seconds, curAcc))).
    }
    else
    {
        set tVal to 1.
    }

    set sVal to heading(90, launch_ang_for_alt(turnAlt, stAlt, endPitch), 0).
    disp_telemetry().
    wait 0.01.
}

disp_msg("Post-turn burning to apoapsis").
until ship:apoapsis >= tgtAlt * 0.975
{
    set sVal to lookDirUp(ship:prograde:vector, sun:position).
    set tVal to max(0.16, min(1, 1 + accPid:update(time:seconds, curAcc))).
    disp_telemetry().
    wait 0.01.
}
disp_msg().

disp_msg("Slow burn to apoapsis").
until ship:apoapsis >= tgtAlt
{
    set sVal to lookDirUp(ship:prograde:vector, sun:position).
    set tVal to max(0.16, min(0.33, 1 - (ship:apoapsis / tgtAlt))).
    disp_telemetry().
    wait 0.01.
}
set tVal to 0.

disp_info("SECO").
wait 1.
disp_info().

disp_msg("Coasting to space").
until ship:altitude >= body:atm:height + 5000
{
    set sVal to lookDirUp(ship:prograde:vector, sun:position).
    // Correction burn if needed
    if ship:apoapsis <= tgtAlt * 0.995
    {
        disp_info("Correction burn").
        until ship:apoapsis >= tgtAlt * 1.005
        {
            set tVal to max(0.16, min(0.33, 1 - (ship:apoapsis / tgtAlt))).
        }
        disp_info().
    }
    set tVal to 0.
    disp_telemetry().
    wait 0.01.
}
disp_info().

set sVal to lookDirUp(ship:prograde:vector, sun:position).
disp_msg("Preparing ship for orbit").
wait 5.
disp_msg().

//-- End Main --//