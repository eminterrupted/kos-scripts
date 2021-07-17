@lazyGlobal off.
clearScreen.

parameter stBody is ship:body,
          tgtBody is target,
          tgtAlt  is 1000000,
          tgtInc  is 0.

runOncePath("0:/lib/lib_mnv").
runOncePath("0:/lib/lib_nav").

// This probably should be split into two scripts - planning and execution

// Calculate ideal phase angle between stBody and tgtBody around kerbol
// Turn phase angle into transfer window
// Determine where along orbit both stBody and ship will be at transfer window
// Get dv for transfer and arrival burns.
// Adjust departure phasing for exit velocity parallel to the planet
// Set up the node for depature
// Get ETA to patch containing tgtBody
// Get ETA to that patch Pe
// Set up the node for arrival







// Functions
// Calculates the dv needed for interplanetary depature and arrival
global function mnv_dv_interplanetary_departure
{
    parameter stBody is ship:body,
              tgtBody is target,
              rParkDepart is ship:orbit:semimajoraxis,
              rParkArrive is tgtAlt.

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

    local rPark to st:orbit:semiMajorAxis.
    return arccos(1 / (1 + ((rPark * vEscape^2) / stBody:mu))).
}

// Calculates the hyperbolic excess speed of departure hyperbold for patched conics transfers
// From: https://ai-solutions.com/_freeflyeruniversityguide/patched_conics_transfer.htm
global function nav_hyperbolic_excess_exit_velocity
{
    parameter stBody,
              tgtBody.

    local smaTrans to (stBody:semimajoraxis + tgtBody:semimajoraxis) / 2.
    local stRadius to stBody:altitude + stBody:body:radius.
    return sqrt(sun:mu / stRadius) * (sqrt(2 - (stRadius / smaTrans)) - 1).
}


global function nav_hyperbolic_pe_velocity
{
    parameter stBody,
              tgtBody,
              rParkDepart is ship:orbit:semimajoraxis,
              rParkArrive is tgtBody:radius + 1000000.

    local vEscape   to nav_hyperbolic_excess_exit_velocity(stBody, tgtBody).
    local smaEscape to nav_sma_hyperbolic_orbit(stBody, vEscape).

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