@lazyGlobal off.

// Functions for orbital maneuvers

// Dependencies
runOncePath("0:/lib/lib_vessel").
runOncePath("0:/lib/lib_nav").
runOncePath("0:/lib/lib_util").
runOncePath("0:/kslib/lib_navball").
runOncePath("0:/lib/lib_disp").
//runOncePath("0:/kslib/lib_navigation").

// Variables
local verbose to false.

// -- Misc
//#region
// Returns the last patch for a given node
global function mnv_last_patch_for_node
{
    parameter _node.

    local curPatch to _node:orbit.
    until not curPatch:hasNextPatch 
    {
        set curPatch to curPatch:nextPatch.
    }

    return curPatch.
}

// Returns the next patch for a given node if one exists
global function mnv_next_patch_for_node
{
    parameter _node.

    local curPatch to _node:orbit.
    if curPatch:hasNextPatch 
    {
        set curPatch to curPatch:nextPatch.
    }

    return curPatch.
}
//#endregion

// -- dv Calculations
//#region
// Bi-elliptic (https://en.wikipedia.org/wiki/Bi-elliptic_transfer)
// Use [1] for launch circ, or the full maneuver when r2 / r1 is 12 or higher
global function mnv_dv_bi_elliptic
{
    parameter stPe,
              stAp,
              tgtPe,
              tgtAp,
              xfrAp,
              mnvBody is ship:body.

    local dv1 to 0. // First transfer burn, boost up to xfrAp
    local dv2 to 0. // Second transfer burn at xfrAp to tgtPe
    local dv3 to 0. // Circularization to tgtAp

    // Orbiting radii for initial, target, and transfer orbits
    local r1  to stPe + mnvBody:radius.
    local r2  to tgtPe + mnvBody:radius.
    local rB  to xfrAp + mnvBody:radius.

    // Semimajor-axis for transfer 1 and 2
    local a1 to (r1 + rb) / 2.
    local a2 to (r2 + rb) / 2.

    set dv1 to sqrt(((2 * mnvBody:mu) / r1) - (mnvBody:mu / a1)) - sqrt(mnvBody:mu / r1).
    set dv2 to sqrt(((2 * mnvBody:mu) / rB) - (mnvBody:mu / a2)) - sqrt(((2 * mnvBody:mu) / rB) - (mnvBody:mu / a1)).
    set dv3 to sqrt(((2 * mnvBody:mu) / r2) - (mnvBody:mu / a2)) - sqrt(mnvBody:mu / r2).

    return list(dv1, dv2, dv3).
}

