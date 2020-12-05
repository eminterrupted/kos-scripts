@lazyGlobal off.

runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/lib_display").
runOncePath("0:/lib/nav/lib_deltav").
runOncePath("0:/lib/nav/lib_node").
runOncePath("0:/lib/data/ship/lib_mass").
runOncePath("0:/lib/data/engine/lib_thrust").
runOncePath("0:/lib/data/engine/lib_engine").
runOncePath("0:/lib/data/engine/lib_isp").
runOncePath("0:/lib/data/engine/lib_twr").

//Returns the burn duration of a single stage
global function get_burn_dur_by_stg {
    parameter pDv,
              pStg is stage:number.
    
    local eList to choose get_engs_for_stg(pStg) if get_engs_for_stg(pStg):length > 0 else get_engs_for_next_stg().
    local engPerfObj to get_eng_perf_obj(eList).
    local exhVel to get_engs_exh_vel(eList, ship:apoapsis).
    local vMass to get_vmass_at_stg(pStg).

    local stageThrust to 0.
    for e in engPerfObj:keys {
        set stageThrust to stageThrust + engPerfObj[e]["thr"]["poss"].
    }

    return ((vMass * exhVel) / stageThrust) * ( 1 - (constant:e ^ (-1 * (pDv / exhVel)))).
}



//Returns the total duration to burn the provided deltav, taking staging into account
global function get_burn_dur {
    parameter pDv.
    
    logStr("get_burn_dur").
    local alldur is 0.
    local stgdur is 0.
    local dvObj to get_stages_for_dv(pDv).

    for k in dvObj:keys {
        set stgdur to get_burn_dur_by_stg(dvObj[k], k).
        set alldur to alldur + stgdur.
    }

    return alldur.
}


//Returns a burn object from a node, including duration and eta to burn
global function get_burn_obj_from_node {
    parameter mnvNode.

    //Read calculating fuel flow in wiki: https://wiki.kerbalspaceprogram.com/wiki/Tutorial:Advanced_Rocket_Design
    //Calculate variables
    local dV to mnvNode:burnvector:mag.
    local nodeAt to time:seconds + mnvNode:eta.
    local burnDur to get_burn_dur(dv). 
    local burnEta to nodeAt - (burnDur / 2).
    local burnEnd to nodeAt + (burnDur / 2).

    logStr("get_burn_data_from_node").
    logStr("[dV: " + round(dV, 2) + "][burnDur: " + round(burnDur, 2) + "][nodeAt: " + round(nodeAt, 2) + "][burnEta: " + round(burnEta, 2) + "]").

    return lexicon("dV", dv,"burnDur",burnDur,"burnEta",burnEta,"burnEnd",burnEnd,"nodeAt",nodeAt).
}


// Returns a coplanar burn object
// Assumes burn is either at Ap or Pe
global function get_coplanar_burn_data {
    parameter newAlt,
              burnAt is "ap".

    //Read calculating fuel flow in wiki: https://wiki.kerbalspaceprogram.com/wiki/Tutorial:Advanced_Rocket_Design
    //Calculate variables
    local nodeAt to choose time:seconds + eta:apoapsis if burnAt = "ap" else time:seconds + eta:periapsis.
    local startAlt to choose ship:periapsis if burnAt = "ap" else ship:apoapsis.

    //get deltaV for the burn
    local dV to get_dv_for_mnv(newAlt, startAlt, ship:body).

    //local burnDur to exhVel * ln(startMass) - exhVel * ln(endMass).
    local burnDur to get_burn_dur(dV). 
    local burnEta to nodeAt - (burnDur / 2).
    local burnEnd to nodeAt + (burnDur / 2).

    logStr("get_circ_burn_data").
    logStr("[dV: " + round(dV, 2) + "][burnDur: " + round(burnDur, 2) + "][nodeAt: " + round(nodeAt, 2) + "][burnEta: " + round(burnEta, 2) + "]").

    return lexicon("dV",dV,"burnDur",burnDur,"burnEta",burnEta,"burnEnd",burnEnd,"nodeAt",nodeAt).
}


