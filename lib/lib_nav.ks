@lazyGlobal off.

//-- Dependencies --//

//-- Variables --//

//-- Functions --//

// Converts longitude into degrees
global function nav_lng_to_degrees
{
    parameter lng.
    return mod(lng + 360, 360).
}

//#region -- Target Functions
// Angular velocity of a target in radians
global function nav_ang_velocity 
{
    parameter tgt,
              mnvBody is ship:body.

    if tgt:typename = "string" set tgt to nav_orbitable(tgt).
    // local angVel to (360 / (2 * constant:pi)) * sqrt(tgt:body:mu / tgt:orbit:semiMajorAxis ^ 3).
    local angVel to sqrt(mnvBody:mu / tgt:orbit:semiMajorAxis^3).
    return angVel.
}

// Converts a string to an orbitable type
global function nav_orbitable 
{
    parameter tgtStr.

    if tgtStr:typename = "vessel" or tgtStr:typeName = "body" 
    {
        return tgtStr. 
    }
    
    local vList to list().
    list targets in vList.

    for vs in vList 
    {
        if vs:name = tgtStr
        {
            return vessel(tgtStr).
        }
    }
    return body(tgtStr).
}

// From KSLib - Gets the phase angle relative to LAN 
function ksnav_phase_angle {
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
        return -phase.
    }
    else {
        return phase.
    }
}

// Phase angle relative to longitude
global function nav_lng_phase_angle
{
    parameter tgt.

    return mod(nav_lng_to_degrees(tgt:longitude) - nav_lng_to_degrees(ship:longitude) + 360, 360).
}

// Returns the proper phase angle to start a transfer burn
global function nav_transfer_phase_angle
{
    parameter tgt,
              stAlt.
    
    if tgt:typename = "string" set tgt to nav_orbitable(tgt).
    local hohSMA to nav_sma(stAlt, tgt:altitude, ship:body).
    //return 180 - (0.5 * nav_transfer_period(hohSMA, ship:body) * (nav_ang_velocity(tgt) * constant:radToDeg)).
    return 2 * constant:radToDeg * (constant:pi - (nav_ang_velocity(tgt, ship:body) * nav_transfer_period(hohSMA, ship:body))).
}
//#endregion

//#region -- Orbit Calculations
// Apoapsis from periapsis and eccentricity
global function nav_ap_from_pe_ecc 
{
    parameter pe,
              ecc,
              tgtBody is ship:body.

    return (((pe + tgtBody:radius) / (1 - ecc)) * (1 + ecc)) - tgtBody:radius.
}

// Eccentricity from apoapsis and periapsis
global function nav_ecc
{
    parameter pe,
              ap,
              tgtBody is ship:body.

    return ((ap + tgtBody:radius) - (pe + tgtBody:radius)) / (ap + pe + (tgtBody:radius * 2)).
}

// Apoapsis and Periapsis from sma and ecc
global function nav_pe_ap_from_sma_ecc
{
    parameter sma,
              ecc.

    local pe to sma * (1 - ecc).
    local ap to sma * (1 + ecc).

    return list (pe, ap).
}

// Periapsis from apoapsis and eccentricity
global function nav_pe_from_ap_ecc 
{
    parameter ap,
              ecc,
              tgtBody is ship:body.

    return (((ap + tgtBody:radius) / (1 + ecc)) * (1 - ecc)) - tgtBody:radius.
}

// Period of hohmann transfer
global function nav_period_from_sma
{
    parameter tgtSMA, 
              tgtBody is ship:body.

    return 0.5 * sqrt((4 * constant:pi^2 * tgtSMA^3) / tgtBody:mu).
}

// Semimajoraxis from orbital period
global function nav_sma_from_period
{
    parameter period, 
              tgtBody is ship:body.

    return ((tgtBody:mu * period^2) / (4 * constant:pi^2))^(1/3).
}

// Semimajoraxis from apoapsis, periapsis, and body
global function nav_sma
{
    parameter pe,
              ap,
              smaBody is ship:body.

    return (pe + ap + (smaBody:radius * 2)) / 2.
}

global function nav_transfer_period
{
    parameter xfrSMA,
              tgtBody is ship:body.

    return 0.5 * sqrt((4 * constant:pi^2 * xfrSMA^3) / tgtBody:mu).
}
//#endregion