// Generic hohmann maneuver
global function mnv_dv_hohmann
{
    parameter stAlt,
              tgtAlt,
              mnvBody is ship:body,
              burnAlt is stAlt.

    // Calculate semi-major axis
    local stSMA  to (stAlt + burnAlt + (2 * mnvBody:radius)) / 2.
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

    // radii and sma
    local rTgtPe    to tgtPe + mnvBody:radius.
    local rTgtAp    to tgtAp + mnvBody:radius.

    local smaStart  to stPe + mnvBody:radius.
    local smaTgt    to tgtAp + mnvBody:radius.
    local smaTrnsfr to smaStart + smaTgt / 2.

    print "smaStart     : " + round(smaStart) at (2, 30).
    print "smaTrnsfr    : " + round(smaTrnsfr) at (2, 31).
    print "smaTgt       : " + round(smaTgt) at (2, 32).

    local vPark         to velocityAt(ship, time:seconds + eta:apoapsis):orbit:mag.
    local vTrnsfrDep    to nav_transfer_velocity(rTgtPe, smaTrnsfr, mnvBody).
    local vTrnsfrArr    to nav_transfer_velocity(rTgtAp, smaTrnsfr, mnvBody).
    local vTgt          to nav_transfer_velocity(rTgtAp, smaTgt, mnvBody).
    
    print "vPark        : " + round(vPark, 2) at (2, 34).
    print "vTrnsfrDep   : " + round(vTrnsfrDep, 2) at (2, 35).
    print "vTrnsfrArr   : " + round(vTrnsfrArr, 2) at (2, 36).
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

// -- Burn times and stage calc
//#region
// Burn duration for the active stage. Used for landing
global function mnv_active_burn_dur
{
    parameter dv.

    local engStats to ves_active_engines_stats(). 
    
    local f to engStats[1] * 1000.  // Thrust in newtons
    local m to ship:mass * 1000.    // Vessel mass
    local e to constant():e.        // 
    local p to engStats[2].         // Average ISP
    local g to ((ship:body:mu * (ship:mass * 1000)) / (ship:body:radius + ship:altitude)^2) /  (ship:mass * 1000). // Local gravity

    return abs(g * m * p * (1 - e^(-dv / (g * p))) / f).
}

// Burn duration over multiple stages. Used for maneuver calculations
global function mnv_staged_burn_dur
{
    parameter dv.
   
    // Get the amount of dv in each stage
    local dvStgObj  to mnv_burn_stages(dv).
    // Get the duration of each stage burn to fulfill dv.
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
        //TODO: local stgEng    to ves_stage_engine_stats(key).
        local exhVel    to ves_stage_exh_vel(key).
        local stgThr    to ves_stage_thrust(key).
        local vesMass   to ves_mass_at_stage(key).

        // Multiply thrust and mass by 1000 to move from t / kn to kg / n.
        local stgBurDur     to (((vesMass * 1000) * exhVel) / (stgThr * 1000)) * (1 - (constant:e ^ (-1 * (dvStgObj[key] / exhVel)))).
        set dvBurnObj[key]  to stgBurDur.
        set dvBurnObj["all"] to dvBurnObj["all"] + stgBurDur.
    }
    return dvBurnObj.
}

// Calculates stages used for a given dv burn. Assumes that the burn starts 
// with the current stage. Returns a lexicon containing stage num and dv per 
// stage. Used with the mnv_burn_dur function
global function mnv_burn_stages
{
    parameter dv.

    local dvStgObj to lex().
    set dv to abs(dv).

    // If we need more dV than the vessel has, throw an exception.
    if ship:deltaV:current < dv 
    {
        ship:deltaV:forcecalc.
        wait 1.
    }
    if verbose
    {
        print "ship:deltaV:current: " + ship:deltaV:current at (2, 35).
    }
    if dv > ship:deltaV:current {
        hudText("dV Needed: " + round(dv, 2) + ". Not enough deltaV on vessel!", 10, 2, 24, red, false).
        return 1 / 0.
    }

    // Iterate over stages until dv is covered
    from { local stg to stage:number.} until dv <= 0 step { set stg to stg - 1.} do
    {
        
        //local dvStg to ship:stageDeltaV(stg):current.
        local dvStg to mnv_stage_dv(stg).

        if dvStg > 0 
        {
            if dv <= dvStg
            {
                set dvStgObj[stg] to dv.
                break.
            }
            else 
            {
                set dvStgObj[stg] to dvStg.
                set dv to dv - dvStg.
            }
        }
    }
    return dvStgObj.
}

// Returns a list of burn eta / duration
global function mnv_burn_times
{
    parameter dv,
              mnvTime.

    local burnDur to mnv_staged_burn_dur(dv).
    local burnEta to mnvTime - mnv_staged_burn_dur(dv / 2).
    return list(burnEta, burnDur).
}

// Returns the DV for a stage. Manual process for ship:stageDeltaV(stg)
global function mnv_stage_dv
{
    parameter stg.

    local curMass   to 0.
    local dvStg     to 0.
    local fuelMass  to 0.
    
    local allEng    to list().
    local fuelUsed  to uniqueSet().
    local stgFuel   to lex().

    local stgIsp    to ves_stage_isp(stg).
    local exhVel    to stgIsp * constant:g0.

    list engines in allEng.
    for e in allEng
    {
        if e:stage = stg 
        {
            for r in e:consumedResources:values
            {
                fuelUsed:add(r:name).
            }
        }
    }

    // Get cur / dry mass of stage
    set curMass  to ves_mass_at_stage(stg).
    set stgFuel  to ves_stage_fuel_mass(stg).
    for fuel in stgFuel:keys
    {
        if fuelUsed:contains(fuel) 
        {
            set fuelMass to fuelMass + stgFuel[fuel].
        }
    }

    set dvStg to exhVel * ln(curMass / (curMass - fuelMass)).
    return dvStg.
}
//#endregion

