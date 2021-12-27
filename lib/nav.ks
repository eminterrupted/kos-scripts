@lazyGlobal off.

//-- Dependencies --//

//-- Variables --//

//-- Functions --//

//#region -- Waypoints
// Returns the currently active waypoint
global function GetActiveWP
{
    for wp in allWaypoints()
    {
        if wp:isSelected
        {
            return wp.
        }
    }
    return false.
}

//#region -- Patch handling
// Returns the last patch for a given node
global function LastPatchForNode
{
    parameter _node.

    local curPatch to _node:orbit.
    until not curPatch:hasNextPatch 
    {
        set curPatch to curPatch:nextPatch.
    }

    return curPatch.
}

// Returns the next patch for a given node if one exists
global function NextPatchForNode
{
    parameter _node.

    local curPatch to _node:orbit.
    if curPatch:hasNextPatch 
    {
        set curPatch to curPatch:nextPatch.
    }

    return curPatch.
}
//#endregion

//#region -- GeoCoordinates
// Converts longitude into degrees
global function LngToDegress
{
    parameter lng.
    return mod(lng + 360, 360).
}

//#region -- Target and Transfer data Functions
// GetAngVelocity :: <orbitable>, <body> -> <scalar>
// Angular velocity of a target in radians
global function GetAngVelocity 
{
    parameter tgt,
              mnvBody is ship:body.

    local angVel to (360 / (2 * constant:pi)) * sqrt(mnvBody:mu / tgt:orbit:semiMajorAxis ^ 3).
    //local angVel to (tgt:orbit:velocity:orbit:mag / tgt:orbit:semiMajorAxis) * constant:radtodeg.
    //local angVel to (tgt:orbit:velocity:orbit:mag / tgt:orbit:semiMajorAxis).
    //local angVel to sqrt(mnvBody:mu / tgt:orbit:semiMajorAxis^3).
    return angVel.
}

// GetAngVelocityNext :: <orbitable>, <body> -> <scalar>
// Angular velocity of a target using a different formula than above
global function GetAngVelocityNext
{
    parameter tgt,
              mnvBody is ship:body.

    local angVel to (tgt:orbit:velocity:orbit:mag / tgt:orbit:semiMajorAxis) * constant:radtodeg.
    return angVel.
}

// Phase angle relative to longitude
global function LngToPhaseAng
{
    parameter tgt.

    return mod(LngToDegress(tgt:longitude) - LngToDegress(ship:longitude) + 360, 360).
}

// Converts a string to an orbitable type
global function GetOrbitable 
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

// GetTransferPhase :: <orbitable / string>, <scalar> -> <scalar>
// Returns the proper phase angle to start a transfer burn. from: https://ai-solutions.com/_freeflyeruniversityguide/interplanetary_hohmann_transfe.htm#calculatinganinterplanetaryhohmanntransfer
global function GetTransferPhase
{
    parameter tgt,
              stAlt.
    
    local angVelTarget  to GetAngVelocity(tgt, tgt:body).
    local tSMA          to GetSMA(stAlt, tgt:altitude, tgt:body).
    local tHoh          to GetTransferPeriod(tSMA, tgt:body).
    return 180 - 0.5 * (tHoh * angVelTarget).
}

