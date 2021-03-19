@lazyGlobal off.

// Dependencies
runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_vessel").
runOncePath("0:/lib/lib_util").

// Functions

// Approaching
global function rdv_approach_target
{
    parameter rdvTgt is target,
              speed is 1.

    lock relativeVelocity to rdvTgt:velocity:orbit - ship:velocity:orbit.
    lock steering to lookDirUp(rdvTgt:position, sun:position).
    wait until ves_settled().

    lock maxAccel to ship:maxThrust / ship:mass.
    lock throttle to min(1, abs(speed - relativeVelocity:mag) / maxAccel).

    until relativeVelocity:mag > speed - 0.1
    {
        disp_info("Distance to target: " + round(rdvTgt:distance)).
        disp_info2("Relative velocity: " + round(relativeVelocity:mag, 1)).
        wait 0.01.
    }
    lock throttle to 0.
    lock steering to relativeVelocity.
}

// Wait until nearest approach
global function rdv_await_nearest_approach
{
    parameter rdvTgt is target,
              minDistance is 250.

    local lastDistance to 999999.
    until false 
    {
        set lastDistance to rdvTgt:distance.
        wait 0.1.
        if rdvTgt:distance >= lastDistance or rdvTgt:distance <= minDistance 
        {
            break.
        }

        disp_info("Distance to target: " + round(rdvTgt:distance)).
        disp_info2("Relative velocity: " + round(relativeVelocity:mag, 1)).
    }
}

// Cancel out relative velocity
global function rdv_cancel_velocity 
{
    parameter rdvTgt is target.

    lock relativeVelocity to rdvTgt:velocity:orbit - ship:velocity:orbit.
    lock steering to lookDirUp(relativeVelocity, sun:position).
    wait until ves_settled().
    
    lock maxAccel to ship:maxThrust / ship:mass.
    lock throttle to max(0.05, min(1, relativeVelocity:mag / maxAccel)).
    until relativeVelocity:mag < 0.1
    {
        disp_info("Distance to target: " + round(rdvTgt:distance)).
        disp_info2("Relative velocity: " + round(relativeVelocity:mag, 1)).
        wait 0.01. 
    }
    lock throttle to 0.
}