//  -- Maneuver structs
//#region
global function mnv_argpe_match_burn
{
    parameter burnVes,
              tgtObt.

    local tgtTA to tgtObt:argumentOfPeriapsis + tgtObt:lan.
    if verbose print "tgtTA: " + round(tgtTA, 2) at (2, 25).

    local tgtEta to nav_eta_to_ta(burnVes:obt, tgtTA).
    local taOpAlt to nav_obt_alt_at_ta(burnVes:obt, tgtTA + 180).
    
    local dvNeeded to mnv_dv_hohmann(taOpAlt, taOpAlt + 500, burnVes:body).
    local mnvNode to node(tgtEta, 0, 0, dvNeeded[0]).
    return list(tgtEta, dvNeeded[0], mnvNode).
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
    local burn_utc is time:seconds + nav_eta_to_ta(burnVes:obt, node_ta).
    
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

 // -- Actions (executing maneuvers)
//#region
//Simple burn emnv_exec_circ_burn facing either prograde or retrograde
global function mnv_exec_circ_burn
{
    parameter dv,
              mnvTime,
              burnEta,
              burnDur.

    local mecoTS      to burnEta + burnDur.
    local tgtVelocity to velocityAt(ship, mnvTime):orbit:mag + dv.
    local lock  dvRemaining to abs(tgtVelocity - ship:velocity:orbit:mag).
    
    local burnDir to choose compass_for(ship, ship:prograde) if dv > 0 else compass_for(ship, ship:retrograde).
    local sVal    to ship:prograde.
    local tVal    to 0.
    lock steering to sVal.
    lock throttle to tVal.
    
    util_warp_trigger(burnEta).

    until time:seconds >= burnEta
    {
        set burnDir to choose compass_for(ship, ship:prograde) if dv > 0 else compass_for(ship, ship:retrograde).
        set sVal to heading(burnDir, 0, 0).
        disp_mnv_burn(burnEta, dvRemaining, mecoTS - time:seconds).
    }

    set tVal to 1.
    disp_msg("Executing burn").
    until dvRemaining <= 0.1
    {
        set burnDir to choose compass_for(ship, ship:prograde) if dv > 0 else compass_for(ship, ship:retrograde).
        set sVal to heading(burnDir, 0, 0).
        disp_mnv_burn(burnEta, dvRemaining).
    }

    set tVal to 0.

    disp_msg("Maneuver complete!").
    wait 1.
    mnv_clr_disp().
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
        disp_mnv_burn(mnvETA, dvToGo, mecoTS - time:seconds).
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
        disp_mnv_burn(mnvETA, dvToGo).
        wait 0.01.
    }
    set tVal to 0.
    
    disp_msg("Maneuver complete!  ").
    mnv_clr_disp().
}

