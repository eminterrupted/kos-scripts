@lazyGlobal off.

parameter holdAlt is 250.

runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/lib_core").
runOncePath("0:/lib/lib_display").
runOncePath("0:/lib/lib_pid").
runOncePath("0:/lib/part/lib_chute").

lock steering to up.

local pidTgt to holdAlt.
local tPid to setup_vSpeed_pid(5).
local tVal is 0.
local tPidVal is 0.

lock throttle to tVal.

// Set up a trigger to arm chute when fuel is low
out_msg("Arming chutes").
when ship:liquidfuel <= 0.1 then {
    arm_chutes().
}

// Activate the engine and mark the time
stage.
local startTime to time:seconds.

// Get to altitude
out_msg("Climbing to altitude: " + holdAlt).
until ship:altitude >= holdAlt -25 {
    set tPidVal to tPid:update(time:seconds, verticalSpeed).
    set tVal to max(0, min((tPidVal), 1)).

    update_display().
    disp_block(list(
        "telemetry", 
        "Telemetry", 
        "throttle",     round(throttle, 1), 
        "altitude",     round(ship:altitude), 
        "radar alt",    round(alt:radar), 
        "vertSpeed",    round(verticalSpeed, 2),
        "tPidVal",      round(tPidVal, 4) 
        )
    ).
}

tPid:reset().

// Reach hover state
out_msg("Hover loop").
until check_value(verticalSpeed, 0, 0.1) and check_value(ship:altitude, holdAlt, 1) {

    // Pidloop update
    set tPidVal to tPid:update(time:seconds, ship:altitude).
    set tVal to max(0, min((tPidVal), 1)).

    // Log out
    log (time:seconds - startTime) + "," + ship:altitude + "," + tPidVal to "0:/logs/Lander_Test/pid_output.csv".
    
    wait 0.001.

    update_display().
}

// Hover
out_msg("Waiting 5s").
local tStamp to time:seconds + 5.
until time:seconds >= tStamp {
    // Pidloop update
    set tPidVal to tPid:update(time:seconds, ship:altitude).
    set tVal to max(0, min((tPidVal), 1)).

    // Log out
    log (time:seconds - startTime) + "," + ship:altitude + "," + tPidVal to "0:/logs/Lander_Test/alt_pid_output.csv".
    
    wait 0.001.

    update_display().
}

// Reset the pid to new vspeed params
out_msg("Resetting pid").
set pidTgt to -10.
set tPid to setup_vspeed_pid(pidTgt).

// Descent
out_msg("Descending").
until alt:radar <= 1.5 {

    set pidTgt to max(-10, - (alt:radar / 10)).
    set tPid:setpoint to pidTgt.

    set tPidVal to tPid:update(time:seconds, ship:verticalSpeed).
    set tVal to max(0, min((tPidVal), 1)).

    log (time:seconds - startTime) + "," + pidTgt + "," + verticalSpeed + "," + tPidVal to "0:/logs/Lander_Test/vs_pid_output.csv".

    wait 0.001.

    update_display().
}

// Touchdown
out_msg("Touchdown").
lock throttle to 0.