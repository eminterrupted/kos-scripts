// This file is distributed under the terms of the MIT license, (c) the KSLib team
@LAZYGLOBAL OFF.

// Same as orbital prograde vector for ves
function kslib_nav_obt_tangent {
    parameter ves is ship.

    return ves:velocity:orbit:normalized.
}

// In the direction of orbital angular momentum of ves
// Typically same as Normal
function kslib_nav_obt_binormal {
    parameter ves is ship.

    return vcrs((ves:position - ves:Body:position):normalized, kslib_nav_obt_tangent(ves)):normalized.
}

// Perpendicular to both tangent and binormal
// Typically same as Radial In
function kslib_nav_obt_normal {
    parameter ves is ship.

    return vcrs(kslib_nav_obt_binormal(ves), kslib_nav_obt_tangent(ves)):normalized.
}

// Vector pointing in the direction of longitude of ascending node
function kslib_nav_obt_lan {
    parameter ves is ship.

    return angleAxis(ves:orbit:LAN, ves:Body:AngularVel:normalized) * solarPrimeVector.
}

// Same as surface prograde vector for ves
function kslib_nav_srf_tangent {
    parameter ves is ship.

    return ves:velocity:surface:normalized.
}

// In the direction of surface angular momentum of ves
// Typically same as Normal
function kslib_nav_srf_binormal {
    parameter ves is ship.

    return vcrs((ves:position - ves:Body:position):normalized, kslib_nav_srf_tangent(ves)):normalized.
}

// Perpendicular to  both tangent and binormal
// Typically same as Radial In
function kslib_nav_srf_normal {
    parameter ves is ship.

    return vcrs(kslib_nav_srf_binormal(ves), kslib_nav_srf_tangent(ves)):normalized.
}

// Vector pointing in the direction of longitude of ascending node
function kslib_nav_srf_lan {
    parameter ves is ship.

    return angleAxis(ves:orbit:LAN - 90, ves:Body:AngularVel:normalized) * solarPrimeVector.
}

// Vector directly away from the body at ves' position
function kslib_nav_local_up {
    parameter ves is ship.

    return ves:up:vector.
}

// Angle to ascending node with respect to ves' body's equator
function kslib_nav_ang_to_body_asc_node {
    parameter ves is ship.

    local joinVector is kslib_nav_obt_lan(ves).
    local angle is vang((ves:position - ves:Body:position):normalized, joinVector).
    if ves:status = "LANDED" {
        set angle to angle - 90.
    }
    else {
        local signVector is vcrs(-body:position, joinVector).
        local sign is vdot(kslib_nav_obt_binormal(ves), signVector).
        if sign < 0 {
            set angle to angle * -1.
        }
    }
    return angle.
}

// Angle to descending node with respect to ves' body's equator
function kslib_nav_ang_to_body_desc_node {
    parameter ves is ship.

    local joinVector is -kslib_nav_obt_lan(ves).
    local angle is vang((ves:position - ves:Body:position):normalized, joinVector).
    if ves:status = "LANDED" {
        set angle to angle - 90.
    }
    else {
        local signVector is vcrs(-body:position, joinVector).
        local sign is vdot(kslib_nav_obt_binormal(ves), signVector).
        if sign < 0 {
            set angle to angle * -1.
        }
    }
    return angle.
}

// Vector directed from the relative descending node to the ascending node
function kslib_nav_rel_nodal_vec {
    parameter orbitBinormal.
    parameter targetBinormal.

    return vcrs(orbitBinormal, targetBinormal):normalized.
}

// Angle to relative ascending node determined from args
function kslib_nav_ang_to_rel_asc_node {
    parameter orbitBinormal.
    parameter targetBinormal.

    local joinVector is kslib_nav_rel_nodal_vec(orbitBinormal, targetBinormal).
    local angle is vang(-body:position:normalized, joinVector).
    local signVector is vcrs(-body:position, joinVector).
    local sign is vdot(orbitBinormal, signVector).
    if sign < 0 {
        set angle to angle * -1.
    }
    return angle.
}

