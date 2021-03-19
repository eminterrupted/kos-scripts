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
// Angular velocity of a target
global function nav_ang_velocity 
{
    parameter tgt.

    if tgt:typename = "string" set tgt to nav_orbitable(tgt).
    local angVel to (360 / (2 * constant:pi)) * sqrt(tgt:body:mu / tgt:orbit:semiMajorAxis ^ 3).
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

// Gets the phase angle to a target orbitable around a parent body
global function nav_phase_angle
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
    return 180 - (0.5 * nav_hoh_period(hohSMA, ship:body)) * nav_ang_velocity(tgt).
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

// Periapsis from apoapsis and eccentricity
global function nav_pe_from_ap_ecc 
{
    parameter ap,
              ecc,
              tgtBody is ship:body.

    return (((ap + tgtBody:radius) / (1 + ecc)) * (1 - ecc)) - tgtBody:radius.
}

// Period of hohmann transfer
global function nav_hoh_period
{
    parameter hohSMA, tgtBody.

    local hohPeriod to 2 * constant:pi * sqrt(hohSMA^3 / tgtBody:mu).
    return hohPeriod.
}

// Semimajoraxis from apoapsis, periapsis, and body
global function nav_sma
{
    parameter pe,
              ap,
              smaBody is ship:body.

    return (pe + ap + (smaBody:radius * 2)) / 2.
}

//-- TA and Normal Calculations
//From dunbaratu's kos tutorial (youtube.com/watch?v=NctfWrgreRI&list=PLdXwd2JlyAvowkTmfRXZrqVdRycxUIxpX)
//ETA to a future true anomaly point in a given orbit
global function nav_eta_to_ta 
{
    parameter obtIn,  // Orbit to predict for
              taDeg.  // true anomaly we need in degrees

    local targetTime is nav_time_pe_to_ta(obtIn, taDeg).
    local curTime is nav_time_pe_to_ta(obtIn, obtIn:trueanomaly).

    local ta is targetTime - curTime.

    //If negative, we've passed it so return the next orbit
    if ta < 0 
    { 
        set ta to ta + obtIn:period. 
    }

    return ta.
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
    local nrm_0 to ksnav_obt_normal(obt0).
    local nrm_1 to ksnav_obt_normal(obt1).

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