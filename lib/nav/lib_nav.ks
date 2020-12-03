//lib for getting and checking error rate of the vessel direction (heading, pitch, roll).
@lazyGlobal off.

runOncePath("0:/lib/lib_init.ks").
runOncePath("0:/lib/data/ship/lib_mass.ks").
runOncePath("0:/lib/nav/lib_deltav.ks").
runOncePath("0:/lib/data/engine/lib_thrust.ks").
runOncePath("0:/lib/data/engine/lib_engine.ks").
runOncePath("0:/lib/data/engine/lib_isp.ks").
runOncePath("0:/lib/data/engine/lib_twr.ks").


//Checks the input heading and normalizes it for a 360 degree compass
global function check_hdg {

    parameter refHdg to 90.
    
    local retHdg to 90.

    //Validate heading provided to within bounds
    if refHdg <= 360 and refHdg >= 0 {   
        set retHdg to refHdg.
    }

    //If hdg exceeds upper bounds, try to find the intended heading.
    else if refHdg > 360 { 
        from { local x to refHdg.} until x < 360 step { set x to x - 360.} do {
            set retHdg to x. 
            wait 0.001.
        }
    }
    
    else if refHdg < 0 {
        from { local x to refHdg.} until x > 0 step { set x to x + 360. } do {
            set retHdg to x.
            wait 0.001.
        }
    }

    return retHdg.
}


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



//Returns a circularization burn object
global function get_circ_burn_data {
    parameter newAlt,
              burnAt is "ap".

    //Read calculating fuel flow in wiki: https://wiki.kerbalspaceprogram.com/wiki/Tutorial:Advanced_Rocket_Design
    //Calculate variables
    local nodeAt to choose time:seconds + eta:apoapsis if burnAt = "ap" else time:seconds + eta:periapsis.
    local startAlt to choose ship:periapsis if burnAt = "ap" else ship:apoapsis.

    //get deltaV for the burn
    local dV to get_dv_for_maneuver(newAlt, startAlt, ship:body).

    //local burnDur to exhVel * ln(startMass) - exhVel * ln(endMass).
    local burnDur to get_burn_dur(dV). 
    local burnEta to nodeAt - (burnDur / 2).
    local burnEnd to nodeAt + (burnDur / 2).

    logStr("get_circ_burn_data").
    logStr("[dV: " + round(dV, 2) + "][burnDur: " + round(burnDur, 2) + "][nodeAt: " + round(nodeAt, 2) + "][burnEta: " + round(burnEta, 2) + "]").

    return lexicon("dV",dV,"burnDur",burnDur,"burnEta",burnEta,"burnEnd",burnEnd,"nodeAt",nodeAt).
}