global function mnv_exec_node_burn
{
    parameter mnvNode,
              burnEta is 0,
              burnDur is 0.

    set burnDur      to mnv_staged_burn_dur(mnvNode:deltaV:mag).
    local halfDur    to mnv_staged_burn_dur(mnvNode:deltaV:mag / 2).
    set burnEta      to mnvNode:time - halfDur.
    local mecoTS     to burnEta + burnDur.
    lock dvRemaining to abs(mnvNode:burnVector:mag).
    
    local sVal       to lookDirUp(mnvNode:burnVector, sun:position).
    local tVal       to 0.
    lock steering    to sVal.
    lock throttle    to tVal.

    disp_info("Burn ETA        : " + round(burnEta, 2) + "          ").
    disp_info2("Burn duration   : " + round(burnDur, 2) + "          ").

    util_warp_trigger(burnEta).

    until time:seconds >= burnEta
    {
        disp_mnv_burn(time:seconds - burnEta, dvRemaining, burnDur).
        wait 0.01.
    }

    local dv0 to mnvNode:deltav.
    lock maxAcc to max(0.00001, ship:maxThrust) / ship:mass.

    disp_msg("Executing burn").
    disp_info2().
    set tVal to 1.
    set sVal to lookDirUp(mnvNode:burnVector, sun:position).
    until false
    {
        if vdot(dv0, mnvNode:deltaV) <= 0.01
        {
            set tVal to 0.
            break.
        }
        else
        {
            set tVal to max(0.02, min(mnvNode:deltaV:mag / maxAcc, 1)).
        }
        disp_mnv_burn(time:seconds - burnEta, dvRemaining, mecoTS - time:seconds).
        wait 0.01.
    }

    disp_msg("Maneuver complete!").
    wait 1.
    mnv_clr_disp().
    unlock steering.
    remove mnvNode.
}
//#endregion

// -- Hill Climbing
//#region
// Evaluates candidates
local function mnv_eval_candidates
{
    parameter data,
              candList,
              tgtVal,
              tgtBody,
              compMode.

    local curScore to mnv_score(data, tgtVal, tgtBody, compMode).
    
    for c in candList 
    {
        local candScore to mnv_score(c, tgtVal, tgtBody, compMode).
        if candScore:intercept 
        {
            if candScore:result > tgtVal 
            {
                if candScore:score < curScore:score 
                {
                    //set curScore to mnv_score(c, tgtVal, tgtBody, compMode).
                    set data to c.
                }
            } 
            else if candScore:result < tgtVal 
            {
                if candScore:score > curScore:score 
                {
                    //set curScore to mnv_score(c, tgtVal, tgtBody, compMode).
                    set data to c.
                }
            }
        }
    }

    return lex("data", data, "curScore", curScore).
}


// Returns a list of candidates given node data and addition factors
global function mnv_get_candidates
{
    parameter data,
              mnvFactor,
              timeFactor to 1,
              radialFactor to 1,
              normalFactor to 1,
              progradeFactor to 1.

    local mnvCandidates to list(
        list(data[0] + mnvFactor, data[1], data[2], data[3])  //Time
        ,list(data[0] - mnvFactor, data[1], data[2], data[3]) //Time
        ,list(data[0], data[1] + mnvFactor, data[2], data[3]) //Radial
        ,list(data[0], data[1] - mnvFactor, data[2], data[3]) //Radial
        ,list(data[0], data[1], data[2] + mnvFactor, data[3]) //Normal
        ,list(data[0], data[1], data[2] - mnvFactor, data[3]) //Normal
        ,list(data[0], data[1], data[2], data[3] + mnvFactor) //Prograde
        ,list(data[0], data[1], data[2], data[3] - mnvFactor) //Prograde
    ).
    if progradeFactor = 0
    {
        mnvCandidates:remove(7).
        mnvCandidates:remove(6).    
    }
    if normalFactor = 0
    {
        mnvCandidates:remove(5).
        mnvCandidates:remove(4).
    }
    if radialFactor = 0
    {
        mnvCandidates:remove(3).
        mnvCandidates:remove(2).
    }
    if timeFactor = 0
    {
        mnvCandidates:remove(1).
        mnvCandidates:remove(0).
    }

    return mnvCandidates.
}

