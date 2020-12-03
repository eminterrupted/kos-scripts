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



global function get_stages_for_dv {
    parameter dV,                   // amount of dv needed
              stg is stage:number.  // the stage number to start with. 

    local stgObj is lex().

    logStr("get_stages_for_dv [dv:" + dV + "][stg:" + stg + "]").
    
    until dv <= 0 or stg < -1 {
        local dvStg is get_avail_dv_for_stage(stg).

        if dv < dvStg {
            set stgObj[stg] to round(dv, 2).
            break.
        } else {
            if dvStg > 0 {
                set stgObj[stg] to round(dvStg, 2).
                set dv to dv - dvStg.
            }
            set stg to get_next_stage_with_eng(stg).
        }
    }

    return stgObj.
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