//lib for  deltaV calculations
@lazyGlobal off.

//delegates

    //
    global get_deltav_at_ap is get_deltav_for_body_alt_tgt@:bind(ship:body, ship:apoapsis).
    global get_deltav_at_pe is get_deltav_for_body_alt_tgt@:bind(ship:body, ship:periapsis).

//For a given 
global function get_deltav_for_body_alt_tgt {
    parameter pBody,
              pBurnAlt,
              pTgt.

    return ((sqrt(pBody:mu / (pTgt + pBody:radius))) * (1 - sqrt((2 * (ship:periapsis + pBody:radius)) / (ship:periapsis + pTgt + (2 * ( pBody:radius)))))).       
}


// //Calculate a circulization burn
// global function get_circularization_burn {
    
//     set targetPitch to get_pitch_for_altitude(0, targetPeriapsis).
//     set sVal to heading(get_heading(), targetPitch, 0).
//     set tVal to 0.0.

//             //Calculate variables
//             //set cbThrust to get_thrust("available").
//             set cbIsp to get_isp("vacuum").

//             //set cbTwr to get_twr("vacuum").
//             set cbStartMass to get_mass_object():current.
//             set exhaustVelocity to (constant:g0 * cbIsp ). 
//             set obtVelocity to sqrt(body:mu / (body:radius + targetPeriapsis )).

//             //calculate deltaV
//             //From: https://wiki.kerbalspaceprogram.com/wiki/Tutorial:Advanced_Rocket_Design
//             set dV to ((sqrt(body:mu / (targetPeriapsis + body:radius))) * (1 - sqrt((2 * (ship:periapsis + body:radius)) / (ship:periapsis + targetPeriapsis + (2 * (body:radius)))))).
            
//             //Calculate vessel end mass
//             set cbEndMass to (1 / ((cbStartMass * constant:e) ^ (dV / exhaustVelocity))).  

//             //Calculate time parameters for the burn
//             set cbDuration to exhaustVelocity * ln(cbStartMass) - exhaustVelocity * ln(cbEndMass).
//             set cbMarkApo to time:seconds + eta:apoapsis.
//             set cbStartBurn to cbMarkApo - (cbDuration / 2).

//             //create the manuever node
//             set cbNode to node(cbMarkApo, 0, 0, dV).

//             //Add to flight path
//             add cbNode. 

//             set runmode to 10.
// }.