//#region -- Calculations of True Anomaly
//From dunbaratu's kos tutorial (youtube.com/watch?v=NctfWrgreRI&list=PLdXwd2JlyAvowkTmfRXZrqVdRycxUIxpX)
//ETA to a future true anomaly point in a given orbit
global function nav_eta_to_ta 
{
    parameter obtIn,  // Orbit to predict for
              taDeg.  // true anomaly we need in degrees

    local targetTime is nav_time_pe_to_ta(obtIn, taDeg).
    local curTime is nav_time_pe_to_ta(obtIn, obtIn:trueanomaly).

    local utimeAtTA is targetTime - curTime.
    
    //If negative, we've passed it so return the next orbit
    if utimeAtTA < 0
    { 
        set utimeAtTA to utimeAtTA + obtIn:period. 
    }

    return utimeAtTA.
}


// The time it takes to get from PE to a given true anomaly
global function nav_time_pe_to_ta 
{
    parameter obtIn,  // Orbit to predict for
              taDeg.  // true anomaly in degrees

    local ecc is obtIn:eccentricity. 
    local sma is obtIn:semimajoraxis.
    local eAnomDeg is arcTan2( sqrt(1 - ecc^2) * sin(taDeg), ecc + cos(taDeg)).
    local eAnomRad is eAnomDeg * constant:degtorad.
    local mAnomRad is eAnomRad - ecc * sin(eAnomDeg).

    return mAnomRad / sqrt( obtIn:body:mu / sma^3 ).
}


// Find the ascending node where orbit 0 crosses the plane of orbit 1
// Answer is returned in the form of true anomaly of orbit 0 (angle from
// orbit 0's Pe). Descending node inverse (+180)
global function nav_asc_node_ta 
{
    parameter obt0, // This should be the ship orbit
              obt1. // This should be the target orbit

    //Normals of the orbits
    local nrm_0 to nav_obt_normal(obt0).
    local nrm_1 to nav_obt_normal(obt1).

    // Unit vector pointing from body's center towards the node
    local vec_body_to_node is vcrs(nrm_0, nrm_1).

    // Vector pointing from body center to obt_0 current position
    local pos_0_body_rel is obt0:position - obt0:body:position.

    // How many true anomaly degrees ahead of my current true anomaly
    local ta_ahead is vang(vec_body_to_node, pos_0_body_rel).

    // I think this will give us pos / neg depending on how 
    // far ahead it is
    local sign_check_vec is vcrs(vec_body_to_node, pos_0_body_rel).
    
    // If the sign_check_vec is negative (meaning more than 180 degrees 
    // in front of us), it will result in the normal being negative. In
    // this case, we subtract ta_ahead from 360 to get degrees from 
    // current position. 
    if vdot(nrm_0, sign_check_vec) < 0
    {
        set ta_ahead to 360 - ta_ahead.
    }

    // Add current true anomaly to our calculated ta_ahead to get the 
    // absolute true anomaly
    return mod( obt0:trueanomaly + ta_ahead, 360).
}

//Get an orbit's altitude at a given true anomaly angle of it
global function nav_obt_alt_at_ta 
{
    parameter obtIn,       // Orbit to check
              trueAnom.    // TA in degrees

    local sma is obtIn:semimajoraxis.
    local ecc is obtIn:eccentricity.
    local r is sma * (1 - ecc ^ 2) / (1 + ecc * cos(trueAnom)).

    // Subtract the body radius from the resulting SMA to get alt
    return r - obtIn:body:radius.
}
//#endregion

//#region -- Nav vectors
// In the direction of orbital angular momentum of ves
// Typically same as Normal
global function nav_obt_binormal 
{
    parameter obtIn.
    return vcrs((obtIn:position - obtIn:body:position):normalized, nav_obt_tangent(obtIn)):normalized.
}

//Normal of the given orbit
global function nav_obt_normal 
{
    parameter obtIn.
    return vcrs( obtIn:body:position - obtIn:position, obtIn:velocity:orbit):normalized.
}

//Position of the given orbit
global function nav_obt_pos 
{
    parameter obtIn.
    return (obtIn:body:position - obtIn:position).
}

//Tangent (velocity) of the given orbit
global function nav_obt_tangent 
{
    parameter obtIn.
    return obtIn:velocity:orbit:normalized.
}
//#endregion

//#region -- ksLib nav vectors
// Same as orbital prograde vector for ves
global function nav_ves_tangent 
{
    parameter ves is ship.
    return ves:velocity:orbit:normalized.
}

// In the direction of orbital angular momentum of ves
// Typically same as Normal
global function nav_ves_binormal 
{
    parameter ves is ship.
    return vcrs((ves:position - ves:body:position):normalized, nav_ves_tangent(ves)):normalized.
}

