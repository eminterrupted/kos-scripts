@lazyGlobal off.

parameter _tgt.

runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/lib_core").
runOncePath("0:/lib/nav/lib_nav").
runOncePath("0:/lib/nav/lib_deltav").

runOncePath("0:/lib/nav/lib_mnv").
runOncePath("0:/lib/nav/lib_calc_mnv").
runOncePath("0:/lib/nav/lib_node").
runOncePath("0:/lib/nav/lib_rendezvous").

set target to orbitable(_tgt).

out_msg("Checking current orbit").

if not check_value(ship:apoapsis, target:apoapsis, 1000) or not check_value(ship:periapsis, target:periapsis, 1000) {
    out_msg("Aligning orbits").
    runPath("0:/a/orbit_change", target:apoapsis, target:periapsis, 0.001).
}

out_msg("Orbit aligned, waiting until Pe").
lock steering to lookDirUp(ship:prograde:vector, sun:position). 

until eta:periapsis < 300 {
    update_display().
    disp_timer(time:seconds + eta:periapsis, "ETA PE").
    wait 1.
}

disp_clear_block("timer").

if warp > 0 set warp to 0.
wait until kuniverse:timewarp:issettled.

local tgtAngle      is target_angle(_tgt).
local desiredPeriod is target:orbit:period * ( 1 + (( 360 - tgtAngle) / 360)).

out_msg("Changing orbital period for intercept").

change_period(desiredPeriod).

exec_circ_burn(time:seconds + eta:periapsis, ship:periapsis).

out_msg("On approach").

until target:distance < 500 {
    await_closest_approach().
    cancel_relative_velocity().
    approach().
}

cancel_relative_velocity().





// Loop until distance from target starts increasing
global function await_closest_approach {
    
    until false {
        local lastDistance to target:distance.
        wait 1.
        if target:distance > lastDistance {
            break.
        } else {
            out_msg("Awaiting closest approach").
            update_display().
        }
    }
}


// Throttle against our relative velocity vector until we're increasing it
global function cancel_relative_velocity {
    lock steering to lookDirUp(target:velocity:orbit - ship:velocity:orbit, sun:position).
    wait until shipSettled().

    lock throttle to 0.1.
    until false {
        local lastDiff to (target:velocity:orbit - ship:velocity:orbit):mag.
        wait 0.1.
        if (target:velocity:orbit - ship:velocity:orbit):mag > lastDiff {
            lock throttle to 0. 
            out_msg().
            break.
        } else {
            update_display().
            out_msg("Cancelling relative velocity").
        }
    }
}


// Throttle towards target to approach 
global function approach {
    lock steering to lookdirup(target:position, sun:position). 
    wait until shipSettled().

    out_msg("Approaching target").
    lock throttle to 0.1.



    lock throttle to 0.
    out_msg().
}


// Throttle prograde or retrograde to change our orbital period
global function change_period {
    parameter newPeriod.

    local currentPeriod to ship:obt:period.
    local boost         to newPeriod > currentPeriod.

    if boost {
        lock steering to lookDirUp(ship:prograde:vector, sun:position).
    } else {
        lock steering to lookDirUp(ship:retrograde:vector, sun:position).
    }

    wait until shipSettled().
    lock throttle to 0.5.

    if boost {
        until ship:obt:period > newPeriod {
            update_display().
        }
    } else {
        until ship:obt:period < newPeriod {
            update_display().
        }
    }

    lock throttle to 0.
}   