// Returns a list of params for a maneuver based on given 
// parameters. Used for creating a node structure
global function get_mnv_param_list {    
    parameter burnAt    // Timestamp of mnv
              ,stAlt    // Starting altitude of mnv
              ,tgtAlt   // Target altitude after mnv
              //,tgtInc   // Target inclination after mnv
              ,mnvBody is ship:body.    // Body SOI the mnv will will occur

    local dv to get_dv_for_mnv(tgtAlt, stAlt, mnvBody).
    
    return list(burnAt, 0, 0, dv).
}


// Returns a coplanar mun transfer burn object. Must be called 
// with a node timestamp and have the desired mun set as target
global function get_mun_xfr_burn_data {
    parameter nodeAt.

    if not hasTarget return lex().

    // Burn details
    local dv to get_dv_for_mun_transfer(target).
    local burnDur to get_burn_dur(dV).
    local burnEta to (nodeAt) - (burnDur / 2).

    logStr("get_mun_xfr_burn_data").
    logStr("[tgt:" + target:name + "][dV: " + round(dV, 2) + "][burnDur: " + round(burnDur, 2) + "][nodeAt: " + round(nodeAt, 2) + "][burnEta: " + round(burnEta, 2) + "]").

    return lex("dv", dv, "nodeAt", nodeAt, "burnDur", burnDur, "burnETA", burnETA).
}



//Returns an object describing the transfer window to a mun
global function get_mun_xfr_window {
    parameter stAlt is (ship:apoapsis + ship:periapsis) / 2,
              stBody is ship:body.

    if not hasTarget return lex().

    //Semi-major axis calcs
    local curSMA is stAlt + stBody:radius.
    local tgtSMA is target:altitude + stBody:radius.
    local hohSMA to (curSMA + tgtSMA) / 2.

    //Transfer phase angle and mark
    local xfrPhaseAng to 180 - (1 / (2 * sqrt(tgtSMA ^ 3 / hohSMA ^ 3)) * 360).
    local nodeAt to get_time_to_xfr(xfrPhaseAng) - 60.

    return lex("xfrPhaseAng", xfrPhaseAng, "nodeAt", nodeAt).
}


//Returns the approximate timestamp of next transfer phase angle
global function get_time_to_xfr {
    parameter tgtPhaseAng,
              tgt is target.

    //Get the period of the phase angle (change per second)    
    print "MSG: Sampling phase angle period" at (2, 7).
    local p0 to get_phase_angle(tgt). 
    wait 1. 
    local p1 to get_phase_angle(tgt).
    local phasePeriod to abs(p1 - p0).
    local phaseAng to get_phase_angle(tgt).

    local xfrWindow to choose (time:seconds + ((phaseAng - tgtPhaseAng) / phasePeriod)) if phaseAng > tgtPhaseAng else (time:seconds + (((phaseAng + 360) - tgtPhaseAng) / phasePeriod)).
    
    //Check if we can do the burn in this orbit, else set the window for the next orbit.
    set xfrWindow to choose xfrWindow if xfrWindow - time:seconds > 90 else xfrWindow + ship:orbit:period.

    print "                                " at (2, 7).
    return xfrWindow.
}


//Gets a transfer object for the current target
global function get_transfer_obj {
    if target = "" return false.
    
    logStr("[get_transfer_obj] Getting transfer object for target [" + target + "]").
    
    local window to get_mun_xfr_window().
    local burn to get_mun_xfr_burn_data(window["nodeAt"]).
    local xfrObj to lex("tgt", target).

    for key in window:keys {
        set xfrObj[key] to window[key].
    }

    for key in burn:keys {
        set xfrObj[key] to burn[key].
    }

    return xfrObj.
}