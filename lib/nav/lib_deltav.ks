//lib for  deltaV calculations
@lazyGlobal off.

runOncePath("0:/lib/data/ship/lib_mass.ks").
runOncePath("0:/lib/data/engine/lib_engine.ks").
runOncePath("0:/lib/data/engine/lib_isp.ks").
runOncePath("0:/lib/data/engine/lib_thrust.ks").

//functions
global function get_dv_for_mnv {
    parameter tgtAlt,
              stAlt,
              mnvBody is ship:body.

    //semi-major axis 
    local tgtSMA is tgtAlt + mnvBody:radius.
    local stSMA is stAlt + mnvBody:radius.

    //Return dv
    local dv to ((sqrt(mnvBody:mu / tgtSMA)) * (1 - sqrt((2 * (stSMA)) / (tgtSMA + stSMA)))).
    return dv.
}



global function get_dv_for_mun_transfer {
    parameter tgt.

    set target to tgt.

    //semi-major axis
    local tgtSMA to target:altitude + target:body:radius.
    local stSMA to ship:altitude + ship:body:radius.
    
    //Return dv
    return ((sqrt(ship:body:mu / stSMA)) * ( sqrt((2 * tgtSMA) / (stSMA + tgtSMA)) - 1)).
}



global function get_avail_dv_for_stage {
    parameter s is stage:number.

    logStr("get_avail_dv_for_stage [stg:" + s + "]").
    
    //Get all parts on the ship at the stage. Discards parts not on vessel by time supplied stage is triggered
    local vMass to get_vmass_at_stg(s).
    local eList is ship:partsTaggedPattern("eng.stgId:" + s).
    if eList:length = 0 {
        set s to s - 1.
        set eList to ship:partsTaggedPattern("eng.stgId:" + s). 
        if eList = 0 {
            logStr("return: -1"). 
            return -1.
        }
    }
    
    local exhVel is get_engs_exh_vel(eList, ship:altitude).
    local stgMassObj to get_stage_mass_obj(s).
    local fuelMass to stgMassObj["cur"] - stgMassObj["dry"].
    local spentMass to vMass - fuelMass.
    logStr("exhVel: return: " + exhVel * ln(vMass / spentMass)).
    return exhVel * ln(vMass / spentMass).
}


// Returns an object representing the number of stages involved 
// in a specific deltaV amount, beginning with either the current
// stage or a provided one.
global function get_stages_for_dv {
    parameter _deltaV,                      // Amount of dv needed
              _stageNum is stage:number.    // Stage to start with

    // The object we'll store the result in
    local stageObj is lex().

    // Loop until either the needed DeltaV is accounted for, or
    // we run out of stages
    until _deltaV <= 0 or _stageNum < -1 {

        // Get the deltaV possible for the stage we are on
        local dvStg is get_avail_dv_for_stage(_stageNum).

        // If the deltaV needed is less than what the stage can 
        // deliver, then add the stage number we checked to the 
        // object and break the loop
        if _deltaV < dvStg {
            set stageObj[_stageNum] to round(_deltaV, 2).
            break.

        } else {

            // If there is deltaV available in the stage we are
            // checking, add that stage to the stage object. Then,
            // subtract that total from the needed deltaV. If that
            // puts us below zero, loop will exit
            if dvStg > 0 {
                set stageObj[_stageNum] to round(dvStg, 2).
                set _deltaV to _deltaV - dvStg.
            }

            // Get the next stage that has engines. This is if the 
            // previous stage did not already cover what we needed
            set _stageNum to get_next_stage_with_eng(_stageNum).
        }
    }

    // DeltaV for each stage needed to execute the burn
    return stageObj.
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