//lib for  deltaV calculations
@lazyGlobal off.

runOncePath("0:/lib/lib_core").
runOncePath("0:/lib/data/ship/lib_mass").
runOncePath("0:/lib/data/engine/lib_engine").
runOncePath("0:/lib/data/engine/lib_isp").
runOncePath("0:/lib/data/engine/lib_thrust").
runOncePath("0:/lib/part/lib_rcs").

//functions
global function get_dv_for_prograde {
    parameter tgtAlt,
              stAlt,
              mnvBody is ship:body.

    //semi-major axis 
    local tgtSMA is tgtAlt + mnvBody:radius.
    local stSMA is stAlt + mnvBody:radius.

    //Return dv
    local dv to sqrt(mnvBody:mu / tgtSMA) * (1 - sqrt((2 * stSMA) / (tgtSMA + stSMA))).
    return dv.
}


global function get_dv_for_retrograde {
    parameter tgtAlt,
              stAlt,
              mnvBody is ship:body.

    //semi-major axis 
    local tgtSMA is tgtAlt + mnvBody:radius.
    local stSMA is stAlt + mnvBody:radius.

    //Return dv
    local dv to sqrt(mnvBody:mu / stSMA) * ( sqrt( (2 * tgtSMA) / (stSMA + tgtSMA)) - 1).
    return dv.
}


global function dv_for_hohmann_transfer {
    parameter tgtObt,
              stObt.

    local r1 is stObt:semimajoraxis.
    local r2 is tgtObt:semimajoraxis.

    local dv to sqrt(stObt:body:mu / r1) * (sqrt((2 * r2) / r1 + r2) - 1). 

    return dv.
}


global function dv_for_hohmann_arrival {
    parameter tgtObt,
              stObt.

    local r1 is stObt:semimajoraxis.
    local r2 is tgtObt:semimajoraxis.

    local dv to sqrt(stObt:body:mu / r2) * (1 - sqrt((2 * r1) / (r1 + r1))).
}


global function get_dv_for_transfer {
    parameter tgtObt,
              stObt.

    local vIA is sqrt( stObt:body:mu / stObt:periapsis + stObt:body:radius).
    local vTXA is sqrt( stObt:body:mu / ( ( 2 / stObt:periapsis + stObt:body:radius) - ( 1 / ( stObt:periapsis + stObt:body:radius + tgtObt:apoapsis + tgtObt:body:radius)))).

    local dv to vTXA - vIA.

    return dv.
}


global function get_dv_for_capture {
    parameter tgtObt,
              stObt.

    //semi-major axis 
    local tgtSMA is tgtObt:semimajoraxis.
    local stSMA is stObt:semimajoraxis.

    //Return dv
    local dv to ((sqrt(stObt:body:mu / stSMA)) * ( sqrt((2 * tgtSMA) / (stSMA + tgtSMA)) - 1)).
    return dv.
}


global function get_dv_for_tgt_transfer {

    //semi-major axis
    local tgtSMA to target:orbit:semimajoraxis.
    local stSMA to ship:periapsis + ship:body:radius.
    
    //Return dv
    return ((sqrt(ship:body:mu / stSMA)) * ( sqrt((2 * tgtSMA) / (stSMA + tgtSMA)) - 1)).
}


global function get_dv_for_tgt_transfer_next {

    //semi-major axis
    local tgtSMA to target:orbit:semimajoraxis.
    local stSMA to ship:obt:semimajoraxis.
    
    //Return dv
    return ((sqrt(ship:body:mu / stSMA)) * ( sqrt((2 * tgtSMA) / (stSMA + tgtSMA)) - 1)).
}



global function get_avail_dv_for_stage {
    parameter stg is stage:number.

    logStr("[get_avail_dv_for_stage] stg:" + stg).

    //Get all parts on the ship at the stage. Discards parts not on vessel by time supplied stage is triggered
    local vMass to get_ves_mass_at_stage(stg).
    local eList is ship:partsTaggedPattern("eng.stgId:" + stg).
    if eList:length = 0 {
        set stg to stg - 1.
        set eList to ship:partsTaggedPattern("eng.stgId:" + stg). 
        if eList = 0 {
            logStr("[get_avail_dv_for_stage]-> return: -1"). 
            return -1.
        }
    }
    
    local exhVel is get_engs_exh_vel(eList, ship:altitude).
    local stgMassObj to get_stage_mass_obj(stg).

    local fuelMass to stgMassObj["cur"] - stgMassObj["dry"].
    local spentMass to vMass - fuelMass.
    
    logStr("[get_avail_dv_for_stage]-> return: " + exhVel * ln(vMass / spentMass)).
    return exhVel * ln(vMass / spentMass).
}


global function get_rcs_dv_at_stage {
    parameter stg is stage:number.

    logStr("get_avail_monoprop_dv_at_stage [stg:" + stg + "]").

    local avgExhVel to 0.

    local vMass to get_ves_mass_at_stage(stg).
    local mpList is ship:partsTaggedPattern("ctrl.rcs").
    if mpList:length = 0 {
        return 0.
    }

    for p in mpList {
        local pStg to utils:stgFromTag(p).
        if pStg <= stg {
            local rcsObj to rcs_obj(p).
            set avgExhVel to avgExhVel + (constant:g0 * rcsObj["rcs isp"]) / 2.
        }
    }

    local fuelMass to get_res_mass_for_stg(stg, "MonoPropellant").
    local spentMass to vMass - fuelMass.
    // logStr("exhVel: return: " + avgExhVel * ln(vMass / spentMass)).

    return avgExhVel * ln(vMass / spentMass).
}


// Returns an object representing the number of stages involved 
// in a specific deltaV amount, beginning with either the current
// stage or a provided one.
global function get_stages_for_dv {
    parameter _deltaV,                      // Amount of dv needed
              _stageNum is stage:number.    // Stage to start with

    logStr("[get_stages_for_dv] _dV: " + _deltaV + ";  _stageNum: " + _stageNum).

    // The object we'll store the result in
    local stageObj is lex().

    // Make dv absolute
    set _deltaV to abs(_deltaV).

    // Loop until either the needed DeltaV is accounted for, or
    // we run out of stages
    until _deltaV <= 0 or _stageNum <= -1 {
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