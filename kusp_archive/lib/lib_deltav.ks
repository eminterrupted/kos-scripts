//lib for  deltaV calculations
@lazyGlobal off.

runOncePath("0:/lib/lib_core").
runOncePath("0:/lib/lib_mass_data").
runOncePath("0:/lib/lib_engine").


runOncePath("0:/lib/lib_rcs").

//functions
global function get_dv_for_prograde 
{
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


global function get_dv_for_retrograde 
{
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


global function dv_for_hohmann_transfer 
{
    parameter tgtObt,
              stObt.

    local r1 is stObt:semimajoraxis.
    local r2 is tgtObt:semimajoraxis.

    local dv to sqrt(stObt:body:mu / r1) * (sqrt((2 * r2) / r1 + r2) - 1). 

    return dv.
}


global function dv_for_hohmann_arrival 
{
    parameter tgtObt,
              stObt.

    local r1 is stObt:semimajoraxis.
    local r2 is tgtObt:semimajoraxis.

    local dv to sqrt(stObt:body:mu / r2) * (1 - sqrt((2 * r1) / (r1 + r1))).

    return dv.
}


global function get_dv_for_transfer 
{
    parameter tgtObt,
              stObt.

    local vIA is sqrt( stObt:body:mu / stObt:periapsis + stObt:body:radius).
    local vTXA is sqrt( stObt:body:mu / ( ( 2 / stObt:periapsis + stObt:body:radius) - ( 1 / ( stObt:periapsis + stObt:body:radius + tgtObt:apoapsis + tgtObt:body:radius)))).

    local dv to vTXA - vIA.

    return dv.
}


global function get_dv_for_capture 
{
    parameter tgtObt,
              stObt.

    //semi-major axis 
    local tgtSMA is tgtObt:semimajoraxis.
    local stSMA is stObt:semimajoraxis.

    //Return dv
    return ((sqrt(stObt:body:mu / stSMA)) * ( sqrt((2 * tgtSMA) / (stSMA + tgtSMA)) - 1)).
}


//Assumes a target is selected
global function get_dv_for_tgt_transfer 
{
    //semi-major axis
    local tgtSMA to target:orbit:semimajoraxis.
    local stSMA to ship:apoapsis + ship:body:radius.
    
    //Return dv
    return ((sqrt(ship:body:mu / stSMA)) * ( sqrt((2 * tgtSMA) / (stSMA + tgtSMA)) - 1)).
}


global function get_dv_for_tgt_transfer_next 
{
    //semi-major axis
    local tgtSMA to target:orbit:semimajoraxis.
    local stSMA to ship:obt:semimajoraxis.
    
    //Return dv
    return ((sqrt(ship:body:mu / stSMA)) * ( sqrt((2 * tgtSMA) / (stSMA + tgtSMA)) - 1)).
}


//Version of get_avail_dv_for_stage that uses built-in dV calc
global function get_avail_dv_for_stage_next 
{
    parameter stgNum is stage:number.

    if verbose logStr("[get_avail_dv_for_stage_next] stgNum:" + stgNum).
    local dv to ship:stageDeltaV(stgNum):current.
    if verbose logStr("[get_avail_dv_for_stage_next]-> return: " + round(dv, 2)).
    return dv.
}


global function get_avail_dv_for_stage 
{
    parameter stgNum is stage:number.

    if verbose logStr("[get_avail_dv_for_stage] stgNum:" + stgNum).

    //Get all parts on the ship at the stage. Discards parts not on vessel by time supplied stage is triggered
    local eList is ship:partsTaggedPattern("eng.stgId:" + stgNum).
    if eList:length = 0 
    { 
        if verbose logStr("[get_avail_dv_for_stage]-> return 0. No engines in provided stage").
        return 0.
    }
    
    local vMass to get_ves_mass_at_stage(stgNum).
    local exhVel is get_engs_exh_vel(eList, ship:altitude).
    local stgMassObj to get_stage_mass_obj(stgNum).

    local fuelMass to stgMassObj["cur"] - stgMassObj["dry"].
    local spentMass to vMass - fuelMass.
    
    if verbose logStr("[get_avail_dv_for_stage]-> return: " + exhVel * ln(vMass / spentMass)).
    return exhVel * ln(vMass / spentMass).
}


global function rcs_dv_at_stage 
{
    parameter stgNum is stage:number.

    if verbose logStr("[rcs_dv_at_stage] stgNum:" + stgNum).

    local avgExhVel to 0.

    local vMass to get_ves_mass_at_stage(stgNum).
    local mpList is ship:partsTaggedPattern("ctrl.rcs").
    if mpList:length = 0 
    {
        return 0.
    }

    for p in mpList 
    {
        local pStg to utils:stgFromTag(p).
        if pStg <= stgNum 
        {
            local rcsObj to rcs_obj(p).
            set avgExhVel to avgExhVel + (constant:g0 * rcsObj["rcs isp"]) / 2.
        }
    }

    local fuelMass to get_res_mass_for_stg(stgNum, "MonoPropellant").
    local spentMass to vMass - fuelMass.
    local rcsDv to avgExhVel * ln(vMass / spentMass).

    if verbose logStr("[rcs_dv_at_stage]-> return : " + rcsDv).

    return rcsDv.
}

// Version of get_stages_for_dv_next using built-in DV calc
global function get_stages_for_dv_next 
{
    parameter dvNeeded,
              stgNum is stage:number.

    if verbose logStr("[get_stages_for_dv_next] dvNeeded: " + dvNeeded + ";  stgNum: " + stgNum).
    
    local stgObj to lex().
    set dvNeeded to abs(dvNeeded).
    until dvNeeded <= 0 or stgNum < -1 
    {
        local dvStg to ship:stageDeltaV(stgNum):current.

        if dvNeeded < dvStg 
        {
            set stgObj[stgNum] to dvNeeded.
            break.

        } 
        else 
        {
            if dvStg > 0 
            {
                set stgObj[stgNum] to dvStg.
                set dvNeeded to dvNeeded - dvStg.
            }
            set stgNum to stgNum - 1.
        }
    }
    
    if verbose logStr("[get_stages_for_dv_next]-> return: " + stgObj).
    return stgObj.
}



// Returns an object representing the number of stages involved 
// in a specific deltaV amount, beginning with either the current
// stage or a provided one.
global function get_stages_for_dv 
{
    parameter dvNeeded,                      // Amount of dv needed
              stgNum is stage:number.    // Stage to start with

    if verbose logStr("[get_stages_for_dv] dvNeeded: " + dvNeeded + ";  _stgNum: " + stgNum).

    // The object we'll store the result in
    local stageObj is lex().

    // Make dv absolute
    set dvNeeded to abs(dvNeeded).

    // Loop until either the needed DeltaV is accounted for, or
    // we run out of stages
    until dvNeeded <= 0 or stgNum < -1 
    {
        // Get the deltaV possible for the stage we are on
        local dvStg is get_avail_dv_for_stage(stgNum).

        // If the deltaV needed is less than what the stage can 
        // deliver, then add the stage number we checked to the 
        // object and break the loop
        if dvNeeded < dvStg {
            set stageObj[stgNum] to dvNeeded.
            break.
        } 
        else 
        {
            // If there is deltaV available in the stage we are
            // checking, add that stage to the stage object. Then,
            // subtract that total from the needed deltaV. If that
            // puts us below zero, loop will exit
            if dvStg > 0 
            {
                set stageObj[stgNum] to dvStg.
                set dvNeeded to dvNeeded - dvStg.
            }

            // Get the next stage that has engines. This is if the 
            // previous stage did not already cover what we needed
            set stgNum to stgNum - 1.
            //set _stageNum to get_next_stage_with_eng(_stageNum).
        }
    }

    if verbose logStr("[get_stages_for_dv]-> return: " + stageObj).

    // DeltaV for each stage needed to execute the burn
    return stageObj.
}