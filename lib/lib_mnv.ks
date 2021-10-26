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

// Full and Half Burn duration times over multiple stages.
global function mnv_burn_dur 
{
    parameter dv.

    local dvBurnObj to lex().

    local dvShip to ves_available_dv()["availDv"].
    if dvShip < abs(dv) 
    {
        disp_tee("mnv_burn_dur failed! Reason: Not enough dv", 2).
        disp_tee("dV Needed: " + round(dv, 2) + ". Ship:DeltaV available: " + round(dvShip, 1) + ".", 2).
        return -1.
    }
    else
    {
        disp_tee("Function mnv_burn_stages_next success!", 0).
        disp_tee("dV Needed: " + round(dv, 2) + ". Calculated available: " + round(dvShip, 1) + ".", 0).
    }

    local dvFullStgObj  to mnv_burn_stages(dv).
    if dvFullStgObj:typename = "Lexicon" 
    {
        set dvBurnObj["Full"] to mnv_burn_dur_stage(dvFullStgObj)["All"].
    }
    else
    {
        return -1.
    }

    local dvHalfStgObj to mnv_burn_stages(dv / 2).
    set dvBurnObj["Half"] to mnv_burn_dur_stage(dvHalfStgObj)["All"].

    return dvBurnObj.
}

// Full and Half Burn duration times over multiple stages.
global function mnv_burn_dur_next
{
    parameter dv.

    local dvStgObj  to mnv_burn_stages_next(dv).
    // breakpoint().
    // writeJson(dvStgObj, "0:/mnv_burn_dur_next-dvStgObj.json").
    local dvBurnObj to mnv_burn_dur_stage_next(dvStgObj).
    // writeJson(dvBurnObj, "0:/mnv_burn_dur_next-dvBurnObj.json").
    // print "Duration" at (2, 35).
    // print "Full: " + dvBurnObj["Full"] at (2, 36).
    // print "Half: " + dvBurnObj["Half"] at (2, 37).
    // breakpoint().  
    return dvBurnObj.
}

// Burn duration over multiple stages.
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

        // print "vesMass  : " + vesMass at (2, 25).
        // print "exhVel   : " + exhVel  at (2, 26).
        // print "stgThr   : " + stgThr  at (2, 27).
        // print "stgKey   : " + key at (2, 28).
        // print "dvStgObj : " + dvStgObj[key] at (2, 29).

        // Multiply thrust and mass by 1000 to move from t / kn to kg / n.
        local stgBurDur     to (((vesMass * 1000) * exhVel) / (stgThr * 1000)) * (1 - (constant:e ^ (-1 * (dvStgObj[key] / exhVel)))).
        set dvBurnObj[key]  to stgBurDur.
        set dvBurnObj["all"] to dvBurnObj["all"] + stgBurDur.

        // print "                                      " at (2, 25).
        // print "                                      " at (2, 26).
        // print "                                      " at (2, 27).
        // print "                                      " at (2, 28).
        // print "                                      " at (2, 29).
    }
    return dvBurnObj.
}

