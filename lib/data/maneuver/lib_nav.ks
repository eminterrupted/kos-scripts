//lib for getting and checking error rate of the vessel direction (heading, pitch, roll).
@lazyGlobal off.

runOncePath("0:/lib/lib_init.ks").
runOncePath("0:/lib/data/vessel/lib_mass.ks").
runOncePath("0:/lib/data/maneuver/lib_deltav.ks").
runOncePath("0:/lib/data/engine/lib_thrust.ks").
runOncePath("0:/lib/data/engine/lib_isp.ks").
runOncePath("0:/lib/data/engine/lib_twr.ks").


global function get_burn_data {
    
    parameter newAlt.

    //Read calculating fuel flow in wiki: https://wiki.kerbalspaceprogram.com/wiki/Tutorial:Advanced_Rocket_Design


    //Calculate variables
    local apIsp is get_avail_isp(body:atm:altitudePressure(ship:apoapsis)).
    local startMass is get_mass_at_stage(stage:number).
    local exhVel is (constant:g0 * apIsp).
    local nodeAt is time:seconds + eta:apoapsis.
    
    //TODO - Print orbital velocity
    //local obtVel is sqrt(body:mu / (body:radius + newAlt)).

    //get deltaV for the burn
    local dV is get_deltav_at_ap(newAlt).
    
    //Calculate time parameters for the burn
    local stageThrust is get_avail_thrust_for_alt(stage:number, ship:apoapsis).
    local fuelBurned is startMass - ( startMass / (constant:e ^ (dV / exhVel))).
    local endMass is startMass - fuelBurned.

    //local burnDur is exhVel * ln(startMass) - exhVel * ln(endMass).
    local burnDur is ((startMass * exhVel) / stageThrust) * ( 1 - (constant:e ^ (-1 * (dv / exhVel)))).
    local burnEta is nodeAt - (burnDur / 2).
    local burnEnd is nodeAt + (burnDur / 2).

    return lexicon("dV",dV,"burnDur",burnDur,"burnEta",burnEta,"burnEnd",burnEnd,"nodeAt",nodeAt,"startMass",startMass,"endMass",endMass).
}


//Checks the input heading and normalizes it for a 360 degree compass
global function check_heading {

    parameter refHdg is 90.
    
    local retHdg is 90.

    //Validate heading provided is within bounds
    if refHdg <= 360 and refHdg >= 0 {   
        set retHdg to refHdg.
    }

    //If hdg exceeds upper bounds, try to find the intended heading.
    else if refHdg > 360 { 
        from { local x is refHdg.} until x < 360 step { set x to x - 360.} do {
            set retHdg to x. 
            wait 0.001.
        }
    }
    
    else if refHdg < 0 {
        from { local x is refHdg.} until x > 0 step { set x to x + 360. } do {
            set retHdg to x.
            wait 0.001.
        }
    }

    return retHdg.
}.


//Get the current compass heading in degrees
global function get_nav_heading {
    return mod( 360 - latlng( 90, 0):bearing, 360).
}.


//Gets the current signed roll value [-180, 180]
global function get_nav_roll {
    parameter   vecA,
                vecB,
                normal.

    local ang is vAng(vecA, vecB).
    if vDot( vCrs(vecA, vecB), normal) < 0 {
        return -ang.
    }

    return ang.
}.


//Get the current pitch in degrees [-90, 90]
global function get_nav_pitch {
    return 90 - vAng(up:vector, facing:vector).
}.