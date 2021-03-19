@lazyGlobal off.

// Functions for orbital maneuvers

// Dependencies
runOncePath("0:/lib/lib_vessel").
runOncePath("0:/lib/lib_nav").
runOncePath("0:/lib/lib_util").
runOncePath("0:/kslib/lib_navball").
runOncePath("0:/kslib/lib_navigation").

//#region -- Burn Calculations
// Returns an object of burn duration calculations based on dv 
// and mnvTimestamp input
global function mnv_burn_times
{
    parameter dvNeeded,
              mnvTime.

    local burnDur to mnv_burn_dur(dvNeeded).
    local burnEta to mnvTime - mnv_burn_dur(dvNeeded / 2).
    return list(burnEta, burnDur).
}

// dV calculations
global function mnv_dv_hohmann
{
    parameter tgtAlt,
              stAlt,
              mnvBody is ship:body.

    // Calculate semi-major axis
    local tgtSMA to tgtAlt + mnvBody:radius.
    local stSMA  to stAlt  + mnvBody:radius.

    local dv1 to sqrt(mnvBody:mu / stSMA) * (sqrt((2 * tgtSMA) / (tgtSMA + stSMA)) - 1).
    local dv2 to sqrt(mnvBody:mu / tgtSMA) * (1 - sqrt((2 * stSMA) / (stSMA + tgtSMA))).
    return list(dv1, dv2).
}

// New way of calculating dv for a hohmann transfer maneuver
global function mnv_dv_hohmann_vnext
{
    parameter stAp,
              stPe,
              tgtAp,
              tgtPe,
              mnvBody is ship:body.

    local smaPark   to nav_sma(stPe, stAp, mnvBody).
    local smaTrnsfr to nav_sma(stPe, tgtAp, mnvBody).
    local smaTgt    to nav_sma(tgtPe, tgtAp, mnvBody).

    local vPark     to mnv_velocity(smaPark, smaPark, mnvBody).
    local vTrnsfr   to mnv_velocity(smaPark, smaTrnsfr, mnvBody).
    local vTgt      to mnv_velocity(smaTgt, smaTgt, mnvBody).

    print "vPark   : " + vPark at (2, 25).
    print "vTrnsfr : " + vTrnsfr at (2, 26).
    print "vTgt    : " + vTgt at (2, 27).

    // [0]: transfer dV, [1] circ dV
    local dv to list(vPark - vTrnsfr, vTgt - vTrnsfr).
    return dv.
}

global function mnv_velocity
{
    parameter stSma,
              tgtSma,
              mnvBody is ship:body.

    return sqrt((constant:g * mnvBody:mass) * ((2 / tgtSma) - (1 / stSma))).
}

// Calculates stages used for a given dv burn. Assumes that the burn starts 
// with the current stage. Returns a lexicon containing stage num and dv per 
// stage. Used with the mnv_burn_dur function
global function mnv_burn_stages
{
    parameter dvNeeded.

    local dvStgObj to lex().
    set dvNeeded to abs(dvNeeded).

    // If we need more dV than the vessel has, throw an exception.
    if dvNeeded > ship:deltaV:current {
        hudText("dV Needed: " + dvNeeded + ". Not enough deltaV on vessel!", 10, 2, 24, red, false).
        return 1 / 0.
    }

    // Iterate over stages until dv is covered
    from { local stg to stage:number.} until dvNeeded <= 0 step { set stg to stg - 1.} do
    {
        local dvStg to ship:stageDeltaV(stg):current.
        if dvStg > 0 
        {
            if dvNeeded <= dvStg
            {
                set dvStgObj[stg] to dvNeeded.
                break.
            }
            else 
            {
                set dvStgObj[stg] to dvStg.
                set dvNeeded to dvNeeded - dvStg.
            }
        }
    }
    return dvStgObj.
}

// Total duration to burn provided dv
global function mnv_burn_dur
{
    parameter dvNeeded.
   
    // Get the amount of dv in each stage
    local dvStgObj  to mnv_burn_stages(dvNeeded).
    local dvBurnObj to mnv_burn_dur_stage(dvStgObj).
    return dvBurnObj["all"].
}

// Given an object containing a list of stages and dv to burn for each stage,
// returns an object of burn duration by stage, plus an "all" key with the 
// total duration of the burn across all stages
global function mnv_burn_dur_stage
{
    parameter dvStgObj.

    local dvBurnObj to lex().
    set dvBurnObj["all"] to 0.

    for key in dvStgObj:keys
    {
        local exhVel    to ves_stage_exh_vel(key).
        local stgThr    to ves_stage_thrust(key).
        local vesMass   to ves_mass_at_stage(key).

        local stgBurDur     to ((vesMass * exhVel) / stgThr) * (1 - (constant:e ^ (-1 * (dvStgObj[key] / exhVel)))).
        set dvBurnObj[key]  to stgBurDur.
        set dvBurnObj["all"] to dvBurnObj["all"] + stgBurDur.
    }
    return dvBurnObj.
}