// Calculates Half Duration Too
global function mnv_burn_dur_stage_next
{
    parameter dvStgObj.

    local dvBurnObj to lex(
        "Full", 0
        ,"Half", 0
    ).
    
    for key in dvStgObj["Full"]:keys
    {
        local stgStats    to ves_stage_stats(key).
        //local stgMass   to stgStats["Stage"]["CurMass"].
        local exhVel    to stgStats["Stage"]["ExhVel"].
        local stgThr    to stgStats["Stage"]["PossThr"].
        local vesMass   to stgStats["Stage"]["ShipMass"].

        // Multiply thrust and mass by 1000 to move from t / kn to kg / n.
        
        // print "key: " + key at (2, 34).
        // print exhVel at (2, 35).
        // print stgThr at (2, 36).
        // print vesMass at (2, 37).
        // print dvStgObj["Full"][key] at (2, 38).

        local fullDur to (((vesMass * 1000) * exhVel) / (stgThr * 1000)) * (1 - (constant:e ^ (-1 * (dvStgObj["Full"][key] / exhVel)))).
        set dvBurnObj["Full"] to dvBurnObj["Full"] + fullDur.

        if dvStgObj["Half"]:hasKey(key)
        {
            local halfDur to (((vesMass * 1000) * exhVel) / (stgThr * 1000)) * (1 - (constant:e ^ (-1 * (dvStgObj["Half"][key] / exhVel)))).
            set dvBurnObj["Half"] to dvBurnObj["Half"] + halfDur.
        }

        // print "Full dur: " + round(dvBurnObj["Full"], 2) at (2, 40).
        // print "Half dur: " + round(dvBurnObj["Half"], 2) at (2, 41).
        // wait 1.
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
    
    // Iterate over stages until dv is covered
    from { local stg to stage:number.} until dv <= 0 or stg < -1 step { set stg to stg - 1.} do
    {
        
        //print "Stage Num: " + stg at (2, 25).
        local dvStg to ship:stageDeltaV(stg):current.
        //local dvStg to mnv_stage_dv_next(stg).

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

// Calculates half duration as well
global function mnv_burn_stages_next
{
    parameter dv.

    set dv to abs(dv).
    
    local dvShip to ves_available_dv_next().
    //print "dvShip: " + dvShip at (2, 20).
    // If we need more dV than the vessel has, throw an exception.
    if dv > dvShip["availDv"] {
        local hudWait to 0.
        until false
        {
            if time:seconds > hudWait
            {
                disp_hud("Function mnv_burn_stages_next failed!", 2).
                disp_hud("dV Needed: " + round(dv, 2) + ". Calculated available: " + round(dvShip["availDv"], 1) + ".", 2).
                disp_hud("Press Enter to override, or End to terminate", 1).
                set hudWait to time:seconds + 3.
            }

            if util_check_char("Enter")
            {
                disp_hud("Low dV caution overridden").
                break.
            }
            
            if util_check_char("DeleteRight")
            {
                return 1 / 0.
            }
        }
    }
    else
    {
        disp_hud("Function mnv_burn_stages_next success!", 0).
        disp_hud("dV Needed: " + round(dv, 2) + ". Calculated available: " + round(dvShip["availDv"], 1) + ".", 0).
    }

    local dvHalf        to dv / 2.
    local dvFullObj     to lex().
    local dvHalfObj     to lex().
    
    // Iterate over stages until dv is covered
    from { local stg to stage:number.} until dv <= 0 or stg < -1 step { set stg to stg - 1.} do
    {
        
        //local dvStg to ship:stageDeltaV(stg):current.
        //local stgStatObj to ves_stage_stats(stg).
        //local dvStg to mnv_stage_dv_next(stgStatObj).
        local dvStg to mnv_stage_dv(stg).
        local breakFlag to false.
        // print "Stage Num: " + stg at (2, 25).
        // print "dvStg    : " + round(dvStg, 2) at (2, 26).
        // breakpoint().

        if dvStg > 0 
        {
            if dv <= dvStg
            {
                set dvFullObj[stg] to dv.
                set breakFlag to true.
            }
            else 
            {
                set dvFullObj[stg] to dvStg.
                set dv to dv - dvStg.
            }

            if dvHalf > 0 and dvHalf <= dvStg 
            {
                set dvHalfObj[stg] to dvHalf.
                set dvHalf to 0.
            }
            else if dvHalf > 0
            {
                set dvHalfObj[stg] to dvStg.
                set dvHalf to dvHalf - dvStg.
            }

            if breakFlag break.
        }
    }
    return lex("Full", dvFullObj, "Half", dvHalfObj).
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
    local fuelsUsed to uniqueSet().
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
                fuelsUsed:add(r:name).
            }
        }
    }

    // Get cur / dry mass of stage
    set curMass  to ves_mass_at_stage(stg).
    set stgFuel  to ves_stage_fuel_mass(stg, fuelsUsed).
    for fuel in stgFuel:keys
    {
        if fuelsUsed:contains(fuel) 
        {
            set fuelMass to fuelMass + stgFuel[fuel].
        }
    }

    // print "mnv_stage_dv" at (2, 24).
    // print "stgISP  : " + round(stgIsp, 3) at (2, 25). 
    // print "exhVel  : " + exhVel at (2, 26).
    // print "curMass : " + round(curMass, 3) at (2, 27).
    // print "fuelMass: " + round(fuelMass, 3) at (2, 28).
    // print "dryMass : " + round(curMass - dryMass, 3) at (2, 29).
    // wait 2.5.

    set dryMass to curMass - fuelMass.
    if dryMass <= 0 
    {
        return 0.
    }
    set dvStg to choose exhVel * ln(curMass / (dryMass)) if fuelMass > 0 else 0.
    return dvStg.
}

// Attempts to account for payload decouplers
global function mnv_stage_dv_next
{
    parameter stStatsObj.

    local curMass   to 0.
    local dryMass   to 0.
    local dvStg     to 0.
    local fuelMass  to 0.
    local shipMass  to 0.

    local stgIsp    to stStatsObj["Stage"]["ISP"].
    local exhVel    to stgIsp * constant:g0.
    
    set curMass to stStatsObj["Stage"]:CurMass.
    set dryMass to stStatsObj["Stage"]:DryMass.
    set fuelMass to stStatsObj["Stage"]:FuelMass.
    set shipMass to stStatsObj["Stage"]:shipMass.

    // print "mnv_stage_dv" at (2, 30).
    // print "stgISP  : " + round(stgIsp, 3) at (2, 31). 
    // print "exhVel  : " + exhVel at (2, 32).
    // print "curMass : " + round(curMass, 3) at (2, 33).
    // print "fuelMass: " + round(fuelMass, 3) at (2, 34).
    // print "dryMass : " + round(dryMass, 3) at (2, 35).
    // wait 2.5.
    
    set dvStg to choose exhVel * ln(shipMass / (shipMass - fuelMass)) if fuelMass > 0 else 0.

    return dvStg.
}

