//lib for getting and checking error rate of the vessel direction (heading, pitch, roll).
@lazyGlobal off.

//Checks the input heading and normalizes it for a 360 degree compass
global function check_hdg {

    parameter refHdg to 90.
    
    local retHdg to 90.

    //Validate heading provided to within bounds
    if refHdg <= 360 and refHdg >= 0 {   
        set retHdg to refHdg.
    }

    //If hdg exceeds upper bounds, try to find the intended heading.
    else if refHdg > 360 { 
        from { local x to refHdg.} until x < 360 step { set x to x - 360.} do {
            set retHdg to x. 
            wait 0.001.
        }
    }
    
    else if refHdg < 0 {
        from { local x to refHdg.} until x > 0 step { set x to x + 360. } do {
            set retHdg to x.
            wait 0.001.
        }
    }

    return retHdg.
}


//Get the current compass heading in degrees
global function get_nav_heading {
    return mod( 360 - latlng( 90, 0):bearing, 360).
}



//Gets the current signed roll value [-180, 180]
global function get_nav_roll {
    parameter   vecA,
                vecB,
                normal.

    local ang to vAng(vecA, vecB).
    if vDot( vCrs(vecA, vecB), normal) < 0 {
        return -ang.
    }

    return ang.
}



//Get the current pitch in degrees [-90, 90]
global function get_nav_pitch {
    return 90 - vAng(up:vector, facing:vector).
}



//Orbital vectors
// In the direction of orbital angular momentum of ves
// Typically same as Normal
global function obt_binormal {
    parameter obtIn.

    return vcrs((obtIn:position - obtIn:body:position):normalized, obt_tangent(obtIn)):normalized.
}


//Normal of the given orbit
global function obt_normal {
    parameter obtIn.

    return vcrs( obtIn:body:position - obtIn:position, obtIn:velocity:orbit):normalized.
}


//Position of the given orbit
global function obt_pos {
    parameter obtIn.

    return (obtIn:body:position - obtIn:position).
}

//Tangent (velocity) of the given orbit
global function obt_tangent {
    parameter obtIn.

    return obtIn:velocity:orbit:normalized.
}


//
// All functions below from kslib project (Distrubuted under MIT  license)
//


// Same as orbital prograde vector for ves
global function ves_tangent {
    parameter ves is ship.

    return ves:velocity:orbit:normalized.
}



// In the direction of orbital angular momentum of ves
// Typically same as Normal
function ves_binormal {
    parameter ves is ship.

    return vcrs((ves:position - ves:body:position):normalized, ves_tangent(ves)):normalized.
}



// Perpendicular to both tangent and binormal
// Typically same as Radial In
function ves_normal {
    parameter ves is ship.

    return vcrs(ves_binormal(ves), ves_tangent(ves)):normalized.
}


// Vector pointing in the direction of longitude of ascending node
function ves_lan {
    parameter ves is ship.

    return angleAxis(ves:orbit:LAN, ves:body:angularVel:normalized) * solarPrimeVector.
}



// Same as surface prograde vector for ves
function ves_srf_tangent {
    parameter ves is ship.

    return ves:velocity:surface:normalized.
}



// In the direction of surface angular momentum of ves
// Typically same as Normal
function ves_srf_binormal {
    parameter ves is ship.

    return vcrs((ves:position - ves:body:position):normalized, ves_srf_tangent(ves)):normalized.
}



// Perpendicular to both tangent and binormal
// Typically same as Radial In
function ves_srf_normal {
    parameter ves is ship.

    return vcrs(ves_srf_binormal(ves), ves_srf_tangent(ves)):normalized.
}



// Vector pointing in the direction of longitude of ascending node
function ves_srf_lan {
    parameter ves is ship.

    return angleAxis(ves:orbit:LAN - 90, ves:body:angularVel:normalized) * solarPrimeVector.
}



// Vector directly away from the body at ves' position
function ves_local_vertical {
    parameter ves is ship.

    return ves:up:vector.
}