// Return an object containing all parameters needed for a maneuver
// to change inclination from orbit 0 to orbit 1. Returns a list:
// - [0] (nodeAt)     - center of burn node
// - [1] (burnVector) - dV vector including direction and mag
// - [2] (nodeStruc)  - A maneuver node structure for this burn
global function mnv_inc_match_burn 
{
    parameter burnVes,  // Vessel that will perform the burn
              tgtObt. // target orbit to match

    // Normals
    local ves_nrm is ksnav_obt_normal(burnVes:obt).
    local tgt_nrm is ksnav_obt_normal(tgtObt).

    // Total inclination change
    local d_inc is vang(ves_nrm, tgt_nrm).

    // True anomaly of ascending node
    local node_ta is nav_asc_node_ta(burnVes:obt, tgtObt).


    // Pick whichever node of AN or DN is higher in altitude,
    // and thus more efficient. node_ta is AN, so if it's 
    // closest to Pe, then use DN 
    if node_ta < 90 or node_ta > 270 
    {
        set node_ta to mod(node_ta + 180, 360).
    }

    // Get the burn eta
    local burn_eta is nav_eta_to_ta(burnVes:obt, node_ta).
    local burn_utc is time:seconds + burn_eta.

    // Get the burn unit direction (burnvector direction)
    local burn_unit is (ves_nrm + tgt_nrm):normalized.

    // Get deltav / burnvector magnitude
    local vel_at_eta is velocityAt(burnVes, burn_utc):orbit.
    local burn_mag is -2 * vel_at_eta:mag * cos(vang(vel_at_eta, burn_unit)).
    
    // // Get the dV components for creating the node structure
    // local burn_nrm to burn_mag * cos(d_inc / 2).
    // local burn_pro to 0 - abs(burn_mag * sin( d_inc / 2)).

    // // Create the node struct
    // local mnv_node to node(burn_utc, 0, burn_nrm, burn_pro).

    //return list(burn_utc, burn_mag * burn_unit, mnv_node, burn_mag, burn_unit).
    return list(burn_utc, burn_mag * burn_unit).
}
//#endregion

//-- Actions (executing maneuvers)
//Simple burn emnv_exec_circ_burn facing either prograde or retrograde
global function mnv_exec_circ_burn
{
    parameter dv,
              mnvTime,
              burnEta.

    local burnDuration to (mnvTime - burnEta) * 2.
    local mecoTS      to burnEta + burnDuration.
    local dvRemaining to 0.
    local tgtVelocity to velocityAt(ship, mnvTime):orbit:mag + dv.
    lock  dvRemaining to abs(tgtVelocity - ship:velocity:orbit:mag).
    
    local burnDir to choose compass_for(ship, ship:prograde) if dv > 0 else compass_for(ship, ship:retrograde).
    local sVal    to ship:prograde.
    local tVal    to 0.
    lock steering to sVal.
    lock throttle to tVal.

    util_warp_trigger(burnEta - 30).

    until time:seconds >= burnEta
    {
        set burnDir to choose compass_for(ship, ship:prograde) if dv > 0 else compass_for(ship, ship:retrograde).
        set sVal to heading(burnDir, 0, 0).
        mnv_burn_disp(burnEta, dvRemaining, burnDuration).
    }

    set tVal to 1.
    disp_msg("Executing burn").
    until dvRemaining <= 10
    {
        set burnDir to choose compass_for(ship, ship:prograde) if dv > 0 else compass_for(ship, ship:retrograde).
        set sVal to heading(burnDir, 0, 0).
        mnv_burn_disp(burnEta, dvRemaining, mecoTS - time:seconds).
    }

    until dvRemaining <= 0.1
    {
        set burnDir to choose compass_for(ship, ship:prograde) if dv > 0 else compass_for(ship, ship:retrograde).
        set sVal to heading(burnDir, 0, 0).
        set tVal to dvRemaining / 10.
        mnv_burn_disp(burnEta, dvRemaining, mecoTS - time:seconds).
    }
    set tVal to 0.

    disp_msg("Maneuver complete!").
    disp_info().
    disp_info2().
    wait 1.
    disp_msg().
}

//Performs a burn given a time and vector
global function mnv_exec_vec_burn
{
    parameter mnvVec,
              mnvTime,
              burnEta.

    local burnDuration to (mnvTime - burnEta) * 2.
    local mecoTS       to burnEta + burnDuration.
    lock  dvRemaining  to mnvVec:mag.
        
    local sVal    to mnvVec.
    local tVal    to 0.
    lock steering to sVal.
    lock throttle to tVal.

    util_warp_trigger(burnEta - 30).

    until time:seconds >= burnEta
    {
        set sVal to mnvVec.
        mnv_burn_disp(burnEta, dvRemaining, burnDuration).
        wait 0.01.
    }

    set tVal to 1.
    disp_msg("Executing burn").
    until mnvVec:mag <= 10
    {
        mnv_burn_disp(burnEta, dvRemaining, mecoTS - time:seconds).
    }

    until dvRemaining <= 0.1
    {
        set tVal to dvRemaining / 10.
        mnv_burn_disp(burnEta, dvRemaining, mecoTS - time:seconds).
        //wait 0.01.
    }
    set tVal to 0.

    disp_msg("Maneuver complete!").
    disp_info().
    disp_info2().
    wait 1.
    disp_msg().
}


//-- Local helpers
local function mnv_burn_disp
{
    parameter burnEta, dvToGo is 0, burnDuration is 0.

    if time:seconds - burnEta < 0 
    {
        disp_info("Burn ETA: " + round(time:seconds - burnEta, 1)).
    }
    else if dvToGo <> 0 
    {
        disp_info("DeltaV Remaining: " + round(dvToGo, 1)). 
    }
    disp_info2("Burn Duration: " + round(burnDuration, 1)).
}