// Returns the dV for a given list of parts
global function mnv_parts_dv
{
    parameter pList.

    local partsMass    to ves_mass_for_parts(pList).
    local curMass   to partsMass["Current"].
    local dryMass   to partsMass["Dry"].
    local dv        to 0.
    local fuelMass  to 0.

    local engObj to ves_parts_engines_stats(pList).

    local exhVel    to engObj["ISP"] * constant:g0.

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
    parameter tgtBody,
              dir is "retro".

    // local vInfBody to 1.
    // local betaAng to arcCos(1 / (1 + (( ship:orbit:semimajoraxis * vInfBody^2) / (ship:body:mu)))) * constant:radtodeg.

    // Add node at Pe
    disp_msg("Adding node").
    local mnvTime to 0.
    if dir = "retro" 
    {
        set mnvTime to time:seconds + eta:periapsis.
    }
    else
    {
        set mnvTime to time:seconds + eta:apoapsis.
    }
    
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

// Return an object containing all parameters needed for a maneuver
// to change inclination from orbit 0 to orbit 1. Returns a list:
// - [0] (nodeAt)     - center of burn node
// - [1] (burnVector) - dV vector including direction and mag
// - [2] (nodeStruc)  - A maneuver node structure for this burn
global function mnv_inc_match_burn 
{
    parameter burnVes,      // Vessel that will perform the burn
              burnVesObt,   // The orbit where the burn will take place. This may not be the current orbit
              tgtObt,       // target orbit to match
              nearestNode is false. // If true, choose the nearest of AN / DN, not the cheapest

    // Variables
    local burn_utc to 0.

    // Normals
    local ves_nrm to nav_obt_normal(burnVesObt).
    local tgt_nrm to nav_obt_normal(tgtObt).

    // Total inclination change
    local d_inc to vang(ves_nrm, tgt_nrm).

    // True anomaly of ascending node
    local node_ta to nav_asc_node_ta(burnVesObt, tgtObt).

    // ** IMPORTANT ** - Below is the "right" code, I am testing picking the soonest vs most efficient
    // Pick whichever node of AN or DN is higher in altitude,
    // and thus more efficient. node_ta is AN, so if it's 
    // closest to Pe, then use DN 
    if node_ta < 90 or node_ta > 270 
    {
        set node_ta to mod(node_ta + 180, 360).
    }

    // Get the burn eta. If nearestNode flag is set, choose the node with 
    // soonest ETA. Else, choose the cheapest node.
    if nearestNode 
    {
        set burn_utc to time:seconds + nav_eta_to_ta(burnVesObt, node_ta).
        if burn_utc > ship:orbit:period / 2 
        {
            set node_ta to mod(node_ta + 180, 360).
            set burn_utc to time:seconds + nav_eta_to_ta(burnVes:obt, node_ta).
        }
    }
    else 
    {
        set burn_utc to time:seconds + nav_eta_to_ta(burnVesObt, node_ta).
    }

    // Get the burn unit direction (burnvector direction)
    local burn_unit to (ves_nrm + tgt_nrm):normalized.

    // Get deltav / burnvector magnitude
    local vel_at_eta to velocityAt(burnVes, burn_utc):orbit.
    local burn_mag to -2 * vel_at_eta:mag * cos(vang(vel_at_eta, burn_unit)).
    
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
              burnDur is lex().

    local fullDur to 0.
    local halfDur to 0.

    if burnDur:typename = "Scalar"
    {
        set fullDur to burnDur.
        set halfDur to mnvNode:time - burnEta.
    }
    else
    {
        set burnDur to mnv_burn_dur_next(mnvNode:deltaV:mag).
        if burnDur:typename = "Scalar" set burnDur to mnv_burn_dur_next(mnvNode:deltaV:mag).
        set fullDur to burnDur["Full"].
        set halfDur to burnDur["Half"].
    }
    
    disp_info("Burn durations").
    disp_info2("Full: " + round(fullDur, 2) + " | Half: " + round(halfDur, 2)).
    
    set burnEta      to mnvNode:time - halfDur.
    disp_info2("Burn ETA: " + round(burnEta, 2) + " | MnvTime: " + round(mnvNode:time, 2)).
    
    local mecoTS     to burnEta + fullDur.
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
    disp_info2("Burn duration   : " + round(fullDur, 2) + "          ").

    util_warp_trigger(burnEta, "burn ETA").

    until time:seconds >= burnEta
    {
        set sVal to lookDirUp(mnvNode:burnVector, sun:position).
        disp_mnv_burn(time:seconds - burnEta, dvRemaining, fullDur).
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