// Returns a maneuver factor for multiplication by the individual node component factors
local function mnv_factor
{
    parameter score.

    local mnvFactor to 0.25.

    // if      score >= -0.95 and score <= 1.05   set mnvFactor to (score * 0.01)  * mnvFactor.
    // else if score >= -0.75 and score <= 1.25   set mnvFactor to (score * 0.1)   * mnvFactor.
    // else if score >= -0.50 and score <= 1.50   set mnvFactor to (score * 0.5)   * mnvFactor.
    // else if score >= -1.0  and score <= 2.0    set mnvFactor to score           * mnvFactor.
    // else if score >= -100  and score <= 101    set mnvFactor to (score * 2)     * mnvFactor.
    // else set mnvFactor to 250. 

    if      score > 0.990 and score < 1.010 set mnvFactor to 0.050  * mnvFactor.
    else if score > 0.975 and score < 1.025 set mnvFactor to 0.125  * mnvFactor.
    else if score > 0.950 and score < 1.050 set mnvFactor to 0.250  * mnvFactor.
    else if score > 0.925 and score < 0.750 set mnvFactor to 0.375  * mnvFactor. 
    else if score > 0.850 and score < 1.150 set mnvFactor to 0.500  * mnvFactor. 
    else if score > 0.750 and score < 1.250 set mnvFactor to 0.750  * mnvFactor.
    else if score > 0.500 and score < 1.500 set mnvFactor to 1      * mnvFactor.
    else if score > 0.000 and score < 2.0   set mnvFactor to 2      * mnvFactor.
    else if score > -2.5  and score < 3.5   set mnvFactor to 4      * mnvFactor. 
    else if score > -10.0 and score < 11.0  set mnvFactor to 8      * mnvFactor.
    else if score > -25.0 and score < 26.0  set mnvFactor to 16     * mnvFactor.
    else if score > -50.0 and score < 51.0  set mnvFactor to 32     * mnvFactor.
    else if score > -75.0 and score < 76.0  set mnvFactor to 64     * mnvFactor.
    else if score > -100  and score < 101   set mnvFactor to 128    * mnvFactor.
    else set mnvFactor to 256 * mnvFactor.

    // if      score > 0.95 * limLo and score < 1.05 * limHi set mnvFactor to 0.050.
    // else if score > 0.85 * limLo and score < 1.15 * limHi set mnvFactor to 0.250. 
    // else if score > 0.75  * limLo and score < 1.25  * limHi set mnvFactor to 0.500. 
    // else if score > 0 * limLo and score < 1.5  * limHi set mnvFactor to 1.
    // else if score > -2.50  * limLo and score < 2.5   * limHi set mnvFactor to 2.
    // else if score > -5.00  * limLo and score < 6     * limHi set mnvFactor to 3.5.
    // else if score > -10.0  * limLo and score < 11    * limHi set mnvFactor to 5.
    // else if score > -25.0  *  limLo and score < 26    * limHi set mnvFactor to 7.5.
    // else if score > -2500  * limLo and score < 2501  * limHi set mnvFactor to 20.
    // else set mnvFactor to 50.

    return mnvFactor.
}


// Improves a maneuver node based on tgtVal and compMode
global function mnv_improve_node 
{
    parameter data,
              tgtVal,
              tgtBody,
              compMode,
              changeModes.

    
    //hill climb to find the best time
    local curScore is mnv_score(data, tgtVal, tgtBody, compMode).

    // mnvCandidates placeholder
    local bestCandidate  to list().
    local mnvCandidates  to list().
    local timeFactor     to changeModes[0].
    local radialFactor   to changeModes[1].
    local normalFactor   to changeModes[2].
    local progradeFactor to changeModes[3].

    // Base maneuver factor - the amount of dV that is used for hill
    // climb iterations
    local mnvFactor is mnv_factor(curScore["score"]).
    
    disp_info("Optimizing node.").

    set mnvCandidates to mnv_get_candidates(data, mnvFactor, timeFactor, radialFactor, normalFactor, progradeFactor).
    set bestCandidate to mnv_eval_candidates(data, mnvCandidates, tgtVal, tgtBody, compMode).
    return bestCandidate.
}

global function mnv_opt_return_node
{
    parameter mnvNode,
              returnBody,
              returnAlt.

    local data  to list(mnvNode:time, mnvNode:radialOut, mnvNode:normal, mnvNode:prograde).
    set data    to mnv_optimize_node_data(data, returnAlt, returnBody, "pe", "1101").
    return node(data[0], data[1], data[2], data[3]).
}

