@lazyGlobal off.

parameter holdAlt is 150.

runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/lib_core").
runOncePath("0:/lib/lib_display").
runOncePath("0:/lib/lib_pid").
runOncePath("0:/lib/part/lib_chute").

lock steering to up + r(0, 0, 180).

local altPid to setup_alt_pid(holdAlt).
local altPidVal to 0.
local pidTgt to holdAlt.
local tPid to setup_vSpeed_pid(25).
local tPidVal is 0.
local tVal is 0.

lock throttle to tVal.

// Set up a trigger to arm chute when fuel is low
out_msg("Arming chutes").
when ship:liquidfuel <= 0.1 then {
    arm_chutes().
}

// triggers to raise the landing legs
when alt:radar >= 10 and verticalSpeed > 0 then {
    gear off.
}

// Activate the engine and mark the time
stage.
local startTime to time:seconds.

// Get to altitude
out_msg("Rapid climbing to altitude: " + holdAlt).
until alt:radar >= holdAlt - 50 {
    set altPidVal   to altPid:update(time:seconds, alt:radar).
    set tPidVal     to tPid:update(time:seconds, verticalSpeed).
    set tVal        to max(0, min((tPidVal), 1)).

    log (time:seconds - startTime) + "," + ship:verticalspeed   + "," + tPidVal     to "0:/logs/Lander_Test/tpid_output.csv".
    log (time:seconds - startTime) + "," + alt:radar            + "," + altPidVal   to "0:/logs/Lander_Test/altpid_output.csv".

    pid_display().
    wait 0.001.
}

out_msg("Slow climbing to altitude: " + holdAlt).
until alt:radar >= holdAlt - 10 {
    set tPid:setpoint   to 2.5.
    set altPidVal       to altPid:update(time:seconds, alt:radar).
    set tPidVal         to tPid:update(time:seconds, verticalSpeed).
    set tVal            to max(0, min((tPidVal), 1)).

    log (time:seconds - startTime) + "," + ship:verticalspeed   + "," + tPidVal     to "0:/logs/Lander_Test/tpid_output.csv".
    log (time:seconds - startTime) + "," + alt:radar            + "," + altPidVal   to "0:/logs/Lander_Test/altpid_output.csv".

    pid_display().
    wait 0.001.
}

out_msg("Setting throttle to AltPid mode").
altPid:reset().

// Reach hover state
out_msg("Hover loop").
until check_value(verticalSpeed, 0, 0.1) and check_value(alt:radar, holdAlt, 1) {

    // Pidloop update
    set altPidVal       to altPid:update(time:seconds, alt:radar).
    set tPidVal         to tPid:update(time:seconds, verticalSpeed).
    set tVal            to max(0, min((altPidVal), 1)).

    // Log out
    log (time:seconds - startTime) + "," + ship:verticalspeed   + "," + tPidVal     to "0:/logs/Lander_Test/tpid_output.csv".
    log (time:seconds - startTime) + "," + alt:radar            + "," + altPidVal   to "0:/logs/Lander_Test/altpid_output.csv".
    
    pid_display().
    wait 0.001.
}

// Hover
out_msg("Waiting 5s").
local tStamp to time:seconds + 5.
until time:seconds >= tStamp {

    // Pidloop update
    set altPidVal       to altPid:update(time:seconds, alt:radar).
    set tPidVal         to tPid:update(time:seconds, verticalSpeed).
    set tVal            to max(0, min((altPidVal), 1)).

    // Log out
    log (time:seconds - startTime) + "," + ship:verticalspeed   + "," + tPidVal     to "0:/logs/Lander_Test/tpid_output.csv".
    log (time:seconds - startTime) + "," + alt:radar            + "," + altPidVal   to "0:/logs/Lander_Test/altpid_output.csv".

    pid_display().
    wait 0.001.
}

// Reset the pid to new vspeed params
out_msg("Resetting pid to vspeed mode").
tPid:reset().
set tPid:setpoint to -25.

altPid:reset().
set altPid:setpoint to 0.

// Trigger to lower landing gear when close to landing
when alt:radar <= 25 and verticalSpeed < 0 then {
    gear on.
}

// Descent
out_msg("Descending").
until alt:radar <= 60 {
    set altPidVal       to altPid:update(time:seconds, alt:radar).
    set tPidVal         to tPid:update(time:seconds, ship:verticalSpeed).
    set tVal            to max(0, min((tPidVal), 1)).

    log (time:seconds - startTime) + "," + ship:verticalspeed   + "," + tPidVal     to "0:/logs/Lander_Test/tpid_output.csv".
    log (time:seconds - startTime) + "," + alt:radar            + "," + altPidVal   to "0:/logs/Lander_Test/altpid_output.csv".

    pid_display().
    wait 0.001.
}


// Hoverslam
out_msg("Descending").
until alt:radar <= 1.5 {

    set pidTgt to max(-10, - (alt:radar / 10)).
    set tPid:setpoint to pidTgt.

    set tPidVal to tPid:update(time:seconds, ship:verticalSpeed).
    set tVal to max(0, min((tPidVal), 1)).

    log (time:seconds - startTime) + "," + ship:verticalspeed   + "," + tPidVal     to "0:/logs/Lander_Test/tpid_output.csv".
    log (time:seconds - startTime) + "," + alt:radar            + "," + altPidVal   to "0:/logs/Lander_Test/altpid_output.csv".

    pid_display().
    wait 0.001.
}

// Touchdown
out_msg("Touchdown").
lock throttle to 0.


local function pid_display {
    update_display().
    disp_block(list(
        "telemetry", 
        "Telemetry", 
        "throttle",     round(throttle, 2), 
        "altitude",     round(ship:altitude), 
        "radar alt",    round(alt:radar), 
        "vertSpeed",    round(verticalSpeed, 2),
        "tPidVal",      round(tPidVal, 4) 
        )
    ).
}