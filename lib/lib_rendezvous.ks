// How far ahead is _obt0's true anomaly measured from _obt1's in degrees?
global function ta_offset 
{
    parameter _obt0,
              _obt1.

    // _obt0 Pe longitude (relative to solar system)
    local pe_lng_0 is _obt0:argumentOfPeriapsis + _obt0:lan.

    // _obt1 Pe longitude (relative to solar system)
    local pe_lng_1 is _obt1:argumentOfPeriapsis + _obt1:lan.

    // how far ahead is obt0's TA measured from obt1's in degrees?
    return pe_lng_0 - pe_lng_1.
}


//Formats a target string as an orbitable object
global function orbitable 
{
    parameter _tgt.

    local vList to list().
    list targets in vList.

    for vs in vList 
    {
        if vs:name = _tgt 
        {
            return vessel(_tgt).
        }
    }
    
    return body(_tgt).
}


// How many degrees difference between ship and a target
global function target_angle 
{
    parameter _tgt.

    return mod(
        lng_to_degrees(orbitable(_tgt):longitude)
        - lng_to_degrees(ship:longitude) + 360,
        360
    ).
}

// Below from CheersKevin Ep 25 (https://www.youtube.com/watch?v=YdwEILVc5Ec&list=PLb6UbFXBdbCrvdXVgY_3jp5swtvW24fYv&index=26)
// Steers towards the vector


// Approaching
global function rdv_approach
{
    parameter rdvTgt is target,
              speed is 1.

    lock relativeVelocity to rdvTgt:velocity:orbit - ship:velocity:orbit.
    lock steering to lookDirUp(rdvTgt:position, sun:position).
    wait until shipFacing().

    lock maxAccel to ship:maxThrust / ship:mass.
    lock throttle to min(1, abs(speed - relativeVelocity:mag) / maxAccel).

    until relativeVelocity:mag > speed - 0.1
    {
        update_display().
    }
    lock throttle to 0.
    lock steering to relativeVelocity.
}

// Cancel out relative velocity
global function rdv_cancel_vel 
{
    parameter rdvTgt is target.

    lock relativeVelocity to rdvTgt:velocity:orbit - ship:velocity:orbit.
    lock steering to lookDirUp(relativeVelocity, sun:position).
    wait until shipFacing().
    
    lock maxAccel to ship:maxThrust / ship:mass.
    lock throttle to min(1, relativeVelocity:mag / maxAccel).
    until relativeVelocity:mag < 0.025
    {
        update_display().
        disp_rendezvous(rdvTgt).
    }
    lock throttle to 0.
}

// Wait until nearest approach
global function rdv_await_nearest
{
    parameter rdvTgt is target,
              minDistance is 250.

    local lastDistance to 999999.
    until false 
    {
        set lastDistance to rdvTgt:distance.
        update_display().
        disp_rendezvous(rdvTgt).
        wait 0.1.
        if rdvTgt:distance >= lastDistance or rdvTgt:distance <= minDistance 
        {
            break.
        }
    }
}
