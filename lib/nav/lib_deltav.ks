//lib for  deltaV calculations
@LazyGlobal off.

RunOncePath("0:/lib/lib_core").
RunOncePath("0:/lib/lib_mass_data").
RunOncePath("0:/lib/lib_engine_data").


RunOncePath("0:/lib/part/lib_rcs").

//functions
global function GetDVForPrograde {
    parameter _targetAlt,
              _startAlt,
              _maneuverBody is ship:Body.

    //semi-major axis 
    local targetSMA to _targetAlt + _maneuverBody:Radius.
    local startSMA  to _startAlt  + _maneuverBody:Radius.

    //Return dv
    local dV to sqrt(_maneuverBody:mu / targetSMA) * (1 - sqrt((2 * startSMA) / (targetSMA + startSMA))).
    return dV.
}


global function GetDVForRetrograde {
    parameter _targetAlt,
              _startAlt,
              _maneuverBody is ship:Body.

    //semi-major axis 
    local targetSMA is _targetAlt + _maneuverBody:Radius.
    local startSMA  is _startAlt + _maneuverBody:Radius.

    //Return dv
    local dV to sqrt(_maneuverBody:mu / startSMA) * ( sqrt( (2 * targetSMA) / (startSMA + targetSMA)) - 1).
    return dV.
}


global function GetDVForHohmannTransfer {
    parameter _targetOrbit,
              _startOrbit.

    local startSMA  to _startOrbit:semimajoraxis.
    local targetSMA to _targetOrbit:semimajoraxis.

    local dv to sqrt(_startOrbit:Body:mu / startSMA) * (sqrt((2 * targetSMA) / startSMA + targetSMA) - 1). 

    return dv.
}


global function GetDVForHohmannArrival {
    parameter _targetOrbit,
              _startOrbit.

    local startSMA  to _startOrbit:semimajoraxis.
    local targetSMA to _targetOrbit:semimajoraxis.
    
    local dv to sqrt(_startOrbit:Body:mu / targetSMA) * (1 - sqrt((2 * startSMA) / (startSMA + startSMA))).

    return dv.
}


global function GetDVForTransfer {
    parameter _targetOrbit,
              _startOrbit.

    local vIA  to sqrt( _startOrbit:Body:mu / _startOrbit:periapsis + _startOrbit:body:radius).
    local vTXA to sqrt( _startOrbit:Body:mu / ( ( 2 / _startOrbit:periapsis + _startOrbit:body:radius) - ( 1 / ( _startOrbit:periapsis + _startOrbit:body:radius + _targetOrbit:apoapsis + _targetOrbit:body:radius)))).

    local dv to vTXA - vIA.

    return dv.
}


global function GetDVForCapture {
    parameter _targetOrbit,
              _startOrbit.

    //semi-major axis 
    local startSMA  to _startOrbit:semimajoraxis.
    local targetSMA to _targetOrbit:semimajoraxis.

    //Return dv
    return ((sqrt(_startOrbit:Body:mu / startSMA)) * ( sqrt((2 * targetSMA) / (startSMA + targetSMA)) - 1)).
}


global function GetDVForTargetTransfer {

    //semi-major axis
    local startSMA  to ship:apoapsis + ship:body:Radius.
    local targetSMA to target:orbit:semimajoraxis.
    
    //Return dv
    return ((sqrt(ship:Body:mu / startSMA)) * ( sqrt((2 * targetSMA) / (startSMA + targetSMA)) - 1)).
}


global function GetDVForTargetTransfer_Next {

    //semi-major axis
    local startSMA  to ship:Orbit:SemiMajorAxis.
    local targetSMA to target:Orbit:SemiMajorAxis.
    
    //Return dv
    return ((sqrt(ship:Body:mu / startSMA)) * ( sqrt((2 * targetSMA) / (startSMA + targetSMA)) - 1)).
}



global function GetAvailabeDVForStage {
    parameter _stage is stage:Number.

    if verbose logStr("[GetAvailableDVForStage] _stg:" + _stage).

    //Get all parts on the ship at the stage. Discards parts not on vessel by time supplied stage is triggered
    local engList is ship:partsTaggedPattern("eng.stgId:" + _stage).
    if engList:length = 0 { 
        if verbose logStr("[GetAvailableDVForStage]-> return 0. No engines in provided stage").
        return 0.
        }
    
    local shipMass          to get_ves_mass_at_stage(_stage).
    local exhaustVelocity   to get_engs_exh_vel(engList, ship:altitude).
    local stageMassObj      to get_stage_mass_obj(_stage).

    local fuelMass   to stageMassObj["cur"] - stageMassObj["dry"].
    local spentMass  to shipMass - fuelMass.
    
    if verbose logStr("[GetAvailableDVForStage]-> return: " + exhaustVelocity * ln(shipMass / spentMass)).
    
    return exhaustVelocity * ln(shipMass / spentMass).
}


global function GetRcsDvAtStage {
    parameter _stageNum is stage:number.

    if verbose logStr("[rcs_dv_at_stage] _stg:" + _stageNum).

    local avgExhaustVelocity to 0.

    local shipMass to get_ves_mass_at_stage(_stageNum).
    local rcsList  to ship:PartsTaggedPattern("ctrl.rcs").
    if rcsList:length = 0 {
        return 0.
    }

    for p in rcsList {
        local pStage to utils:stgFromTag(p).
        if pStage <= _stageNum {
            local rcsObj to rcs_obj(p).
            set avgExhaustVelocity to avgExhaustVelocity + (constant:g0 * rcsObj["rcs isp"]) / 2.
        }
    }

    local fuelMass  to get_res_mass_for_stg(_stageNum, "MonoPropellant").
    local spentMass to shipMass - fuelMass.
    local rcsDv     to avgExhaustVelocity * ln(shipMass / spentMass).

    if verbose logStr("[rcs_dv_at_stage]-> return : " + rcsDv).

    return rcsDv.
}


// Returns an object representing the number of stages involved 
// in a specific deltaV amount, beginning with either the current
// stage or a provided one.
global function GetStagesForDv {
    parameter _dV,                      // Amount of dv needed
              _stageNum is stage:number.    // Stage to start with

    if verbose logStr("[get_stages_for_dv] _dV: " + _dV + ";  _stageNum: " + _stageNum).

    // The object we'll store the result in
    local stageObj is lex().

    // Make dv absolute
    set _dV to abs(_dV).

    // Loop until either the needed DeltaV is accounted for, or
    // we run out of stages
    until _dV <= 0 or _stageNum < -1 {
        // Get the deltaV possible for the stage we are on
        local dvStg is GetAvailabeDVForStage(_stageNum).

        // If the deltaV needed is less than what the stage can 
        // deliver, then add the stage number we checked to the 
        // object and break the loop
        if _dV < dvStg {
            set stageObj[_stageNum] to round(_dV, 2).
            break.

        } else {

            // If there is deltaV available in the stage we are
            // checking, add that stage to the stage object. Then,
            // subtract that total from the needed deltaV. If that
            // puts us below zero, loop will exit
            if dvStg > 0 {
                set stageObj[_stageNum] to round(dvStg, 2).
                set _dV to _dV - dvStg.
            }

            // Get the next stage that has engines. This is if the 
            // previous stage did not already cover what we needed
            set _stageNum to _stageNum - 1.
            //set _stageNum to get_next_stage_with_eng(_stageNum).
        }
    }

    if verbose logStr("[get_stages_for_dv]-> return: " + stageObj).

    // DeltaV for each stage needed to execute the burn
    return stageObj.
}