//#region -- Transfer Nodes
// Optimizes a transfer node to another vessel using position prediction and hill climbing.
global function mnv_opt_object_transfer_node
{
    parameter mnvNode,
              tgtVAng is 0.25.

    local bestCandidate to list().
    local candidates    to list().
    local data          to list(mnvNode:time, mnvNode:radialOut, mnvNode:normal, mnvNode:prograde).

    local nodeScore     to mnv_score(data, tgtVAng, target:body, "rendezvousAng").
    local curScore      to nodeScore["score"].
    local intercept     to nodeScore["intercept"].
    local mnvFactor     to mnv_factor(curScore).

    until allNodes:length = 0
    {
        remove nextNode.
    }
    
    // Make sure we will be in the same SOI
    if not intercept 
    {
        set data to mnv_optimize_node_data(data, (target:orbit:semiMajorAxis - target:body:radius) * 2, target:body, "pe").
    }
    
    // Hill climb - eval candidates until within acceptable range
    until curScore >= 0.995 and curScore <= 1.005
    {
        set mnvFactor  to mnv_factor(curScore).
        set candidates to mnv_get_candidates(data, mnvFactor, 10, 0, 0, 0).
        set bestCandidate to mnv_eval_candidates(data, candidates, tgtVAng, target:body, "rendezvousAng").
        set data to bestCandidate["data"].

        set curScore to bestCandidate["curScore"]["score"].
    }

    set mnvNode to node(data[0], data[1], data[2], data[3]).
    return mnvNode.
}

// Optimizes a standard transfer node to another celestial body (not ships!)
global function mnv_opt_transfer_node
{
    parameter mnvNode,
              tgtBody,
              tgtAlt,
              tgtInc.

    local  data         to list(mnvNode:time, mnvNode:radialOut, mnvNode:normal, mnvNode:prograde + 1).
    if hasNode remove mnvNode.

    local optimizedData to list().
    local obtRetro      to choose false if tgtInc <= 90 and tgtInc >= -90 else true.
    
    local nodeScore     to mnv_score(data, tgtInc, tgtBody, "tliInc").
    local intercept     to nodeScore["intercept"].

    disp_msg("Adjusting timing to intercept").
    
    if not intercept 
    {
        until intercept 
        {
            set   data    to list(data[0] + 1, data[1], data[2], data[3]).
            local mnv to node(data[0], data[1], data[2], data[3]).
            add   mnv.
            local testPatch to mnv_next_patch_for_node(mnv).
            
            wait 0.01.

            if testPatch:body = tgtBody
            {
                remove mnv.
                set intercept to true.
            }
            else 
            {
                remove mnv.
            }
        }
    }
    
    disp_msg("Adjusting timing for desired orbital direction").

    set nodeScore to mnv_score(data, tgtInc, tgtBody, "tliInc").
    if obtRetro 
    {
        until nodeScore["intercept"] and nodeScore["result"] > 90 
        {
            set data to list(data[0] - 1, data[1], data[2], data[3]).
            set nodeScore to mnv_score(data, tgtInc, tgtBody, "tliInc").
            wait 0.01.
        }
        set optimizedData to data.
    } 
    else 
    {
        until nodeScore["intercept"] and nodeScore["result"] <= 90 
        {
            set data to list(data[0] + 1, data[1], data[2], data[3]).
            set nodeScore to mnv_score(data, tgtInc, tgtBody, "tliInc").
            wait 0.01.
        }
        set optimizedData to data.
    }
    disp_msg().
    set optimizedData to mnv_optimize_node_data(optimizedData, tgtAlt, tgtBody, "pe").
    return node(optimizedData[0], optimizedData[1], optimizedData[2], optimizedData[3]).
}
//#endregion


