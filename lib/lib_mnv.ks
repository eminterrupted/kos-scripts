@lazyGlobal off.

// Functions for orbital maneuvers

// Dependencies
runOncePath("0:/lib/lib_vessel").
runOncePath("0:/lib/lib_nav").
runOncePath("0:/lib/lib_util").
runOncePath("0:/kslib/lib_navball").
//runOncePath("0:/kslib/lib_navigation").

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
    parameter dvNeeded.

    local dvStgObj to lex().
    set dvNeeded to abs(dvNeeded).

    // If we need more dV than the vessel has, throw an exception.
    ship:deltaV:forcecalc.
    if dvNeeded > ship:deltaV:current {
        hudText("dV Needed: " + round(dvNeeded, 2) + ". Not enough deltaV on vessel!", 10, 2, 24, red, false).
        return 1 / 0.
    }

    // Iterate over stages until dv is covered
    from { local stg to stage:number.} until dvNeeded <= 0 step { set stg to stg - 1.} do
    {
        
        //local dvStg to ship:stageDeltaV(stg):current.
        local dvStg to mnv_stage_dv(stg).

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

// Returns a list of burn eta / duration
global function mnv_burn_times
{
    parameter dvNeeded,
              mnvTime.

    local burnDur to mnv_burn_dur(dvNeeded).
    local burnEta to mnvTime - mnv_burn_dur(dvNeeded / 2).
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
    print tgtTA at (2, 25).

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
        mnv_burn_disp(burnEta, dvRemaining).
    }

    set tVal to 1.
    disp_msg("Executing burn").
    until dvRemaining <= 0.1
    {
        set burnDir to choose compass_for(ship, ship:prograde) if dv > 0 else compass_for(ship, ship:retrograde).
        set sVal to heading(burnDir, 0, 0).
        mnv_burn_disp(burnEta, dvRemaining).
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
        mnv_burn_disp(mnvETA, dvToGo).
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
        mnv_burn_disp(mnvETA, dvToGo).
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

    set burnDur      to mnv_burn_dur(mnvNode:deltaV:mag).
    local halfDur    to mnv_burn_dur(mnvNode:deltaV:mag / 2).
    set burnEta      to mnvNode:time - halfDur.
    local mecoTS     to burnEta + burnDur.
    lock dvRemaining to abs(mnvNode:burnVector:mag).
    
    local sVal       to lookDirUp(mnvNode:burnVector, sun:position).
    local tVal       to 0.
    lock steering    to sVal.
    lock throttle    to tVal.

    disp_info("Burn ETA : " + round(burnEta, 2) + "          ").
    disp_info2("Burn duration: " + round(burnDur, 2) + "          ").

    util_warp_trigger(burnEta).

    until time:seconds >= burnEta
    {
        mnv_burn_disp(time:seconds - burnEta, dvRemaining, burnDur).
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
        mnv_burn_disp(time:seconds - burnEta, dvRemaining, mecoTS - time:seconds).
        wait 0.01.
    }

    disp_msg("Maneuver complete!").
    wait 1.
    mnv_clr_disp().
    unlock steering.
    remove mnvNode.
}
//#endregion

// -- Disp
//#region
global function mnv_burn_disp
{
    parameter burnEta, dvToGo is 0, burnDur is 0.

    disp_msg("DeltaV Remaining: " + round(dvToGo, 2)). 
    if burnEta <= 0 
    {
        disp_info("Burn ETA: " + round(burnEta, 2)).
        disp_info2("Burn duration: " + round(burnDur, 2)).
    }
    else
    {
        disp_info("Burn duration: " + round(burnDur, 2)).
        disp_info2().
    }
}

local function mnv_clr_disp
{
    disp_msg().
    disp_info().
    disp_info2().
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
                    set curScore to mnv_score(c, tgtVal, tgtBody, compMode).
                    set data to c.
                }
            } 
            else if candScore:result < tgtVal 
            {
                if candScore:score > curScore:score 
                {
                    set curScore to mnv_score(c, tgtVal, tgtBody, compMode).
                    set data to c.
                }
            }
        }
    }

    return lex("data", data, "curScore", curScore).
}