//Returns a mun transfer burn object
//Must be called with a node timestamp and have the desired mun set as target
global function get_mun_xfr_burn_data {
    parameter nodeAt.

    if not hasTarget return lex().

    //Burn details
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



//Get the current compass heading in degrees
global function get_nav_heading {
    return mod( 360 - latlng( 90, 0):bearing, 360).
}



//Gets the current signed roll value [-180, 180]
global function get_nav_roll {
    parameter   vecA,
                vecB,
                normal.

    local ang to vAng(vecA, vecB).
    if vDot( vCrs(vecA, vecB), normal) < 0 {
        return -ang.
    }

    return ang.
}



//Get the current pitch in degrees [-90, 90]
global function get_nav_pitch {
    return 90 - vAng(up:vector, facing:vector).
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


global function obt_normal {
    parameter obtIn.

    return vcrs( obtIn:body:position - obtIn:position, obtIn:velocity:orbit):normalized.
}


global function obt_pos {
    parameter obtIn.

    return (obtIn:body:position - obtIn:position).
}


global function obt_tangent {
    parameter obtIn.

    return obtIn:velocity:orbit:normalized.
}


//
// All functions below from kslib project (Distrubuted under MIT  license)
//


// Same as orbital prograde vector for ves
global function ves_tangent {
    parameter ves is ship.

    return ves:velocity:orbit:normalized.
}



// In the direction of orbital angular momentum of ves
// Typically same as Normal
function ves_binormal {
    parameter ves is ship.

    return vcrs((ves:position - ves:body:position):normalized, ves_tangent(ves)):normalized.
}



// Perpendicular to both tangent and binormal
// Typically same as Radial In
function ves_normal {
    parameter ves is ship.

    return vcrs(ves_binormal(ves), ves_tangent(ves)):normalized.
}


// Vector pointing in the direction of longitude of ascending node
function ves_lan {
    parameter ves is ship.

    return angleAxis(ves:orbit:LAN, ves:body:angularVel:normalized) * solarPrimeVector.
}



// Same as surface prograde vector for ves
function ves_srf_tangent {
    parameter ves is ship.

    return ves:velocity:surface:normalized.
}



// In the direction of surface angular momentum of ves
// Typically same as Normal
function ves_srf_binormal {
    parameter ves is ship.

    return vcrs((ves:position - ves:body:position):normalized, ves_srf_tangent(ves)):normalized.
}



// Perpendicular to  both tangent and binormal
// Typically same as Radial In
function ves_srf_normal {
    parameter ves is ship.

    return vcrs(ves_srf_binormal(ves), ves_srf_tangent(ves)):normalized.
}



// Vector pointing in the direction of longitude of ascending node
function ves_srf_lan {
    parameter ves is ship.

    return angleAxis(ves:orbit:LAN - 90, ves:body:angularVel:normalized) * solarPrimeVector.
}



// Vector directly away from the body at ves' position
function ves_local_vertical {
    parameter ves is ship.

    return ves:up:vector.
}



// Angle to ascending node with respect to ves' body's equator
function ang_to_body_asc_node {
    parameter ves is ship.

    local joinVector is ves_lan(ves).
    local angle is vang((ves:position - ves:body:position):normalized, joinVector).
    if ves:status = "LANDED" {
        set angle to angle - 90.
    }
    else {
        local signVector is vcrs(-body:position, joinVector).
        local sign is vdot(ves_binormal(ves), signVector).
        if sign < 0 {
            set angle to angle * -1.
        }
    }
    return angle.
}



// Angle to descending node with respect to ves' body's equator
function ang_to_body_desc_node {
    parameter ves is ship.

    local joinVector is -ves_lan(ves).
    local angle is vang((ves:position - ves:body:position):normalized, joinVector).
    if ves:status = "LANDED" {
        set angle to angle - 90.
    }
    else {
        local signVector is vcrs(-body:position, joinVector).
        local sign is vdot(ves_binormal(ves), signVector).
        if sign < 0 {
            set angle to angle * -1.
        }
    }
    return angle.
}



// Vector directed from the relative descending node to the ascending node
function rel_nodal_vec {
    parameter orbitBinormal.
    parameter targetBinormal.

    return vcrs(orbitBinormal, targetBinormal):normalized.
}



// Angle to relative ascending node determined from args
function ang_to_rel_asc_node {
    parameter orbitBinormal.
    parameter targetBinormal.

    local joinVector is rel_nodal_vec(orbitBinormal, targetBinormal).
    local angle is vang(-body:position:normalized, joinVector).
    local signVector is vcrs(-body:position, joinVector).
    local sign is vdot(orbitBinormal, signVector).
    if sign < 0 {
        set angle to angle * -1.
    }
    return angle.
}



// Angle to relative descending node determined from args
function ang_to_rel_desc_node {
    parameter orbitBinormal.
    parameter targetBinormal.

    local joinVector is -rel_nodal_vec(orbitBinormal, targetBinormal).
    local angle is vang(-body:position:normalized, joinVector).
    local signVector is vcrs(-body:position, joinVector).
    local sign is vdot(orbitBinormal, signVector).
    if sign < 0 {
        set angle to angle * -1.
    }
    return angle.
}



// Orbital phase angle with assumed target
// Positive when you are behind the target, negative when ahead
function get_phase_angle {
    parameter tgt is target.

    local common_ancestor is 0.
    local my_ancestors is list().
    local your_ancestors is list().

    my_ancestors:add(ship:body).
    until not(my_ancestors[my_ancestors:length-1]:hasBody) {
        my_ancestors:add(my_ancestors[my_ancestors:length-1]:body).
    }
    your_ancestors:add(tgt:body).
    until not(your_ancestors[your_ancestors:length-1]:hasBody) {
        your_ancestors:add(your_ancestors[your_ancestors:length-1]:body).
    }

    for my_ancestor in my_ancestors {
        local found is false.
        for your_ancestor in your_ancestors {
            if my_ancestor = your_ancestor {
                set common_ancestor to my_ancestor.
                set found to true.
                break.
            }
        }
        if found {
            break.
        }
    }

    local vel is ship:velocity:orbit.
    local my_ancestor is my_ancestors[0].
    until my_ancestor = common_ancestor {
        set vel to vel + my_ancestor:velocity:orbit.
        set my_ancestor to my_ancestor:body.
    }
    local binormal is vcrs(-common_ancestor:position:normalized, vel:normalized):normalized.

    local phase is vang(
        -common_ancestor:position:normalized,
        vxcl(binormal, tgt:position - common_ancestor:position):normalized
    ).
    local signVector is vcrs(
        -common_ancestor:position:normalized,
        (tgt:position - common_ancestor:position):normalized
    ).
    local sign is vdot(binormal, signVector).
    if sign < 0 {
        return -phase + 360.
    }
    else {
        return phase.
    }
}


global function ta_from_orbits {
    parameter obt0,
              obt1 is ship:obt.

    local obt0_velo to obt0:velocity.
    local obt0_pos to obt0:position.

    
}


//From dunbaratu's kos tutorial (youtube.com/watch?v=NctfWrgreRI&list=PLdXwd2JlyAvowkTmfRXZrqVdRycxUIxpX)
//ETA to a future true anomaly point in a given orbit
local function eta_to_ta {
    parameter orbitIn,  // Orbit to predict for
              taDeg.    // true anomaly we need in degrees

    local targetTime is time_pe_to_ta(orbitIn, taDeg).
    local curTime is time_pe_to_ta(orbitIn, orbitIn:trueanomaly).

    local ta is targetTime - curTime.

    //If negative, we've passed it so return the next orbit
    if ta < 0 { set ta to ta + orbitIn:period. }

    return ta.
}


// The time it takes to get from PE to a given true anomaly
local function time_pe_to_ta {
    parameter orbitIn,  // Orbit to predict for
              taDeg.    // true anomaly in degrees

    local ecc is orbitIn:eccentricity. 
    local sma is orbitIn:semimajoraxis.
    local eAnomDeg is arcTan2( sqrt(1 - ecc^2) * sin(taDeg), ecc + cos(taDeg)).
    local eAnomRad is eAnomDeg * constant():pi / 180.
    local mAnomRad is eAnomRad - ecc * sin(eAnomDeg).

    return mAnomRad / sqrt( orbitIn:body:mu / sma^3 ).
}


//Example functions
// function eta_true_anom {
//     declare local parameter tgt_lng.
//     // convert the positon from reference to deg from PE (which is the true anomaly)
//     local ship_ref to mod(obt:lan+obt:argumentofperiapsis+obt:trueanomaly,360).
//     // s_ref = lan + arg + referenc

//     local node_true_anom to (mod (720+ tgt_lng - (obt:lan + obt:argumentofperiapsis),360)).

//     print "Node anomaly   : " + round(node_true_anom,2).    
//     local node_eta to 0.
//     local ecc to OBT:ECCENTRICITY.
//     if ecc < 0.001 {
//         set node_eta to SHIP:OBT:PERIOD * ((mod(tgt_lng - ship_ref + 360,360))) / 360.

//     } else {
//         local eccentric_anomaly to  arccos((ecc + cos(node_true_anom)) / (1 + ecc * cos(node_true_anom))).
//         local mean_anom to (eccentric_anomaly - ((180 / (constant():pi)) * (ecc * sin(eccentric_anomaly)))).

//         // time from periapsis to point
//         local time_2_anom to  SHIP:OBT:PERIOD * mean_anom /360.

//         local my_time_in_orbit to ((OBT:MEANANOMALYATEPOCH)*OBT:PERIOD /360).
//         set node_eta to mod(OBT:PERIOD + time_2_anom - my_time_in_orbit,OBT:PERIOD) .

//     }

//     return node_eta.
// }



// function set_inc_lan {
//     DECLARE PARAMETER incl_t.
//     DECLARE PARAMETER lan_t.
//     local incl_i to SHIP:OBT:INCLINATION.
//     local lan_i to SHIP:OBT:LAN.

// // setup the vectors to highest latitude; Transform spherical to cubic coordinates.
//     local Va to V(sin(incl_i)*cos(lan_i+90),sin(incl_i)*sin(lan_i+90),cos(incl_i)).
//     local Vb to V(sin(incl_t)*cos(lan_t+90),sin(incl_t)*sin(lan_t+90),cos(incl_t)).
// // important to use the reverse order
//     local Vc to VCRS(Vb,Va).

//     local dv_factor to 1.
//     //compute burn_point and set to the range of [0,360]
//     local node_lng to mod(arctan2(Vc:Y,Vc:X)+360,360).
//     local ship_ref to mod(obt:lan+obt:argumentofperiapsis+obt:trueanomaly,360).

//     local ship_2_node to mod((720 + node_lng - ship_ref),360).
//     if ship_2_node > 180 {
//         print "Switching to DN".
//         set dv_factor to -1.
//         set node_lng to mod(node_lng + 180,360).
//     }       

//     local node_true_anom to 360- mod(720 + (obt:lan + obt:argumentofperiapsis) - node_lng , 360 ).
//     local ecc to OBT:ECCENTRICITY.
//     local my_radius to OBT:SEMIMAJORAXIS * (( 1 - ecc^2)/ (1 + ecc*cos(node_true_anom)) ).
//     local my_speed1 to sqrt(SHIP:BODY:MU * ((2/my_radius) - (1/OBT:SEMIMAJORAXIS)) ).   
//     local node_eta to eta_true_anom(node_lng).
//     local my_speed to VELOCITYAT(SHIP, time+node_eta):ORBIT:MAG.
//     local d_inc to arccos (vdot(Vb,Va) ).
//     local dvtgt to dv_factor* (2 * (my_speed) * SIN(d_inc/2)).

//     // Create a blank node
//     local inc_node to NODE(node_eta, 0, 0, 0).
//  // we need to split our dV to normal and prograde
//     set inc_node:NORMAL to dvtgt * cos(d_inc/2).
//     // always burn retrograde
//     set inc_node:PROGRADE to 0 - abs(dvtgt * sin(d_inc/2)).
//     set inc_node:ETA to node_eta.

//     ADD inc_node.
// }