// Angle to relative descending node determined from args
function kslib_nav_ang_to_rel_desc_node {
    parameter orbitBinormal.
    parameter targetBinormal.

    local joinVector is -kslib_nav_rel_nodal_vec(orbitBinormal, targetBinormal).
    local angle is vang(-body:position:normalized, joinVector).
    local signVector is vcrs(-body:position, joinVector).
    local sign is vdot(orbitBinormal, signVector).
    if sign < 0 {
        set angle to angle * -1.
    }
    return angle.
}

// Orbital phase angle with assumed target
// Positive when you are behind the target, negative when ahead
function kslib_nav_phase_angle {
    parameter tgtVes,
              thisVes is Ship.

    local common_ancestor is 0.
    local my_ancestors is list().
    local your_ancestors is list().

    my_ancestors:Add(thisVes:Body).
    until not(my_ancestors[my_ancestors:Length-1]:hasBody) {
        my_ancestors:Add(my_ancestors[my_ancestors:Length-1]:Body).
    }
    your_ancestors:Add(tgtVes:Body).
    until not(your_ancestors[your_ancestors:Length-1]:hasBody) {
        your_ancestors:Add(your_ancestors[your_ancestors:Length-1]:Body).
    }

    for my_ancestor in my_ancestors {
        local found is false.
        for your_ancestor in your_ancestors {
            if my_ancestor = your_ancestor {
                set common_ancestor to my_ancestor.
                set found to true.
                break.
            }
        }
        if found {
            break.
        }
    }

    local vel is thisVes:velocity:orbit.
    local my_ancestor is my_ancestors[0].
    until my_ancestor = common_ancestor {
        set vel to vel + my_ancestor:velocity:orbit.
        set my_ancestor to my_ancestor:Body.
    }
    local binormal is vcrs(-common_ancestor:position:normalized, vel:normalized):normalized.

    local phase is vang(
        -common_ancestor:position:normalized,
        vxcl(binormal, tgtVes:position - common_ancestor:position):normalized
    ).
    local signVector is vcrs(
        -common_ancestor:position:normalized,
        (tgtVes:position - common_ancestor:position):normalized
    ).
    local sign is vdot(binormal, signVector).
    if sign < 0 {
        return 360 - phase.
    }
    else {
        return phase.
    }
}

// Average Isp calculation
function kslib_nav_avg_isp {
    local burnEngines is list().
    list engines in burnEngines.
    local massBurnRate is 0.
    for eng in burnEngines {
        if eng:Ignition {
            set massBurnRate to massBurnRate + eng:AvailableThrust/(eng:ISP * constant:g0).
        }
    }
    local isp is -1.
    if massBurnRate <> 0 {
        set isp to ship:Availablethrust / massBurnRate.
    }
    return isp.
}

// Burn time from rocket equation given a single stage
function kslib_nav_burn_time {
    parameter deltaV.
    parameter isp is 0.
    
    if deltaV:typename() = "Vector" {
        set deltaV to deltaV:mag.
    }
    if isp = 0 {
        set isp to kslib_nav_avg_isp().
    }
    
    local burnTime is -1.
    if ship:Availablethrust <> 0 {
        set burnTime to ship:mass * (1 - CONSTANT:E ^ (-deltaV / isp)) / (ship:Availablethrust / isp).
    }
    return burnTime.
}

// Instantaneous azimuth
function kslib_nav_azimuth {
    parameter inclination.
    parameter orbit_alt.
    parameter auto_switch is false.

    local shipLat is ship:latitude.
    if abs(inclination) < abs(shipLat) {
        set inclination to shipLat.
    }

    local head is arcsin(cos(inclination) / cos(shipLat)).
    if auto_switch {
        if kslib_nav_ang_to_body_desc_node(ship) < kslib_nav_ang_to_body_asc_node(ship) {
            set head to 180 - head.
        }
    }
    else if inclination < 0 {
        set head to 180 - head.
    }
    local vOrbit is sqrt(body:mu / (orbit_alt + body:radius)).
    local vRotX is vOrbit * sin(head) - vdot(ship:velocity:orbit, heading(90, 0):vector).
    local vRotY is vOrbit * cos(head) - vdot(ship:velocity:orbit, heading(0, 0):vector).
    set head to 90 - arctan2(vRotY, vRotX).
    return mod(head + 360, 360).
}