// Improves a maneuver node based on tgtVal and compMode
local function mnv_improve_node 
{
    parameter data,
              tgtVal,
              tgtBody,
              compMode,
              changeModes.

    local limLo to 1 - 0.0075.
    local limHi to 1 + 0.0075.

    //hill climb to find the best time
    local curScore is mnv_score(data, tgtVal, tgtBody, compMode).

    // mnvCandidates placeholder
    local mnvCandidates is list().

    // Base maneuver factor - the amount of dV that is used for hill
    // climb iterations
    local mnvFactor is 1.

    if curScore:score > (limLo * 0.975) and curScore:score < (limHi * 1.025)        set mnvFactor to 0.05   * mnvFactor.
    else if curScore:score > (limLo * 0.925) and curScore:score < (limHi * 1.075)   set mnvFactor to 0.125  * mnvFactor. 
    else if curScore:score > (limLo * 0.85) and curScore:score < (limHi * 1.15)     set mnvFactor to 0.25   * mnvFactor. 
    else if curScore:score > (limLo * 0.75) and curScore:score < (limHi * 1.25)     set mnvFactor to 0.50   * mnvFactor.
    else if curScore:score > (limLo * 0.65) and curScore:score < (limHi * 1.35)     set mnvFactor to 0.75   * mnvFactor.
    else if curScore:score > 0.5 * limLo and curScore:score < limHi * 1.5               set mnvFactor to 1      * mnvFactor.
    else if curScore:score > -10 * limLo and curScore:score < limHi * 11            set mnvFactor to 2      * mnvFactor. 
    else                                                                            set mnvFactor to 5      * mnvFactor.
    
    disp_info("Optimizing node.").

    set mnvCandidates to list(
        list(data[0] + mnvFactor, data[1], data[2], data[3])  //Time
        ,list(data[0] - mnvFactor, data[1], data[2], data[3]) //Time
        ,list(data[0], data[1] + mnvFactor, data[2], data[3]) //Radial
        ,list(data[0], data[1] - mnvFactor, data[2], data[3]) //Radial
        ,list(data[0], data[1], data[2] + mnvFactor, data[3]) //Normal
        ,list(data[0], data[1], data[2] - mnvFactor, data[3]) //Normal
        ,list(data[0], data[1], data[2], data[3] + mnvFactor) //Prograde
        ,list(data[0], data[1], data[2], data[3] - mnvFactor) //Prograde
    ).
    if changeModes[3] = "0"
    {
        mnvCandidates:remove(7).
        mnvCandidates:remove(6).    
    }
    if changeModes[2] = "0"
    {
        mnvCandidates:remove(5).
        mnvCandidates:remove(4).
    }
    if changeModes[1] = "0"
    {
        mnvCandidates:remove(3).
        mnvCandidates:remove(2).
    }
    if changeModes[0] = "0"
    {
        mnvCandidates:remove(1).
        mnvCandidates:remove(0).
    }


    local bestCandidate to mnv_eval_candidates(data, mnvCandidates, tgtVal, tgtBody, compMode).
    return bestCandidate.
}

global function mnv_opt_return_node
{
    parameter mnvNode,
              returnBody,
              returnAlt.

    local data  to list(mnvNode:time, mnvNode:radialOut, mnvNode:normal, mnvNode:prograde).
    set data    to mnv_optimize_node_data(data, returnAlt, returnBody, "pe", "1001").
    return node(data[0], data[1], data[2], data[3]).
}

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
    set optimizedData to mnv_optimize_node_data(optimizedData, tgtAlt, tgtBody, "pe").
    return node(optimizedData[0], optimizedData[1], optimizedData[2], optimizedData[3]).
}

// Optimize a node list, obvi
global function mnv_optimize_node_data
{
    parameter data,
              tgtVal,
              tgtBody,
              compMode,
              changeModes is "1111".

    disp_info("Optimizing node.").

    local iteration     to 0.
    local improvedData  to lex().
    local lastScore     to 0.
    local limLo         to 1 - 0.005.
    local limHi         to 1 + 0.005.
    local nodeScore     to 0.

    until iteration >= 5
    {
        set lastScore to mnv_score(data, tgtVal, tgtBody, compMode):score.
        set improvedData to mnv_improve_node(data, tgtVal, tgtBody, compMode, changeModes).
        set data to improvedData["data"].
        set nodeScore to improvedData["curScore"]:score.
        wait 0.01.
        if nodeScore >= limLo and nodeScore <= limHi 
        {
            break.
        }
        else if round(nodeScore, 8) = round(lastScore, 8)
        {
            print "Same score iteration: " + iteration at (2, 35).
            set iteration to iteration + 1.
        }
        wait 0.01.
    }
    print "                        " at (2, 25).
    disp_info("Optimized maneuver found (score: " + round(nodeScore, 5) + ")").
    clr_disp(). 
    return data.
}


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
}


global function mnv_opt_simple_node 
{
    parameter mnvNode,
              tgtVal,
              compMode,
              tgtBody is ship:body.


    print "tgtVal: " + tgtVal at (2, 25).
    print "compMode: " + compMode at (2, 26).
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
            set score to result / tgtVal.
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