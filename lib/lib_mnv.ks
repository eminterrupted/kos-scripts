@lazyGlobal off.

// Functions for orbital maneuvers

// Dependencies
runOncePath("0:/lib/lib_vessel").
runOncePath("0:/lib/lib_nav").
runOncePath("0:/lib/lib_util").
runOncePath("0:/kslib/lib_navball").
//runOncePath("0:/kslib/lib_navigation").

//#region -- dv Calculations
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
    parameter stAlt,
              tgtAlt,
              mnvBody is ship:body.

    // Calculate semi-major axis
    local stSMA  to stAlt  + mnvBody:radius.
    local tgtSMA to tgtAlt + mnvBody:radius.

    local dv1 to sqrt(mnvBody:mu / stSMA) * (sqrt((2 * tgtSMA) / (tgtSMA + stSMA)) - 1).
    local dv2 to sqrt(mnvBody:mu / tgtSMA) * (1 - sqrt((2 * stSMA) / (stSMA + tgtSMA))).
    return list(dv1, dv2).
}

// dV for hohmann transfer based on start & end ap/pe
global function mnv_dv_hohmann_velocity
{
    parameter stPe,
              tgtPe,
              tgtAp,
              mnvBody is ship:body.

    local smaTrnsfr to nav_sma(stPe, tgtAp, mnvBody).
    local smaTgt    to nav_sma(tgtPe, tgtAp, mnvBody).

    print "smaTrnsfr    : " + round(smaTrnsfr) at (2, 31).
    print "smaTgt       : " + round(smaTgt) at (2, 32).

    local vPark     to velocityAt(ship, time:seconds + eta:periapsis).
    print "vPark        : " + round(vPark, 2) at (2, 34).
    local vTrnsfrDep   to nav_transfer_velocity(stPe, smaTrnsfr, mnvBody).
    print "vTrnsfrDep   : " + round(vTrnsfrDep, 2) at (2, 35).
    local vTrnsfrArr   to nav_transfer_velocity(tgtAp, smaTrnsfr, mnvBody).
    print "vTrnsfrArr   : " + round(vTrnsfrArr, 2) at (2, 36).
    local vTgt      to nav_transfer_velocity(tgtAp, smaTgt, mnvBody).
    print "vTgt         : " + round(vTgt, 2) at (2, 37).

    // [0]: transfer dV, [1] circ dV
    return list(vTrnsfrDep - vPark, vTgt - vTrnsfrArr).
}

// dV for hohmann transfer maneuver based on sample orbits and a given true anomaly
global function mnv_dv_hohmann_orbit
{
    parameter inOrbit,
              tgtOrbit,
              tgtAnomaly.

    // Altitudes at time of departure
    local peAtTA        to nav_obt_alt_at_ta(inOrbit, tgtAnomaly).
    local apAtTA        to nav_obt_alt_at_ta(inOrbit, tgtAnomaly + 180).

    // dv for departure and arrival
    local dvDep to mnv_dv_hohmann(apAtTa, tgtOrbit:apoapsis, ship:body)[0].
    local dvArr to mnv_dv_hohmann(peAtTA, tgtOrbit:periapsis, ship:body)[1].

    // [0]: transfer dV, [1] circ dV
    return list(dvDep, dvArr).
}

// dV for a hohmann maneuver based on velocity change
global function mnv_dv_hohmann_orbit_velocity
{
    parameter inOrbit,
              tgtOrbit,
              tgtAnomaly,
              mnvBody is ship:body.

    local shipAltAtTA   to nav_obt_alt_at_ta(inOrbit, tgtAnomaly).
    local trnsfrSMA to nav_sma(shipAltAtTA, tgtOrbit:apoapsis, mnvBody).
    local tgtSMA    to nav_sma(tgtOrbit:periapsis, tgtOrbit:apoapsis, mnvBody).

    local vStart    to nav_velocity_at_ta(ship, inOrbit, tgtAnomaly).
    local vTrDepart to nav_transfer_velocity(shipAltAtTA + mnvBody:radius, trnsfrSMA, mnvBody).
    local vTrArrive to nav_transfer_velocity(tgtOrbit:apoapsis + mnvBody:radius, trnsfrSMA, mnvBody).
    local vTarget   to nav_transfer_velocity(tgtOrbit:apoapsis + mnvBody:radius, tgtSMA, mnvBody).
    
    print "vStart   : " + round(vStart, 2) at (2, 15).
    print "vTrDepart: " + round(vTrDepart, 2) at (2, 16).
    print "vTrArrive: " + round(vTrArrive, 2) at (2, 17).
    print "vTarget  : " + round(vTarget, 2) at (2, 18).

    return list(vTrDepart - vStart, vTarget - vTrArrive).
}
//#endregion