// Perpendicular to both tangent and binormal
// Typically same as Radial In
global function nav_ves_normal 
{
    parameter ves is ship.
    return vcrs(nav_ves_binormal(ves), nav_ves_tangent(ves)):normalized.
}

// Vector pointing in the direction of longitude of ascending node
global function nav_ves_lan 
{
    parameter ves is ship.
    return angleAxis(ves:orbit:LAN, ves:body:angularVel:normalized) * solarPrimeVector.
}

// Same as surface prograde vector for ves
global function nav_ves_srf_tangent 
{
    parameter ves is ship.
    return ves:velocity:surface:normalized.
}

// In the direction of surface angular momentum of ves
// Typically same as Normal
global function nav_ves_srf_binormal 
{
    parameter ves is ship.
    return vcrs((ves:position - ves:body:position):normalized, nav_ves_srf_tangent(ves)):normalized.
}

// Perpendicular to both tangent and binormal
// Typically same as Radial In
global function nav_ves_srf_normal 
{
    parameter ves is ship.
    return vcrs(nav_ves_srf_binormal(ves), nav_ves_srf_tangent(ves)):normalized.
}

// Vector pointing in the direction of longitude of ascending node
global function nav_ves_srf_lan 
{
    parameter ves is ship.
    return angleAxis(ves:orbit:LAN - 90, ves:body:angularVel:normalized) * solarPrimeVector.
}

// Vector directly away from the body at ves' position
global function nav_ves_local_vertical 
{
    parameter ves is ship.
    return ves:up:vector.
}

// Angle to ascending node with respect to ves' body's equator
function nav_ang_to_body_asc_node {
    parameter ves is ship.

    local joinVector is nav_ves_lan(ves).
    local angle is vang((ves:position - ves:body:position):normalized, joinVector).
    if ves:status = "LANDED" {
        set angle to angle - 90.
    }
    else {
        local signVector is vcrs(-body:position, joinVector).
        local sign is vdot(nav_ves_binormal(ves), signVector).
        if sign < 0 {
            set angle to angle * -1.
        }
    }
    return angle.
}

// Angle to descending node with respect to ves' body's equator
function nav_ang_to_body_desc_node {
    parameter ves is ship.

    local joinVector is -nav_ves_lan(ves).
    local angle is vang((ves:position - ves:body:position):normalized, joinVector).
    if ves:status = "LANDED" {
        set angle to angle - 90.
    }
    else {
        local signVector is vcrs(-body:position, joinVector).
        local sign is vdot(nav_ves_binormal(ves), signVector).
        if sign < 0 {
            set angle to angle * -1.
        }
    }
    return angle.
}

// Vector directed from the relative descending node to the ascending node
function nav_rel_nodal_vec {
    parameter orbitBinormal.
    parameter targetBinormal.

    return vcrs(orbitBinormal, targetBinormal):normalized.
}

// Angle to relative ascending node determined from args
function nav_ang_to_rel_asc_node {
    parameter orbitBinormal.
    parameter targetBinormal.

    local joinVector is nav_rel_nodal_vec(orbitBinormal, targetBinormal).
    local angle is vang(-body:position:normalized, joinVector).
    local signVector is vcrs(-body:position, joinVector).
    local sign is vdot(orbitBinormal, signVector).
    if sign < 0 {
        set angle to angle * -1.
    }
    return angle.
}

// Angle to relative descending node determined from args
function nav_ang_to_rel_desc_node {
    parameter orbitBinormal.
    parameter targetBinormal.

    local joinVector is -nav_rel_nodal_vec(orbitBinormal, targetBinormal).
    local angle is vang(-body:position:normalized, joinVector).
    local signVector is vcrs(-body:position, joinVector).
    local sign is vdot(orbitBinormal, signVector).
    if sign < 0 {
        set angle to angle * -1.
    }
    return angle.
}
//#endregion

//#region -- Velocity calculations
// Transfer velocity from start and end semimajoraxis
global function nav_transfer_velocity
{
    parameter rStart,
              endSMA,
              mnvBody is ship:body.
    
    return sqrt(mnvBody:mu * ((2 / (rStart)) - (1 / endSMA))).
}

// Velocity given a true anomaly
global function nav_velocity_at_ta
{
    parameter ves,
              orbitIn,
              anomaly.

    local etaToAnomaly to time:seconds + nav_eta_to_ta(orbitIn, anomaly).
    return velocityAt(ves, etaToAnomaly):orbit:mag.
}
//#endregion