// Optimize a node list, obvi
global function mnv_optimize_node_data
{
    parameter data,
              tgtVal,
              tgtBody,
              compMode,
              changeModes is list(10, 1, 1, 1).

    disp_info("Optimizing node.").

    local iteration     to 0.
    local improvedData  to lex().
    local lastScore     to 0.
    local limLo         to 1 - 0.005.
    local limHi         to 1 + 0.005.
    local nodeScore     to 0.

    until iteration >= 10
    {
        set lastScore to mnv_score(data, tgtVal, tgtBody, compMode):score.
        set improvedData to mnv_improve_node(data, tgtVal, tgtBody, compMode, changeModes).
        set data to improvedData["data"].
        set nodeScore to improvedData["curScore"]:score.
        if nodeScore >= limLo and nodeScore <= limHi 
        {
            break.
        }
        else if round(nodeScore, 12) = round(lastScore, 12)
        {
            print "Same score iteration: " + iteration at (2, 35).
            set iteration to iteration + 1.
            if iteration = 10 disp_info2("Reached same score iteration limit: " + iteration).
        }
        else 
        {
            set iteration to 0.
            print "Same score iteration: 0 " at (2, 35).
        }
    }
    print "                        " at (2, 25).
    disp_info("Optimized maneuver found (score: " + round(nodeScore, 5) + ")").
    clr_disp(). 
    return data.
}


// Optimize a node list, obvi
global function mnv_opt_result
{
    parameter compMode, 
              testOrbit.

    if compMode = "pe"          return testOrbit:periapsis.
    else if compMode = "ap"     return testOrbit:apoapsis. 
    else if compMode = "inc"    return testOrbit:inclination.
    else if compMode = "tliInc" return testOrbit:inclination.
    else if compMode = "lan"    return testOrbit:longitudeOfAscendingNode.
    else if compMode = "argpe"  return testOrbit:argumentofperiapsis.
    else if compMode = "impactPos" return addons:tr:impactPos.
    else if compMode = "impactPosLat" return addons:tr:impactPos:lat.
    else if compMode = "impactPosLng" return addons:tr:impactPos:lng.
    else if compMode = "rendezvousAng"
    {
        local rendezvousTime to nextNode:time + (nextNode:orbit:period / 2).
        local targetVelocity to velocityAt(target, rendezvousTime).
        local myVelocity     to velocityAt(ship, rendezvousTime).
        return vang(targetVelocity:orbit, myVelocity:orbit).
    }
}


global function mnv_opt_simple_node 
{
    parameter mnvNode,
              tgtVal,
              compMode,
              tgtBody is ship:body.


    local data to list(mnvNode:time, mnvNode:radialOut, mnvNode:normal, mnvNode:prograde).
    set data to mnv_optimize_node_data(data, tgtVal, tgtBody, compMode).
    return node(data[0], data[1], data[2], data[3]).
}

global function mnv_score
{
    parameter data,
              tgtVal,
              tgtBody,
              compMode.

    local intercept to false.
    local mnvTest   to node(data[0], data[1], data[2], data[3]).
    local result to -999999.
    local score to -999999.

    add mnvTest.
    local scoredOrbit to mnvTest:orbit.

    until intercept
    {
        if scoredOrbit:body = tgtBody
        {
            set result to mnv_opt_result(compMode, scoredOrbit).
            if result:typeName = "GeoCoordinates" 
            {
                local latCheck to result:lat / tgtVal:lat.
                local lngCheck to result:lng / tgtVal:lng.
                set score to (latCheck + (3 * lngCheck)) / 4.
            }
            else
            {
                set score to result / tgtVal.
            }
            set intercept to true.
        }
        else if scoredOrbit:hasNextPatch
        {
            set scoredOrbit to scoredOrbit:nextPatch.
        }
        else
        {
            break.
        }
    }
    disp_mnv_score(tgtVal, tgtBody, intercept, result, score).
    remove mnvTest.

    return lex("score", score, "result", result, "intercept", intercept).
}
//#endregion

//#region -- Local functions
local function mnv_clr_disp
{
    disp_msg().
    disp_info().
    disp_info2().
}
//#endregion