// Angle to ascending node with respect to ves' body's equator
function ang_to_body_asc_node {
    parameter ves is ship.

    local joinVector is ves_lan(ves).
    local angle is vang((ves:position - ves:body:position):normalized, joinVector).
    if ves:status = "LANDED" {
        set angle to angle - 90.
    }
    else {
        local signVector is vcrs(-body:position, joinVector).
        local sign is vdot(ves_binormal(ves), signVector).
        if sign < 0 {
            set angle to angle * -1.
        }
    }
    return angle.
}


// Angle to descending node with respect to ves' body's equator
function ang_to_body_desc_node {
    parameter ves is ship.

    local joinVector is -ves_lan(ves).
    local angle is vang((ves:position - ves:body:position):normalized, joinVector).
    if ves:status = "LANDED" {
        set angle to angle - 90.
    }
    else {
        local signVector is vcrs(-body:position, joinVector).
        local sign is vdot(ves_binormal(ves), signVector).
        if sign < 0 {
            set angle to angle * -1.
        }
    }
    return angle.
}


// Vector directed from the relative descending node to the ascending node
function rel_nodal_vec {
    parameter orbitBinormal.
    parameter targetBinormal.

    return vcrs(orbitBinormal, targetBinormal):normalized.
}


// Angle to relative ascending node determined from args
function ang_to_rel_asc_node {
    parameter orbitBinormal.
    parameter targetBinormal.

    local joinVector is rel_nodal_vec(orbitBinormal, targetBinormal).
    local angle is vang(-body:position:normalized, joinVector).
    local signVector is vcrs(-body:position, joinVector).
    local sign is vdot(orbitBinormal, signVector).
    if sign < 0 {
        set angle to angle * -1.
    }
    return angle.
}


