@lazyGlobal off.

// Functions for orbital maneuvers

// Dependencies
runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_mnv_optimization").
runOncePath("0:/lib/lib_nav").
runOncePath("0:/lib/lib_util").
runOncePath("0:/lib/lib_vessel").
runOncePath("0:/kslib/lib_navball").
//runOncePath("0:/kslib/lib_navigation").

// Variables
local verbose to false.

// -- Misc

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

    set dv to abs(dv).
    local dvStgObj to lex().

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
        
        local dvStg to ship:stageDeltaV(stg):current.
        //local dvStg to mnv_stage_dv(stg).

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


// Calculates stages used for a given dv burn. Assumes that the burn starts 
// with the current stage. Returns a lexicon containing stage num and dv per 
// stage. Used with the mnv_burn_dur function
global function mnv_burn_stages_next
{
    parameter dv.

    local availDv to 0.
    local dvStgObj to lex().
    local dvBurnObj to lex().

    set dv to abs(dv).

    set availDv to ves_available_dv().
    breakpoint().

    // If we need more dV than the vessel has, throw an exception.
    if dv > availDv {
        hudText("dV Needed: " + round(dv, 2) + ". Not enough deltaV on vessel!", 10, 2, 24, red, false).
        return 1 / 0.
    }

    // Iterate over stages until dv is covered
    for stg in dvStgObj:keys
    {
        local stgDv to dvStgObj[stg].
        if dv < stgDv 
        {
            set dvBurnObj[stg] to dv.
            break.
        }
        else
        {
            set dvBurnObj[stg] to stgDv.
            set dv to dv - stgDv.
        }
    }

    return dvBurnObj.
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
    local dryMass   to 0.
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

    set dryMass to curMass - fuelMass.
    if dryMass <= 0 
    {
        return 0.
    }
    set dvStg to choose exhVel * ln(curMass / (dryMass)) if fuelMass > 0 else 0.
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

// Returns an exit manuever
global function mnv_exit_node
{
    parameter tgtBody.

    // local vInfBody to 1.
    // local betaAng to arcCos(1 / (1 + (( ship:orbit:semimajoraxis * vInfBody^2) / (ship:body:mu)))) * constant:radtodeg.

    // Add node at Pe
    disp_msg("Adding node").
    local mnvTime to time:seconds + eta:periapsis.
    local mnvNode to node(mnvTime, 0, 0, 10).
    add mnvNode.

    wait 1.

    // Given it dv to escape
    disp_msg("Adding escape dv").
    until false
    {
        if mnvNode:orbit:hasnextpatch
        {
            if mnvNode:orbit:nextPatch:body = tgtBody
            {
                break.
            }   
        }
        remove mnvNode.
        set mnvNode to mnv_opt_change_node(mnvNode, "prograde", 25).
        add mnvNode. 
    }
    disp_info().
    wait 1.

    return mnvNode.
}

// Optimizes an exit node for highest ap
global function mnv_optimize_exit_ap
{
    parameter mnvNode,
              apThresh.
    
    // Sweep timing to lowest Pe
    local lastAp to mnvNode:orbit:nextPatch:apoapsis.
    remove mnvNode.
    until false
    {
        add mnvNode.
        disp_info("Current Ap: " + mnvNode:orbit:nextPatch:apoapsis).
        disp_info2("LastAp    : " + lastAp).
        if lastAp > mnvNode:orbit:nextPatch:apoapsis or lastAp >= apThresh
        {
            remove mnvNode.
            break.
        }
        set lastAp to mnvNode:orbit:nextPatch:apoapsis. 
        remove mnvNode.
        set mnvNode to mnv_opt_change_node(mnvNode, "time", 10).
    }
    disp_info().
    disp_info2().
    return mnvNode.
}


// Optimizes an exit node for lowest pe
global function mnv_optimize_exit_pe
{
    parameter mnvNode,
              peThresh.
    
    // Sweep timing to lowest Pe
    if not hasNode add mnvNode.
    local lastPe to mnvNode:orbit:nextPatch:periapsis.
    remove mnvNode.
    until false
    {
        add mnvNode.
        disp_info("Current Pe: " + mnvNode:orbit:nextPatch:periapsis).
        disp_info2("LastPe    : " + lastPe).
        if lastPe < mnvNode:orbit:nextPatch:periapsis or lastPe <= peThresh
        {
            remove mnvNode.
            break.
        }
        set lastPe to mnvNode:orbit:nextPatch:periapsis. 
        remove mnvNode.
        set mnvNode to mnv_opt_change_node(mnvNode, "time", 10).
    }
    disp_info().
    disp_info2().

    return mnvNode.
}

// Return an object containing all parameters needed for a maneuver
// to change inclination from orbit 0 to orbit 1. Returns a list:
// - [0] (nodeAt)     - center of burn node
// - [1] (burnVector) - dV vector including direction and mag
// - [2] (nodeStruc)  - A maneuver node structure for this burn
global function mnv_inc_match_burn 
{
    parameter burnVes,      // Vessel that will perform the burn
              burnVesObt,   // The orbit where the burn will take place. This may not be the current orbit
              tgtObt.       // target orbit to match

    // Normals
    local ves_nrm is nav_obt_normal(burnVesObt).
    local tgt_nrm is nav_obt_normal(tgtObt).

    // Total inclination change
    local d_inc is vang(ves_nrm, tgt_nrm).

    // True anomaly of ascending node
    local node_ta is nav_asc_node_ta(burnVesObt, tgtObt).

    // ** IMPORTANT ** - Below is the "right" code, I am testing picking the soonest vs most efficient
    // Pick whichever node of AN or DN is higher in altitude,
    // and thus more efficient. node_ta is AN, so if it's 
    // closest to Pe, then use DN 
    if node_ta < 90 or node_ta > 270 
    {
        set node_ta to mod(node_ta + 180, 360).
    }

    // Get the burn eta
    local burn_utc is time:seconds + nav_eta_to_ta(burnVesObt, node_ta).
    
    // TEST CODE BASED ON SOONEST NODE
    // if burn_utc > ship:orbit:period / 2 
    // {
    //     set node_ta to mod(node_ta + 180, 360).
    //     set burn_utc to time:seconds + nav_eta_to_ta(burnVes:obt, node_ta).
    // }


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
    
    //Staging trigger
    when ship:availablethrust <= 0.1 and tVal > 0 then
    {
        ves_safe_stage().
        preserve.
    }

    disp_info("Burn ETA        : " + round(burnEta, 2) + "          ").
    disp_info2("Burn duration   : " + round(burnDur, 2) + "          ").

    util_warp_trigger(burnEta).

    until time:seconds >= burnEta
    {
        set sVal to lookDirUp(mnvNode:burnVector, sun:position).
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

//#region -- Local functions
local function mnv_clr_disp
{
    disp_msg().
    disp_info().
    disp_info2().
}
//#endregion