//#region -- Burn stage and duration calc
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
        //return 1 / 0.
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
              tgtObt.   // target orbit to match

    // Normals
    local ves_nrm is nav_obt_normal(burnVes:obt).
    local tgt_nrm is nav_obt_normal(tgtObt).

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
    local burn_utc is nav_eta_to_ta(burnVes:obt, node_ta).
    
    // Get the burn unit direction (burnvector direction)
    local burn_unit is (ves_nrm + tgt_nrm):normalized.

    // Get deltav / burnvector magnitude
    local vel_at_eta is velocityAt(burnVes, burn_utc):orbit.
    local burn_mag is -2 * vel_at_eta:mag * cos(vang(vel_at_eta, burn_unit)).
    
    // Get the dV components for creating the node structure
    local burn_nrm to burn_mag * cos(d_inc / 2).
    local burn_pro to 0 - abs(burn_mag * sin( d_inc / 2)).

    // Create the node struct
    local mnv_node to node(burn_utc, 0, burn_nrm, burn_pro).
    
    return list(burn_utc, burn_mag * burn_unit, mnv_node, burn_mag, burn_unit).
}
//#endregion

//-- Actions (executing maneuvers)
//Simple burn emnv_exec_circ_burn facing either prograde or retrograde
global function mnv_exec_circ_burn
{
    parameter dv,
              mnvTime,
              burnEta,
              burnDur.

    //local lastDv      to 999999.
    local mecoTS      to burnEta + burnDur.
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
        mnv_burn_disp(burnEta, dvRemaining, burnDur).
    }

    set tVal to 1.
    disp_msg("Executing burn").
    until dvRemaining <= 0.1
    {
        set burnDir to choose compass_for(ship, ship:prograde) if dv > 0 else compass_for(ship, ship:retrograde).
        set sVal to heading(burnDir, 0, 0).
        mnv_burn_disp(burnEta, dvRemaining, mecoTS - time:seconds).
    }

    // until dvRemaining <= 0.1 or dvRemaining > lastDv
    // {
    //     set lastDv to dvRemaining.
    //     set burnDir to choose compass_for(ship, ship:prograde) if dv > 0 else compass_for(ship, ship:retrograde).
    //     set sVal to heading(burnDir, 0, 0).
    //     set tVal to dvRemaining / 10.
    //     mnv_burn_disp(burnEta, dvRemaining, mecoTS - time:seconds).
    // }
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
              mnvETA.

    local burnDuration  to (mnvTime - mnvETA) * 2.
    local mecoTS        to mnvETA + burnDuration.
    local dvToGo        to abs(mnvVec:mag).
    local startVel      to 0.
        
    local sVal    to mnvVec.
    local tVal    to 0.
    lock steering to sVal.
    lock throttle to tVal.


    util_warp_trigger(mnvETA - 30).

    until time:seconds >= mnvETA
    {
        set sVal to mnvVec.
        mnv_burn_disp(mnvETA, dvToGo, burnDuration).
        wait 0.01.
    }

    set sVal to mnvVec.
    set tVal to 1.
    set startVel to ship:velocity:orbit.
    clearVecDraws().
    disp_msg("Executing burn                               ").
    until dvToGo <= 0.1
    {
        //set dvLast to dvToGo.
        set dvToGo to mnvVec:mag - sqrt(abs(vdot(mnvVec, (ship:velocity:orbit - startVel)))).
        if dvToGo < 10 
        { 
            set tVal to max(0, min(1, dvToGo / 10)). 
        } 
        mnv_burn_disp(mnvETA, dvToGo, mecoTS - time:seconds).
        wait 0.01.
    }
    set tVal to 0.
    
    disp_msg("Maneuver complete!  ").
    disp_info().
    disp_info2().
    disp_msg().
}

global function mnv_exec_node_burn
{
    parameter mnvNode,
              burnEta,
              burnDur.

    local mecoTS       to burnEta + burnDur.
    lock dvRemaining   to abs(mnvNode:burnVector:mag).
    
    local tVal    to 0.
    lock steering to mnvNode:burnVector.
    lock throttle to tVal.

    util_warp_trigger(burnEta - 30).

    until time:seconds >= burnEta
    {
        mnv_burn_disp(burnEta, dvRemaining, burnDur).
    }

    set tVal to 1.
    disp_msg("Executing burn").
    until dvRemaining <= 10
    {
        mnv_burn_disp(burnEta, dvRemaining, mecoTS - time:seconds).
    }

    until dvRemaining <= 0.125
    {
        set tVal to dvRemaining / 10.
        mnv_burn_disp(burnEta, dvRemaining, mecoTS - time:seconds).
    }
    set tVal to 0.

    disp_msg("Maneuver complete!").
    disp_info().
    disp_info2().
    wait 1.
    disp_msg().
    unlock steering.
    remove mnvNode.
}


//-- Disp
global function mnv_burn_disp
{
    parameter burnEta, dvToGo is 0, burnDuration is 0.

    if time:seconds - burnEta < 0 
    {
        disp_info("Burn ETA: " + round(time:seconds - burnEta, 2)).
    }
    else if dvToGo <> 0 
    {
        disp_info("DeltaV Remaining: " + round(dvToGo, 2)). 
    }
    disp_info2("Duration Remaining: " + round(burnDuration, 2)).
}