@lazyGlobal off.

parameter holdAlt is 500.

runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/lib_core").
runOncePath("0:/lib/lib_display").
runOncePath("0:/lib/lib_pid").
runOncePath("0:/lib/part/lib_chute").
runOncePath("0:/lib/nav/lib_calc_mnv").


local burnDur   to 0.

local tPid      to setup_alt_pid(holdAlt).
local tPidVal   to 0.
local vsPid     to setup_vspeed_pid(50).
local vsPidVal  to 0.

local tVal      to 0.
lock  throttle  to tVal.

lock  steering  to up + r(0, 0, 180).

// Initialize the pid log files
local ascLog    to "0:/logs/Lander_Test/ascent_pid_output.csv".
local hovLog    to "0:/logs/Lander_Test/hover_pid_output.csv".
local desLog    to "0:/logs/Lander_Test/descent_pid_output.csv".
if exists(ascLog) deletePath(ascLog). 
if exists(hovLog) deletePath(hovLog). 
if exists(desLog) deletePath(desLog). 
log "time,throttle,alt,tpid_output,verticalSpeed,vspid_output" to ascLog.
log "time,throttle,alt,tpid_output,verticalSpeed,vspid_output" to hovLog.
log "time,throttle,alt,tpid_output,verticalSpeed,vspid_output" to desLog.


// Set up a trigger to arm chute when fuel is low
out_msg("Arming chutes").
when ship:liquidfuel <= 0.1 then {
    arm_chutes().
}

// triggers to raise the landing legs
when alt:radar >= 10 and verticalSpeed > 0 then {
    logStr("Raising landing legs").
    gear off.
}

// Activate the engine and mark the time
logStr("Ignition").
stage.
local startTime to time:seconds.

// Get to altitude
logStr("Rapid climbing to altitude: " + holdAlt).
out_msg("Rapid climbing to altitude: " + holdAlt).
until alt:radar >= holdAlt * 0.90 {
    set tPidVal     to tPid:update(time:seconds, alt:radar).
    set vsPidVal    to vsPid:update(time:seconds, verticalSpeed).
    set tVal        to min(tPidVal, vsPidVal).

    log (time:seconds - startTime) + "," + throttle + "," + alt:radar + "," + tPidVal + "," + verticalSpeed + "," + vsPidVal to ascLog.

    pid_display().
    wait 0.001.
}

logStr("Slow climbing to altitude: " + holdAlt).
out_msg("Slow climbing to altitude: " + holdAlt).
set vsPid:setpoint to min(10, (holdAlt * 0.9) / 10).
vsPid:reset().
until alt:radar >= holdAlt - 10 {
    set tPidVal         to tPid:update(time:seconds, alt:radar).
    set vsPidVal    to vsPid:update(time:seconds, verticalSpeed).
    set tVal        to min(tPidVal, vsPidVal).

    log (time:seconds - startTime) + "," + throttle + "," + alt:radar + "," + tPidVal + "," + verticalSpeed + "," + vsPidVal to ascLog.

    pid_display().
    wait 0.001.
}

// Reach hover state
logStr("Hover loop").
out_msg("Hover loop").
until check_value(verticalSpeed, 0, 0.1) and check_value(alt:radar, holdAlt, 1) {

    // Pidloop update
    set tPidVal     to tPid:update(time:seconds, alt:radar).
    set vsPidVal    to vsPid:update(time:seconds, verticalSpeed).        
    set tVal        to min(tPidVal, vsPidVal).

    // Log out
    log (time:seconds - startTime) + "," + throttle + "," + alt:radar + "," + tPidVal + "," + verticalSpeed + "," + vsPidVal to ascLog.

    pid_display().
    wait 0.001.
}

// Hover
local tStamp to time:seconds + 5.
set vsPid:setpoint to 0.
vsPid:reset().

logStr("Hovering").
until time:seconds >= tStamp {
    out_msg("Hovering in place for " + round(tStamp - time:seconds) + "s  ").
    // Pidloop update
    set tPidVal     to tPid:update(time:seconds, alt:radar).
    set vsPidVal    to vsPid:update(time:seconds, verticalSpeed).
    set tVal        to max(0, min((tPidVal), 1)).

    // Log out
    log (time:seconds - startTime) + "," + throttle + "," + alt:radar + "," + tPidVal + "," + verticalSpeed + "," + vsPidVal  to hovLog.

    pid_display().
    wait 0.001.
}

// Reset the pid
logStr("Resetting pid").
out_msg("Resetting pid").
tPid:reset().
set tPid:setpoint to 0.

// Trigger to lower landing gear when close to landing
when alt:radar <= 50 and verticalSpeed < 0 then {
    logStr("Lowering landing legs").
    gear on.
}

set vsPid:setpoint to -25.
vsPid:reset().
set tVal to 0.

local localGravAccel to constant():g * ship:body:mass / ship:body:radius^2. 

logStr("localGravAccel calculated: " + localGravAccel).

// Descent
logStr("Free fall").
out_msg("Free fall").
until burnDur > utils:timeToGround() {
    logStr("Time to ground impact: " + utils:timeToGround()).
    set burnDur to get_burn_dur(verticalSpeed).

    pid_display().
    wait 0.001.
}

// Hoverslam
logStr("Powered descent").
out_msg("Powered descent").
until alt:radar <= 50 {
    set tPidVal     to tPid:update(time:seconds, alt:radar).
    set vsPidVal    to vsPid:update(time:seconds, verticalSpeed).
    set tVal        to max(vsPidVal, tPidVal).

    log (time:seconds - startTime) + "," + throttle + "," + alt:radar + "," + tPidVal + "," + verticalSpeed + "," + vsPidVal  to desLog.

    pid_display().
    wait 0.001.
}

logStr("Slowing rate of descent").
out_msg("Slowing rate of descent").
set vsPid:setpoint to -5.
vsPid:reset().
until alt:radar <= 25 {
    set tPidVal     to tPid:update(time:seconds, alt:radar).
    set vsPidVal    to vsPid:update(time:seconds, verticalSpeed).
    set tVal        to max(vsPidVal, tPidVal).

    log (time:seconds - startTime) + "," + throttle + "," + alt:radar + "," + tPidVal + "," + verticalSpeed + "," + vsPidVal  to desLog.

    pid_display().
    wait 0.001.
}

set vsPid:setpoint to -1.
vsPid:reset().
until status = "landed" {
    set tPidVal     to tPid:update(time:seconds, alt:radar).
    set vsPidVal    to vsPid:update(time:seconds, verticalSpeed).
    set tVal        to max(vsPidVal, tPidVal).

    log (time:seconds - startTime) + "," + throttle + "," + alt:radar + "," + tPidVal + "," + verticalSpeed + "," + vsPidVal to desLog.

    pid_display().
    wait 0.001.
}

// Touchdown
logStr("Touchdown").
out_msg("Touchdown").
lock throttle to 0.
unlock steering.
sas on.


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
        "timetoground", round(utils:timetoground(), 1),
        "burnDur",      round(burnDur, 1)
        )
    ).
    disp_block(list(
        "tpid",
        "tpid values",
        "p", round(tPid:pterm, 5),
        "i", round(tPid:iterm, 5),
        "d", round(tPid:dterm, 5),
        "output", round(tPid:output, 2)
        )
    ).
    disp_block(list(
        "vspid",
        "vspid values",
        "p", round(vsPid:pterm, 5),
        "i", round(vsPid:iterm, 5),
        "d", round(vsPid:dterm, 5),
        "output", round(vsPid:output, 2)
        )
    ).
}