@lazyGlobal off.

parameter _tgtLong,
          _tgtLat.

runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/lib_core").
runOncePath("0:/lib/display/lib_display").
runOncePath("0:/lib/lib_pid").
runOncePath("0:/lib/lib_util").
runOncePath("0:/lib/nav/lib_calc_mnv").
runOncePath("0:/lib/part/lib_antenna").

//-- Variables --//

    // Throttle / Control
    local burnDur   to 0.
    local tVal      to 0.
    lock  throttle  to tVal.

    // Local gravity
    local localGravAccel to body:mu / ship:body:radius^2. 

    // Pid
    local altPid    to setup_alt_pid(0).
    local altPidVal to 0.
    local vsPid     to setup_vspeed_pid(-50).
    local vsPidVal  to 0.

//-- Triggers --//

    // Trigger to lower landing gear when close to landing
    when alt:radar <= 1500 and verticalSpeed < 0 then {
        logStr("Lowering landing legs").
        gear off. gear on.
        lights off. lights on.
    }

logStr("localGravAccel: " + localGravAccel).

rcs off. rcs on.
local sVal to ship:retrograde.
lock steering to sVal.

local tStamp to time:seconds + 10.
until time:seconds >= tStamp {
    update_display().
    disp_timer(tStamp, "Retro Alignment").
}
disp_clear_block("timer").

until ship:velocity:surface:mag < 250 {
    set tVal to 0.5.

    out_msg("ship:velocity:surface:mag < 250").

    update_landing_disp().
    wait 0.001.
}

set tVal to 0.

if stage:number > 0 {
    until stage:number <= 0 {
        safe_stage().
    }
}

wait 5.

lock steering to steer_up().

until ship:velocity:surface:mag < 55 {
    //set altPidVal   to altPid:update(time:seconds, alt:radar).
    set vsPidVal    to vsPid:update(time:seconds, verticalSpeed).
    set tVal to vsPidVal.
    //set tVal        to max(vsPidVal, altPidVal).

    out_msg("surface velocity < 55 loop").

    update_landing_disp().
    wait 0.001.
}
out_msg().
set tVal to 0.

until alt:radar <= 1000 {
    //set altPidVal   to altPid:update(time:seconds, alt:radar).
    set vsPidVal    to vsPid:update(time:seconds, verticalSpeed).
    set tVal to vsPidVal.
    //set tVal        to max(vsPidVal, altPidVal).


    update_landing_disp().
    out_msg("alt:radar <= 1000").
}
out_msg().

local tti to 999999.
until burnDur > tti {
    set tti to time_to_impact(100).
    set burnDur to get_burn_dur(verticalSpeed).

    out_msg("tti loop").

    logStr("Time to impact (100m buffer): " + tti + "s").
    update_landing_disp().
    wait 0.001.
}

// Set vspid controls to new setpoints
set vsPid:setpoint to -10.

// Hoverslam
logStr("Ignition").

logStr("Entering powered descent at radar alt: " + round(alt:radar)).
out_msg("Entering powered descent phase at alt: " + round(alt:radar)).
until alt:radar <= 50 {
    set altPidVal   to altPid:update(time:seconds, alt:radar).
    set vsPidVal    to vsPid:update(time:seconds, verticalSpeed).
    set tVal        to max(vsPidVal, altPidVal).

    set tti to time_to_impact(100).
    //logStr("Time to impact (0m buffer): " + round(tti, 3) + "s").

    out_msg("powered descent").

    update_landing_disp().
    wait 0.001.
}

logStr("Slowing rate of descent").
out_msg("Slowing rate of descent").
set vsPid:setpoint to -2.5.
vsPid:reset().
until ship:status = "landed" {
    set altPidVal     to altPid:update(time:seconds, alt:radar).
    set vsPidVal    to vsPid:update(time:seconds, verticalSpeed).
    set tVal        to max(vsPidVal, altPidVal).

    set tti to time_to_impact(100).
    //logStr("Time to impact (0m buffer): " + round(tti, 3) + "s").

    out_msg("final descent").

    update_landing_disp().
    wait 0.001.
}

// Touchdown
logStr("Touchdown").
out_msg("Touchdown").
lock throttle to 0.
unlock steering.
sas on.
rcs off.
panels on.
for p in ship:partsTaggedPattern("comm") {
    activate_antenna(p).
}
for e in ship:partsTaggedPattern("eng") {
    e:shutdown.
}
uplink_telemetry().


//-- Local functions --//

    // From CheersKevin tutorial #16
    local function steer_up {
        if ship:verticalSpeed < 0 {
            return ship:srfRetrograde.
        } else {
            return lookDirUp(up:vector, sun:position).
        }
    }

    local function update_landing_disp {
        update_display().
        disp_block(list(
            "telemetry", 
            "Telemetry", 
            "throttle",     round(throttle, 2), 
            "altitude",     round(ship:altitude), 
            "radar alt",    round(alt:radar), 
            "vertSpeed",    round(verticalSpeed, 2),
            "groundSpeed",  round(ship:groundspeed, 2),
            "srfVelocity",  round(ship:velocity:surface:mag, 2),
            "timetoground", round(utils:timetoground(), 1),
            "burnDur",      round(burnDur, 1)
            )
        ).
    }