// KSNavPhaseAng :: <orbitable>, <vessel> -> <scalar>
// From KSLib - Gets the phase angle relative to LAN for a target and starting ship
global function KSNavPhaseAng {
    parameter tgt is target, 
              stObj is ship.
    
    local common_ancestor is 0.
    local my_ancestors is list().
    local your_ancestors is list().

    my_ancestors:add(stObj:body).
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

    local vel is stObj:orbit:velocity:orbit.
    local my_ancestor is my_ancestors[0].
    until my_ancestor = common_ancestor {
        set vel to vel + my_ancestor:orbit:velocity:orbit.
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

//#endregion

//#region -- Orbit Calculations
// Apoapsis from periapsis and eccentricity
global function GetAp 
{
    parameter pe,
              ecc,
              tgtBody is ship:body.

    return (((pe + tgtBody:radius) / (1 - ecc)) * (1 + ecc)) - tgtBody:radius.
}

// Eccentricity from apoapsis and periapsis
global function GetEcc
{
    parameter pe,
              ap,
              tgtBody is ship:body.

    return ((ap + tgtBody:radius) - (pe + tgtBody:radius)) / (ap + pe + (tgtBody:radius * 2)).
}

// Apoapsis and Periapsis from sma and ecc
global function GetApPe
{
    parameter sma,
              ecc.

    local pe to sma * (1 - ecc).
    local ap to sma * (1 + ecc).

    return list (pe, ap).
}

// Periapsis from apoapsis and eccentricity
global function GetPe 
{
    parameter ap,
              ecc,
              tgtBody is ship:body.

    return (((ap + tgtBody:radius) / (1 + ecc)) * (1 - ecc)) - tgtBody:radius.
}

// Period of hohmann transfer
global function GetPeriod
{
    parameter tgtSMA, 
              tgtBody is ship:body.

    return 0.5 * sqrt((4 * constant:pi^2 * tgtSMA^3) / tgtBody:mu).
}

// Semimajoraxis from orbital period
global function GetSMAFromPeriod
{
    parameter period, 
              tgtBody is ship:body.

    return ((tgtBody:mu * period^2) / (4 * constant:pi^2))^(1/3).
}

// Semimajoraxis from apoapsis, periapsis, and body
global function GetSMA
{
    parameter pe,
              ap,
              smaBody is ship:body.

    return (pe + ap + (smaBody:radius * 2)) / 2.
}

// 
global function GetTransferSma
{
    parameter arrivalRadius,
              parkingOrbit.

    return (arrivalRadius + parkingOrbit) / 2.
}

global function GetTransferPeriod
{
    parameter xfrSMA,
              tgtBody is ship:body.

    //return 0.5 * sqrt((4 * constant:pi^2 * xfrSMA^3) / tgtBody:mu).
    return 2 * constant:pi * sqrt(xfrSMA^3 / tgtBody:mu).
}
//#endregion

//#region -- Calculations of True Anomaly
//From dunbaratu's kos tutorial (youtube.com/watch?v=NctfWrgreRI&list=PLdXwd2JlyAvowkTmfRXZrqVdRycxUIxpX)
//ETA to a future true anomaly point in a given orbit
global function ETAtoTA 
{
    parameter obtIn,  // Orbit to predict for
              taDeg.  // true anomaly we need in degrees

    local targetTime is TimePeToTA(obtIn, taDeg).
    local curTime is TimePeToTA(obtIn, obtIn:trueanomaly).

    local utimeAtTA is targetTime - curTime.
    
    //If negative, we've passed it so return the next orbit
    if utimeAtTA < 0
    { 
        set utimeAtTA to utimeAtTA + obtIn:period. 
    }

    return utimeAtTA.
}


// The time it takes to get from PE to a given true anomaly
global function TimePeToTA 
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
global function AscNodeTA 
{
    parameter obt0, // This should be the ship orbit
              obt1. // This should be the target orbit

    //Normals of the orbits
    local nrm_0 to ObtNormal(obt0).
    local nrm_1 to ObtNormal(obt1).

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
global function AltAtTA 
{
    parameter obtIn,       // Orbit to check
              trueAnom.    // TA in degrees

    local sma is obtIn:semimajoraxis.
    local ecc is obtIn:eccentricity.
    local r is sma * (1 - ecc ^ 2) / (1 + ecc * cos(trueAnom)).

    // Subtract the body radius from the resulting SMA to get alt
    return r - obtIn:body:radius.
}

// Converts a true anomaly to the mean anomaly. 
global function TAtoMA
{
    parameter obtIn, 
              trueAnom.

    local ecc to obtIn:eccentricity.
    local ea to arctan2(sqrt(1 - ecc^2) * sin(trueAnom), ecc + cos(trueAnom)).
    local ma to ea - (ecc * sin(ea) * constant:radtodeg).
    return mod(ma + 360, 360).
}
//#endregion

//#region -- Nav vectors
// In the direction of orbital angular momentum of ves
// Typically same as Normal
global function ObtBinormal 
{
    parameter obtIn.
    return vcrs((obtIn:position - obtIn:body:position):normalized, ObtTangent(obtIn)):normalized.
}

//Normal of the given orbit
global function ObtNormal 
{
    parameter obtIn.
    return vcrs( obtIn:body:position - obtIn:position, obtIn:velocity:orbit):normalized.
}

//Position of the given orbit
global function ObtPosition 
{
    parameter obtIn.
    return (obtIn:body:position - obtIn:position).
}

//Tangent (velocity) of the given orbit
global function ObtTangent 
{
    parameter obtIn.
    return obtIn:velocity:orbit:normalized.
}
//#endregion

//#region -- ksLib nav vectors
// Same as orbital prograde vector for ves
global function VesTangent 
{
    parameter ves is ship.
    return ves:velocity:orbit:normalized.
}

// In the direction of orbital angular momentum of ves
// Typically same as Normal
global function VesBinormal 
{
    parameter ves is ship.
    return vcrs((ves:position - ves:body:position):normalized, VesTangent(ves)):normalized.
}

// Perpendicular to both tangent and binormal
// Typically same as Radial In
global function VesNormal 
{
    parameter ves is ship.
    return vcrs(VesBinormal(ves), VesTangent(ves)):normalized.
}

// Vector pointing in the direction of longitude of ascending node
global function VesLAN 
{
    parameter ves is ship.
    return angleAxis(ves:orbit:LAN, ves:body:angularVel:normalized) * solarPrimeVector.
}

// Same as surface prograde vector for ves
global function VesSrfTangent 
{
    parameter ves is ship.
    return ves:velocity:surface:normalized.
}

// In the direction of surface angular momentum of ves
// Typically same as Normal
global function VesSrfBinormal 
{
    parameter ves is ship.
    return vcrs((ves:position - ves:body:position):normalized, VesSrfTangent(ves)):normalized.
}

// Perpendicular to both tangent and binormal
// Typically same as Radial In
global function VesSrfNormal 
{
    parameter ves is ship.
    return vcrs(VesSrfBinormal(ves), VesSrfTangent(ves)):normalized.
}

// Vector pointing in the direction of longitude of ascending node
global function VesSrfLAN 
{
    parameter ves is ship.
    return angleAxis(ves:orbit:LAN - 90, ves:body:angularVel:normalized) * solarPrimeVector.
}

// Vector directly away from the body at ves' position
global function VesLocalVertical 
{
    parameter ves is ship.
    return ves:up:vector.
}

// Angle to ascending node with respect to ves' body's equator
function AngToBodyAscNode {
    parameter ves is ship.

    local joinVector is VesLAN(ves).
    local angle is vang((ves:position - ves:body:position):normalized, joinVector).
    if ves:status = "LANDED" {
        set angle to angle - 90.
    }
    else {
        local signVector is vcrs(-body:position, joinVector).
        local sign is vdot(VesBinormal(ves), signVector).
        if sign < 0 {
            set angle to angle * -1.
        }
    }
    return angle.
}

// Angle to descending node with respect to ves' body's equator
function AngToBodyDescNode {
    parameter ves is ship.

    local joinVector is -VesLAN(ves).
    local angle is vang((ves:position - ves:body:position):normalized, joinVector).
    if ves:status = "LANDED" {
        set angle to angle - 90.
    }
    else {
        local signVector is vcrs(-body:position, joinVector).
        local sign is vdot(VesBinormal(ves), signVector).
        if sign < 0 {
            set angle to angle * -1.
        }
    }
    return angle.
}

// Vector directed from the relative descending node to the ascending node
function DescToAscNodeVec {
    parameter orbitBinormal.
    parameter targetBinormal.

    return vcrs(orbitBinormal, targetBinormal):normalized.
}

// Angle to relative ascending node determined from args
function AngToRelAscNode {
    parameter orbitBinormal.
    parameter targetBinormal.

    local joinVector is DescToAscNodeVec(orbitBinormal, targetBinormal).
    local angle is vang(-body:position:normalized, joinVector).
    local signVector is vcrs(-body:position, joinVector).
    local sign is vdot(orbitBinormal, signVector).
    if sign < 0 {
        set angle to angle * -1.
    }
    return angle.
}

// Angle to relative descending node determined from args
function AngToRelDescNode {
    parameter orbitBinormal.
    parameter targetBinormal.

    local joinVector is -DescToAscNodeVec(orbitBinormal, targetBinormal).
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
global function TransferVelocity
{
    parameter rStart,
              endSMA,
              mnvBody is ship:body.
    
    return sqrt(mnvBody:mu * ((2 / (rStart)) - (1 / endSMA))).
}

// Velocity given a true anomaly
global function VelocityAtTA
{
    parameter ves,
              orbitIn,
              anomaly.

    local etaToAnomaly to time:seconds + ETAtoTA(orbitIn, anomaly).
    return velocityAt(ves, etaToAnomaly):orbit:mag.
}
//#endregion

// GetHyperAsymptoteAng :: <none> -> <scalar>
// Returns the angle between the two asymptotes in a hyperbolic trajectory
global function GetHyperAsymptoteAng
{
    return arcSin(1 / ship:orbit:eccentricity).
}

// GetHyperDepartureAng :: <none> -> <scalar>
// 
global function GetHyperDepatureAng
{
    return arcCos(-(1 / ship:orbit:eccentricity)).
}

// GetHyperTA :: <none> -> <scalar>
//
global function GetHyperTA 
{
    local peSma to ship:periapsis + body:radius.
    local ta to arcCos((ship:orbit:semimajoraxis * (1 - ship:orbit:eccentricity^2) - (peSma)) / (ship:orbit:eccentricity * peSma)).
    return ta.
}

// GetHyperPe :: <none> -> <scalar>
// Returns the periapsis of the current hyperbolic orbit
global function GetHyperPe
{
    return (ship:orbit:semiMajorAxis * (1 - ship:orbit:eccentricity)) - ship:body:radius.
}

// GetFlightPathAng :: <ship> -> <scalar>
global function GetFlightPathAng
{
    parameter ves is ship.

    local ecc to ves:orbit:eccentricity.
    local ta to GetTA(ves).

    return arcTan((ecc * sin(ta)) / (1 + (ecc * cos(ta)))).
}

// GetTA :: <ship>, <scalar> -> <scalar>
// Returns the TA for the given ship at a specific radius
global function GetTA
{
    parameter ves is ship,
              radius is ship:altitude + body:radius.

    local ecc to ves:orbit:eccentricity.
    local a to ves:orbit:semimajoraxis.
    
    return arcCos((a * (1 - ecc^2) - radius) / (ecc * radius)).
}

// GetVelAtSMA :: <ship>, <scalar> -> <scalar>
// 
global function GetVelAtRadius
{
    parameter ves is ship,
              radius is ship:altitude + body:radius.

    return sqrt(body:mu * ((2 / radius) - (1 / ves:orbit:semimajoraxis))).
}