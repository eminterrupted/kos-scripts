// Functions
// Calculates the dv needed for interplanetary depature and arrival
global function mnv_dv_interplanetary_departure
{
    parameter stBody is ship:body,
              tgtBody is target,
              rParkDepart is ship:orbit:semimajoraxis,
              rParkArrive is 1000000.

    local vHyperPe to nav_hyperbolic_pe_velocity(stBody, tgtBody, rParkDepart, rParkArrive).
    local dv0 to abs(vHyperPe[0] - sqrt(stBody:mu / rParkDepart)).
    local dv1 to -(abs(vHyperPe[1] - sqrt(tgtBody:mu / rParkArrive))).
    
    return list(dv0, dv1).
}

// Finds the desired phase angle to burn at for escaping the starting planet parallel to the planet's velocity vector
global function nav_hyperbolic_escape_angle
{
    parameter stBody,
              vEscape.

    local rPark to stBody:orbit:semiMajorAxis.
    return arccos(1 / (1 + ((rPark * vEscape^2) / stBody:mu))).
}

// TO DO
global function nav_escape_angle_eta
{
    parameter stBody, 
              escapeAng.

    local bodyOrbitVec to stBody:orbit:velocity:orbit.
    //local escapeVec    to angleAxis(-(escapeAng), bodyOrbitVec).
}

// Calculates the hyperbolic excess speed of departure hyperbold for patched conics transfers
// From: https://ai-solutions.com/_freeflyeruniversityguide/patched_conics_transfer.htm
global function nav_hyperbolic_excess_exit_velocity
{
    parameter stBody,
              tgtBody.

    local rStBody  to stBody:orbit:semiMajorAxis.
    local rTgtBody to tgtBody:orbit:semiMajorAxis.
    local smaTrans to (rStBody + rTgtBody) / 2.
    
    local vStExit to sqrt(stBody:body:mu / rStBody) * (sqrt(2 - (rStBody / smaTrans)) -  1).


    // local smaTrans to (stBody:orbit:semimajoraxis + tgtBody:orbit:semimajoraxis) / 2.
    // local stRadius to stBody:altitude + stBody:body:radius.
    // return sqrt(ship:body:mu / stRadius) * (sqrt(2 - (stRadius / smaTrans)) - 1).

    // local uStBody to stBody:body:mu.
    // local rStBody to stBody:orbit:semiMajorAxis.
    // local rTgtBody to tgtBody:orbit:semiMajorAxis.
    // local aTrans  to (rStBody + rTgtBody) / 2.

    // local vStBody to sqrt(uStBody / rStBody).
    // local vTrans to sqrt(uStBody * ( (2 / rStBody) - (1 / aTrans))).
    
    // local vStExit to abs(vTrans - vStBody).
    return vStExit.
}


global function nav_hyperbolic_pe_velocity
{
    parameter stBody,
              tgtBody,
              rParkDepart is ship:orbit:semimajoraxis,
              rParkArrive is tgtBody:radius + 1000000.

    local vEscape   to nav_hyperbolic_excess_exit_velocity(stBody, tgtBody).
    local smaEscape to nav_sma_hyperbolic_orbit(stBody, vEscape).

    // print "stBody     : " + stBody at (2, 30).
    // print "tgtBody    : " + tgtBody at (2, 31).
    // print "rParkDepart: " + rParkDepart at (2, 32).
    // print "rParkArrive: " + rParkArrive at (2, 33).
    // print "vEscape    : " + round(vEscape, 2) at (2, 34).
    // print "smaEscape  : " + round(smaEscape, 2) at (2, 35).

    local vPeDepart to sqrt(stBody:mu * ((2 / rParkDepart) - (1 / smaEscape))).
    local vPeArrive to sqrt(tgtBody:mu * ((2 / rParkArrive) - (1 / smaEscape))).
    return list(vPeDepart, vPeArrive).
}

global function nav_sma_hyperbolic_orbit
{
    parameter stBody,
              transferVelocity.

    return ((2 / stBody:soiradius) - (transferVelocity^2 / stBody:mu)) ^(-1).
}