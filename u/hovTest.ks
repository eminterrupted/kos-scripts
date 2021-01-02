@lazyGlobal off.

parameter holdAlt is 500.

runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/lib_core").
runOncePath("0:/lib/lib_display").
runOncePath("0:/lib/lib_pid").
runOncePath("0:/lib/part/lib_chute").
runOncePath("0:/lib/nav/lib_calc_mnv").

lock steering to up + r(0, 0, 180).

local tPid      to setup_alt_pid(holdAlt).
local tPidVal   to 0.
local vPid      to setup_vspeed_pid(25).
local vPidVal   to 0.
local tVal      to 0.

lock throttle to tVal.


// Writing the deltaV and mass calculations to cache



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
    set tPidVal     to tPid:update(time:seconds, alt:radar).
    set tVal        to max(0, min((tPidVal), 1)).

    log (time:seconds - startTime) + "," + alt:radar + "," + tPidVal + "," + throttle   to "0:/logs/Lander_Test/tpid_output.csv".

    pid_display().
    wait 0.001.
}

out_msg("Slow climbing to altitude: " + holdAlt).
until alt:radar >= holdAlt - 10 {
    set tPidVal         to tPid:update(time:seconds, alt:radar).
    set tVal            to max(0, min((tPidVal), 1)).

    log (time:seconds - startTime) + "," + alt:radar + "," + tPidVal + "," + throttle to "0:/logs/Lander_Test/tpid_output.csv".

    pid_display().
    wait 0.001.
}

// Reach hover state
out_msg("Hover loop").
until check_value(verticalSpeed, 0, 0.1) and check_value(alt:radar, holdAlt, 1) {

    // Pidloop update
    set tPidVal         to tPid:update(time:seconds, alt:radar).
    set tVal            to max(0, min((tPidVal), 1)).

    // Log out
    log (time:seconds - startTime) + "," + alt:radar + "," + tPidVal + "," + throttle to "0:/logs/Lander_Test/tpid_output.csv".
    
    pid_display().
    wait 0.001.
}

// Hover
local tStamp to time:seconds + 5.
until time:seconds >= tStamp {
    out_msg("Hovering in place for " + round(tStamp - time:seconds) + "s  ").
    // Pidloop update
    set tPidVal         to tPid:update(time:seconds, alt:radar).
    set tVal            to max(0, min((tPidVal), 1)).

    // Log out
    log (time:seconds - startTime) + "," + alt:radar + "," + tPidVal + "," + throttle to "0:/logs/Lander_Test/tpid_output.csv".

    pid_display().
    wait 0.001.
}

// Reset the pid
out_msg("Resetting pid").
//tPid:reset().
set tPid:setpoint to 0.

// Trigger to lower landing gear when close to landing
when alt:radar <= 50 and verticalSpeed < 0 then {
    gear on.
}

set tPid to setup_vspeed_pid(-2.5).
set tVal to 0.

// Descent
out_msg("Free fall").
until get_burn_dur(verticalSpeed) >= utils:timeToGround() - 3 {
    set tPidVal to tPid:update(time:seconds, verticalSpeed).
    
    log (time:seconds - startTime) + "," + verticalSpeed + "," + tPidVal + "," + throttle to "0:/logs/Lander_Test/tpid_descent_output.csv".

    pid_display().
    wait 0.001.
}

// Set pid to vertical speed mode


// Hoverslam
out_msg("Powered descent").
until status = "landed" {

    set tPidVal to tPid:update(time:seconds, verticalSpeed).
    set tVal to max(0, min((tPidVal), 1)).

    log (time:seconds - startTime) + "," + verticalSpeed + "," + tPidVal + "," + throttle to "0:/logs/Lander_Test/tpid_descent_output.csv".

    pid_display().
    wait 0.001.
}

// Touchdown
out_msg("Touchdown").
lock throttle to 0.


// Test display controller
local function pid_display {
    update_display().
    disp_block(list(
        "telemetry", 
        "Telemetry", 
        "throttle",     round(throttle, 2), 
        "altitude",     round(ship:altitude), 
        "radar alt",    round(alt:radar), 
        "vertSpeed",    round(verticalSpeed, 2),
        "timetoground", round(utils:timetoground())
        )
    ).
    disp_block(list(
        "pid",
        "pid values",
        "p", round(tPid:pterm, 5),
        "i", round(tPid:iterm, 5),
        "d", round(tPid:dterm, 5),
        "output", round(tPid:output, 2)
        )
    ).
}