//lib for getting and checking error rate of the vessel direction (heading, pitch, roll).
@lazyGlobal off.

//Checks the input heading and normalizes it for a 360 degree compass
global function check_hdg {

    parameter _refHdg to 90.
    
    local retHdg to 90.

    //Validate heading provided to within bounds
    if _refHdg <= 360 and _refHdg >= 0 {   
        set retHdg to _refHdg.
    }

    //If hdg exceeds upper bounds, try to find the intended heading.
    else if _refHdg > 360 { 
        from { local x to _refHdg.} until x < 360 step { set x to x - 360.} do {
            set retHdg to x. 
            wait 0.001.
        }
    }
    
    else if _refHdg < 0 {
        from { local x to _refHdg.} until x > 0 step { set x to x + 360. } do {
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
    parameter   _vecA,
                _vecB,
                _normal.

    local ang to vAng(_vecA, _vecB).
    if vDot( vCrs(_vecA, _vecB), _normal) < 0 {
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
    parameter _obtIn.

    return vcrs((_obtIn:position - _obtIn:body:position):normalized, obt_tangent(_obtIn)):normalized.
}


//Normal of the given orbit
global function obt_normal {
    parameter _obtIn.

    return vcrs( _obtIn:body:position - _obtIn:position, _obtIn:velocity:orbit):normalized.
}


//Position of the given orbit
global function obt_pos {
    parameter _obtIn.

    return (_obtIn:body:position - _obtIn:position).
}

//Tangent (velocity) of the given orbit
global function obt_tangent {
    parameter _obtIn.

    return _obtIn:velocity:orbit:normalized.
}


//
// All functions below from kslib project (Distrubuted under MIT  license)
//


// Same as orbital prograde vector for ves
global function ves_tangent {
    parameter _ves is ship.

    return _ves:velocity:orbit:normalized.
}



// In the direction of orbital angular momentum of ves
// Typically same as Normal
global function ves_binormal {
    parameter _ves is ship.

    return vcrs((_ves:position - _ves:body:position):normalized, ves_tangent(_ves)):normalized.
}



// Perpendicular to both tangent and binormal
// Typically same as Radial In
global function ves_normal {
    parameter _ves is ship.

    return vcrs(ves_binormal(_ves), ves_tangent(_ves)):normalized.
}


// Vector pointing in the direction of longitude of ascending node
global function ves_lan {
    parameter _ves is ship.

    return angleAxis(_ves:orbit:LAN, _ves:body:angularVel:normalized) * solarPrimeVector.
}



// Same as surface prograde vector for ves
global function ves_srf_tangent {
    parameter _ves is ship.

    return _ves:velocity:surface:normalized.
}



// In the direction of surface angular momentum of ves
// Typically same as Normal
global function ves_srf_binormal {
    parameter _ves is ship.

    return vcrs((_ves:position - _ves:body:position):normalized, ves_srf_tangent(_ves)):normalized.
}



// Perpendicular to both tangent and binormal
// Typically same as Radial In
global function ves_srf_normal {
    parameter _ves is ship.

    return vcrs(ves_srf_binormal(_ves), ves_srf_tangent(_ves)):normalized.
}



// Vector pointing in the direction of longitude of ascending node
global function ves_srf_lan {
    parameter _ves is ship.

    return angleAxis(_ves:orbit:LAN - 90, _ves:body:angularVel:normalized) * solarPrimeVector.
}



// Vector directly away from the body at ves' position
global function ves_local_vertical {
    parameter _ves is ship.

    return _ves:up:vector.
}


// Angle to ascending node with respect to ves' body's equator
global function ang_to_body_asc_node {
    parameter _ves is ship.

    local joinVector is ves_lan(_ves).
    local angle is vang((_ves:position - _ves:body:position):normalized, joinVector).
    if _ves:status = "LANDED" {
        set angle to angle - 90.
    }
    else {
        local signVector is vcrs(-body:position, joinVector).
        local sign is vdot(ves_binormal(_ves), signVector).
        if sign < 0 {
            set angle to angle * -1.
        }
    }
    return angle.
}


// Angle to descending node with respect to ves' body's equator
global function ang_to_body_desc_node {
    parameter _ves is ship.

    local joinVector is -ves_lan(_ves).
    local angle is vang((_ves:position - _ves:body:position):normalized, joinVector).
    if _ves:status = "LANDED" {
        set angle to angle - 90.
    }
    else {
        local signVector is vcrs(-body:position, joinVector).
        local sign is vdot(ves_binormal(_ves), signVector).
        if sign < 0 {
            set angle to angle * -1.
        }
    }
    return angle.
}


// Vector directed from the relative descending node to the ascending node
global function rel_nodal_vec {
    parameter _obtBinormal.
    parameter _tgtBinormal.

    return vcrs(_obtBinormal, _tgtBinormal):normalized.
}


// Angle to relative ascending node determined from args
global function ang_to_rel_asc_node {
    parameter _obtBinormal.
    parameter _tgtBinormal.

    local joinVector is rel_nodal_vec(_obtBinormal, _tgtBinormal).
    local angle is vang(-body:position:normalized, joinVector).
    local signVector is vcrs(-body:position, joinVector).
    local sign is vdot(_obtBinormal, signVector).
    if sign < 0 {
        set angle to angle * -1.
    }
    return angle.
}


// Angle to relative descending node determined from args
global function ang_to_rel_desc_node {
    parameter _obtBinormal.
    parameter _tgtBinormal.

    local joinVector is -rel_nodal_vec(_obtBinormal, _tgtBinormal).
    local angle is vang(-body:position:normalized, joinVector).
    local signVector is vcrs(-body:position, joinVector).
    local sign is vdot(_obtBinormal, signVector).
    if sign < 0 {
        set angle to angle * -1.
    }
    return angle.
}



// Orbital phase angle with assumed target
// Positive when you are behind the target, negative when ahead
global function get_phase_angle {
    parameter _tgt is target.

    local common_ancestor is 0.
    local my_ancestors is list().
    local your_ancestors is list().

    my_ancestors:add(ship:body).
    until not(my_ancestors[my_ancestors:length-1]:hasBody) {
        my_ancestors:add(my_ancestors[my_ancestors:length-1]:body).
    }
    your_ancestors:add(_tgt:body).
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
        vxcl(binormal, _tgt:position - common_ancestor:position):normalized
    ).
    local signVector is vcrs(
        -common_ancestor:position:normalized,
        (_tgt:position - common_ancestor:position):normalized
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
global function eta_to_ta {
    parameter _obtIn,  // Orbit to predict for
              _taDeg.    // true anomaly we need in degrees

    local targetTime is time_pe_to_ta(_obtIn, _taDeg).
    local curTime is time_pe_to_ta(_obtIn, _obtIn:trueanomaly).

    local ta is targetTime - curTime.

    //If negative, we've passed it so return the next orbit
    if ta < 0 { set ta to ta + _obtIn:period. }

    return ta.
}


// The time it takes to get from PE to a given true anomaly
global function time_pe_to_ta {
    parameter _obtIn,  // Orbit to predict for
              _taDeg.    // true anomaly in degrees

    local ecc is _obtIn:eccentricity. 
    local sma is _obtIn:semimajoraxis.
    local eAnomDeg is arcTan2( sqrt(1 - ecc^2) * sin(_taDeg), ecc + cos(_taDeg)).
    local eAnomRad is eAnomDeg * constant:degtorad.
    local mAnomRad is eAnomRad - ecc * sin(eAnomDeg).

    return mAnomRad / sqrt( _obtIn:body:mu / sma^3 ).
}


// Find the ascending node where orbit 0 crosses the plane of orbit 1
// Answer is returned in the form of true anomaly of orbit 0 (angle from
// orbit 0's Pe). Descending node inverse (+180)
global function get_asc_node_ta {
    parameter _obt0, // This should be the ship orbit
              _obt1. // This should be the target orbit

    //Normals of the orbits
    local nrm_0 to obt_normal(_obt0).
    local nrm_1 to obt_normal(_obt1).

    // Unit vector pointing from body's center towards the node
    local vec_body_to_node is vcrs(nrm_0, nrm_1).

    // Vector pointing from body center to obt_0 current position
    local pos_0_body_rel is _obt0:position - _obt0:body:position.

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
    return mod( _obt0:trueanomaly + ta_ahead, 360).
}


// Return an object containing all parameters needed for a maneuver
// to change inclination from orbit 0 to orbit 1. Returns a list:
// - [0] (nodeAt)     - center of burn node
// - [1] (burnVector) - dV vector including direction and mag
// - [2] (nodeStruc)  - A maneuver node structure for this burn
global function get_inc_match_burn {
    parameter _burnVes,  // Vessel that will perform the burn
              _tgtObt. // target orbit to match

    // Normals
    local ves_nrm is obt_normal(_burnVes:obt).
    local tgt_nrm is obt_normal(_tgtObt).

    // Total inclination change
    local d_inc is vang(ves_nrm, tgt_nrm).

    // True anomaly of ascending node
    local node_ta is get_asc_node_ta(_burnVes:obt, _tgtObt).


    // Pick whichever node of AN or DN is higher in altitude,
    // and thus more efficient. node_ta is AN, so if it's 
    // closest to Pe, then use DN 
    if node_ta < 90 or node_ta > 270 {
        set node_ta to mod(node_ta + 180, 360).
    }

    // Get the burn eta
    local burn_eta is eta_to_ta(_burnVes:obt, node_ta).
    local burn_utc is time:seconds + burn_eta.

    // Get the burn unit direction (burnvector direction)
    local burn_unit is (ves_nrm + tgt_nrm):normalized.

    // Get deltav / burnvector magnitude
    local vel_at_eta is velocityAt(_burnVes, burn_utc):orbit.
    local burn_mag is -2 * vel_at_eta:mag * cos(vang(vel_at_eta, burn_unit)).
    
    // Get the dV components for creating the node structure
    local burn_nrm to burn_mag * cos(d_inc / 2).
    local burn_pro to 0 - abs(burn_mag * sin( d_inc / 2)).

    // Create the node struct
    local mnv_node to node(burn_utc, 0, burn_nrm, burn_pro).

    return list(burn_utc, burn_mag * burn_unit, mnv_node, burn_mag, burn_unit).
}

//Get an orbit's altitude at a given true anomaly angle of it
global function obt_alt_at_ta {
    parameter _obtIn,       // Orbit to check
              _trueAnom.    // TA in degrees

    local sma is _obtIn:semimajoraxis.
    local ecc is _obtIn:eccentricity.
    local r is sma * (1 - ecc ^ 2) / (1 + ecc * cos(_trueAnom)).

    // Subtract the body radius from the resulting SMA to get alt
    return r - _obtIn:body:radius.
}