// Angle to relative descending node determined from args
function ang_to_rel_desc_node {
    parameter orbitBinormal.
    parameter targetBinormal.

    local joinVector is -rel_nodal_vec(orbitBinormal, targetBinormal).
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
function get_phase_angle {
    parameter tgt is target.

    local common_ancestor is 0.
    local my_ancestors is list().
    local your_ancestors is list().

    my_ancestors:add(ship:body).
    until not(my_ancestors[my_ancestors:length-1]:hasBody) {
        my_ancestors:add(my_ancestors[my_ancestors:length-1]:body).
    }
    your_ancestors:add(tgt:body).
    until not(your_ancestors[your_ancestors:length-1]:hasBody) {
        your_ancestors:add(your_ancestors[your_ancestors:length-1]:body).
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

    local vel is ship:velocity:orbit.
    local my_ancestor is my_ancestors[0].
    until my_ancestor = common_ancestor {
        set vel to vel + my_ancestor:velocity:orbit.
        set my_ancestor to my_ancestor:body.
    }
    local binormal is vcrs(-common_ancestor:position:normalized, vel:normalized):normalized.

    local phase is vang(
        -common_ancestor:position:normalized,
        vxcl(binormal, tgt:position - common_ancestor:position):normalized
    ).
    local signVector is vcrs(
        -common_ancestor:position:normalized,
        (tgt:position - common_ancestor:position):normalized
    ).
    local sign is vdot(binormal, signVector).
    if sign < 0 {
        return -phase + 360.
    }
    else {
        return phase.
    }
}



//From dunbaratu's kos tutorial (youtube.com/watch?v=NctfWrgreRI&list=PLdXwd2JlyAvowkTmfRXZrqVdRycxUIxpX)
//ETA to a future true anomaly point in a given orbit
local function eta_to_ta {
    parameter orbitIn,  // Orbit to predict for
              taDeg.    // true anomaly we need in degrees

    local targetTime is time_pe_to_ta(orbitIn, taDeg).
    local curTime is time_pe_to_ta(orbitIn, orbitIn:trueanomaly).

    local ta is targetTime - curTime.

    //If negative, we've passed it so return the next orbit
    if ta < 0 { set ta to ta + orbitIn:period. }

    return ta.
}


// The time it takes to get from PE to a given true anomaly
local function time_pe_to_ta {
    parameter orbitIn,  // Orbit to predict for
              taDeg.    // true anomaly in degrees

    local ecc is orbitIn:eccentricity. 
    local sma is orbitIn:semimajoraxis.
    local eAnomDeg is arcTan2( sqrt(1 - ecc^2) * sin(taDeg), ecc + cos(taDeg)).
    local eAnomRad is eAnomDeg * constant():pi / 180.
    local mAnomRad is eAnomRad - ecc * sin(eAnomDeg).

    return mAnomRad / sqrt( orbitIn:body:mu / sma^3 ).
}


// Find the ascending node where orbit 0 crosses the plane of orbit 1
// Answer is returned in the form of true anomaly of orbit 0 (angle from
// orbit 0's Pe). Descending node inverse (+180)
local function get_asc_node_ta {
    parameter obt_0, // Orbits to predict - this should be the ship orbit
              obt_1. // This should be the target orbit

    //Normals of the orbits
    local nrm_0 to obt_normal(obt_0).
    local nrm_1 to obt_normal(obt_1).

    // Unit vector pointing from body's center towards the node
    local vec_body_to_node is vcrs(nrm_0, nrm_1).

    // Vector pointing from body center to obt_0 current position
    local pos_0_body_rel is obt_0:position - obt_0:body:position.

    // How many true anomaly degrees ahead of my current true anomaly
    local ta_ahead is vang(vec_body_to_node, pos_0_body_rel).

    // I think this will give us pos / neg depending on how 
    // far ahead it is
    local sign_check_vec is vcrs(vec_body_to_node, pos_0_body_rel).
    
    // If the sign_check_vec is negative (meaning more than 180 degrees 
    // in front of us), it will result in the normal being negative. In
    // this case, we subtract ta_ahead from 360 to get degrees from 
    // current position. 
    if vdot(nrm_0, sign_check_vec) < 0 {
        set ta_ahead to 360 - ta_ahead.
    }

    // Add current true anomaly to our calculated ta_ahead to get the 
    // absolute true anomaly
    return mod( obt_0:trueanomaly + ta_ahead, 360).
}


// Return an object containing all parameters needed for a maneuver
// to change inclination from orbit 0 to orbit 1. Returns a list:
// - [0] (nodeAt) - center of burn node
// - [1] (burnVector) - dV vector including direction and mag
global function get_inc_match_burn {
    parameter brnVes,  // Vessel that will perform the burn
              tgtObt. // target orbit to match

    local ves_nrm is obt_normal(brnVes:obt).
    local tgt_nrm is obt_normal(tgtObt).

    // True anomaly of ascending node
    local node_ta is get_asc_node_ta(brnVes:obt, tgtObt).

    // Pick whichever node of AN or DN is higher in altitude,
    // and thus more efficient. node_ta is AN, so if it's 
    // closest to Pe, then use DN 
    if node_ta < 90 or node_ta > 270 {
        set node_ta to mod(node_ta + 180, 360).
    }

    // Get the burn eta
    local burn_eta is eta_to_ta(brnVes:obt, node_ta).
    local burn_utc is time:seconds + burn_eta.

    // Get the burn direction (burnvector direction)
    local burn_unit is (ves_nrm + tgt_nrm):normalized.

    // Get the deltaV of the burn (burnvector magnitude)
    local vel_at_eta is velocityAt(brnVes, burn_utc):orbit.
    local burn_mag is -2 * vel_at_eta:mag * cos(vang(vel_at_eta, burn_unit)).

    return list(burn_utc, burn_mag * burn_unit).
}


//Get an orbit's altitude at a given true anomaly angle of it
global function obt_alt_at_ta {
    parameter obt_in,       // Orbit to check
              true_anom.    // TA in degrees

    local sma is obt_in:semimajoraxis.
    local ecc is obt_in:eccentricity.
    local r is sma * (1 - ecc ^ 2) / (1 + ecc * cos(true_anom)).

    // Subtract the body radius from the resulting SMA to get alt
    return r - obt_in:body:radius.
}
