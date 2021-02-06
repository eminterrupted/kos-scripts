@lazyGlobal off.

parameter wp. // either a waypoint object, or the waypoint name as a string

if wp:isType("string") {
    set wp to waypoint(wp).
}

runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/lib_core").
runOncePath("0:/lib/display/lib_display").
runOncePath("0:/lib/lib_pid").
runOncePath("0:/lib/lib_util").
runOncePath("0:/lib/lib_land").
runOncePath("0:/lib/nav/lib_calc_mnv").
runOncePath("0:/lib/part/lib_antenna").
runOncePath("0:/lib/part/lib_solar").

//-- Variables --//

    // Throttle / Control
    local burnDur   to 0.
    local tVal      to 0.
    lock  throttle  to tVal.

    // Local gravity
    local localGravAccel to body:mu / ship:body:radius^2. 

    // Waypoint / Landing variables
    local targetDistOld is 0.
    local wpGeo to wp:geoPosition.
    

    // Pids
    local climbPid    to pidLoop(0.4, 0.3, 0.005, 0, 1). // Controls vertical speed
    local hoverPid    to pidLoop(1, 0.01, 0.0, -15, 15). // Controls altitude by changing setpoint of climbPid
    set hoverPid:setpoint to addons:scansat:elevation(wp:body, wpGeo) + 25.

    local eastVelPid  to pidLoop(3, 0.01, 0.0, -35, 35). // Controls horizontal speed by pitching
    local northVelPid to pidLoop(3, 0.01, 0.0, -35, 35). // ^
    local eastPosPid  to pidLoop(1700, 0, 100, -30, 30). // Controls horizontal position be changing velPid setpoints
    local northPosPid to pidLoop(1700, 0, 100, -30, 30). // ^
    set eastPosPid:setpoint to wpGeo:lng.
    set northPosPid:setpoint to wpGeo:lat.
    

//-- Triggers --//

    // Trigger to lower landing gear when close to landing
    when alt:radar <= 1000 and verticalSpeed < 0 then {
        logStr("Lowering landing legs").
        gear off. gear on.
        lights off. lights on.
    }

    //Staging trigger
    when ship:availableThrust < 0.1 and throttle > 0 then {
        safe_stage().
        preserve.
    }

logStr("localGravAccel: " + localGravAccel).

rcs off. rcs on.
lock steering to ship:srfretrograde.
update_display().

wait 3.

// Burn until we are impacting the body
set tVal to 1. 
until addons:tr:hasImpact {
    out_msg("addons:tr:hasImpact: " + addons:tr:hasImpact).
    update_landing_disp().
    wait 0.01.
}
set tVal to 0.

// Get the angle and distance between current impact and waypoint target
lock targetDist to geo_dist(wpGeo, addons:tr:impactpos).
lock targetDir  to geo_dir(addons:tr:impactpos, wpGeo).

// Orient the vessel towards the target
local steerDir to targetDir - 180. 
local steerPitch to 0.
lock steering to heading(steerDir, steerPitch, 0).
wait until shipSettled().

// Execute the burn
until false {
    
    set steerDir to targetDir - 180.
    set steerPitch to 0.
    if vAng(heading(steeringDir, steeringPitch):vector, ship:facing:vector) < 20 {
        set tVal to targetDist / 5000 + 0.2.
    } else {
        set tVal to 0.2.
    }
    
    if targetDist > targetDistOld and targetDist < 300 {
        set tVal to 0.
        break.
    }

    set targetDistOld to targetDist.
}















lock steering to steer_up().
wait 2.5.

until ship:velocity:surface:mag < srfThreshold / 2 or alt:radar <= 7500 {
    set vsPidVal    to vsPid:update(time:seconds, verticalSpeed).
    set tVal to vsPidVal.
    
    out_msg("surface velocity < srfThreshold / 2 loop").

    update_landing_disp().
    wait 0.001.
}
out_msg().
set tVal to 0.

until alt:radar <= 5000 {
    set vsPidVal    to vsPid:update(time:seconds, verticalSpeed).
    set tVal to vsPidVal.

    update_landing_disp().
    out_msg("alt:radar <= 5000").
}
out_msg().

logStr("Entering TTI loop").
local tti to 999999.
until burnDur >= tti {
    set vsPidVal    to vsPid:update(time:seconds, verticalSpeed).
    set tVal to vsPidVal.
    
    set tti to time_to_impact(125).
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
until alt:radar <= 100 {
    set altPidVal   to altPid:update(time:seconds, alt:radar).
    set vsPidVal    to vsPid:update(time:seconds, verticalSpeed).
    set tVal        to max(vsPidVal, altPidVal).

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
until ship:status = "landed" {
    set altPidVal     to altPid:update(time:seconds, alt:radar).
    set vsPidVal    to vsPid:update(time:seconds, verticalSpeed).
    set tVal        to max(vsPidVal, altPidVal).

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

    local function update_landing_disp {
        update_display().
        disp_landing(wpGeo, burnDur).
    }