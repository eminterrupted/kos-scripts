@lazyGlobal off.

parameter _geo1, _geo2.

runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/lib_core").
runOncePath("0:/lib/display/lib_display").
runOncePath("0:/lib/lib_pid").
runOncePath("0:/lib/lib_util").
runOncePath("0:/lib/nav/lib_calc_mnv").
runOncePath("0:/lib/part/lib_antenna").
runOncePath("0:/lib/part/lib_solar").

//-- Variables --//

    // Altitude targets
    local altBuffer to 100.

    // Throttle / Control
    local burnDur   to 0.
    local tVal      to 0.
    lock  throttle  to tVal.

    // Local gravity
    local localGravAccel to body:mu / ship:body:radius^2. 

    // Pid
    local altPid    to setup_alt_pid(0).
    local altPidVal to 0.
    local hsPidThresh to choose 25 if ship:body:name = "Minmus" else 75.
    local hsPid     to setup_speed_pid(hsPidThresh).
    local hsPidVal to 0.
    local vsPidthresh to choose -50 if ship:body:name = "Minmus" else -100.
    local vsPid     to setup_speed_pid(vsPidthresh).
    local vsPidVal  to 0.

//-- Triggers --//

    // Trigger to lower landing gear when close to landing
    when alt:radar <= 1000 and verticalSpeed < 0 then 
    {
        logStr("Lowering landing legs").
        gear off. gear on.
        lights off. lights on.
    }

    //Staging trigger
    when ship:availableThrust < 0.1 and throttle > 0 then 
    {
        safe_stage().
        preserve.
    }

logStr("localGravAccel: " + localGravAccel).


wait 3.

rcs off. rcs on.
lock steering to ship:srfretrograde.
update_display().
local srfThreshold to choose 25 if ship:body:name = "Minmus" else 100.

until ship:velocity:surface:mag < srfThreshold 
{
    set tVal to 1.

    out_msg("ship:velocity:surface:mag < threshold:" + srfThreshold).

    update_landing_disp().
    wait 0.001.
}

set tVal to 0.

lock steering to steer_up().
wait 2.5.

until ship:altitude <= 15000 or alt:radar <= 10000 
{
    set vsPidVal to vsPid:update(time:seconds, verticalSpeed).
    set hsPidVal to hsPid:update(time:seconds, groundSpeed).
    set tVal to max(vsPidVal, 1 - hsPidVal).
    
    out_msg("15000 / 10000").

    update_landing_disp().
    wait 0.001.
}
out_msg().
set tVal to 0.

set hsPid:setpoint to hsPidThresh / 1.5.
set vsPid:setpoint to vsPidthresh / 1.5.

until ship:altitude <= 7500 or alt:radar <= 5000 
{
    set hsPidVal to hsPid:update(time:seconds, groundSpeed).
    set vsPidVal to vsPid:update(time:seconds, verticalSpeed).
    set tVal to max(vsPidVal, 1 - hsPidVal).

    update_landing_disp().
    out_msg("7500 / 5000").
}
out_msg().

set hsPid:setpoint to hsPidThresh / 3.
set vsPid:setpoint to choose vsPidthresh / 1.75 if ship:body:name = "Minmus" else vsPidThresh / 3.

local tti to 999999.
until burnDur >= tti 
{
    set hsPidVal to hsPid:update(time:seconds, groundSpeed).
    set vsPidVal to vsPid:update(time:seconds, verticalSpeed).
    set tVal to max(vsPidVal, 1 - hsPidVal).
    
    set tti to time_to_impact(altBuffer).
    set burnDur to get_burn_dur(verticalSpeed).

    out_msg("tti loop").

    //logStr("Time to impact (100m buffer): " + tti + "s").
    update_landing_disp().
    wait 0.001.
}

// Set vspid controls to new setpoints
set vsPid:setpoint to -10.

// Hoverslam
logStr("Ignition").

logStr("Entering powered descent at radar alt: " + round(alt:radar)).
out_msg("Entering powered descent phase at alt: " + round(alt:radar)).
until alt:radar <= altBuffer 
{
    set altPidVal to altPid:update(time:seconds, alt:radar).
    set vsPidVal  to vsPid:update(time:seconds, verticalSpeed).
    set tVal      to max(vsPidVal, altPidVal).

    //set tti to time_to_impact(100).
    //logStr("Time to impact (0m buffer): " + round(tti, 3) + "s").

    out_msg("powered descent").

    update_landing_disp().
    wait 0.001.
}

logStr("Slowing rate of descent").
out_msg("Slowing rate of descent").

set vsPid:setpoint to -2.5.
vsPid:reset().
until ship:status = "landed" 
{
    set altPidVal to altPid:update(time:seconds, alt:radar).
    set vsPidVal  to vsPid:update(time:seconds, verticalSpeed).
    set tVal      to max(vsPidVal, altPidVal).

    //set tti to time_to_impact(50).
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

for p in ship:partsTaggedPattern("solar") {
    if not p:tag:contains("onAscent") {
        activate_solar(p).
    }
}

for p in ship:partsTaggedPattern("comm") {
    if not p:tag:contains("onAscent") {
        activate_antenna(p).
    }
}
for e in ship:partsTaggedPattern("eng") {
    e:shutdown.
}
uplink_telemetry().


//-- Local functions --//

    // From CheersKevin tutorial #16
    local function steer_up {
        if ship:verticalSpeed < 0 {
            return lookDirUp(ship:srfRetrograde:vector, sun:position).
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