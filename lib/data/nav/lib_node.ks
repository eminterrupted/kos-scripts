runOncePath("0:/lib/data/nav/lib_deltav").
runOncePath("0:/lib/data/nav/lib_nav").


//
global function add_node {
    parameter mnv.

    //Maneuver node is time, radial, normal, prograde.
    if career():canmakenodes {
        set mnv to node(mnv[0], mnv[1], mnv[2], mnv[3]).
        add mnv.
        return mnv.
    }
}


global function remove_node {
    parameter mnv.
    
    remove mnv.
}


//Returns a circularization burn object
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


global function add_simple_circ_node {
    parameter nodeAt is "ap",
              tgtAlt is ship:apoapsis.

    local mnv is node(0, 0, 0, 0).

    if nodeAt = "ap" {
        set mnv to node(time:seconds + eta:apoapsis, 0, 0, get_dv_for_maneuver(tgtAlt, ship:periapsis, ship:body)).
    } else {
        set mnv to node(time:seconds + eta:periapsis, 0, 0, get_dv_for_maneuver(tgtAlt, ship:apoapsis, ship:body)).
    }

    add mnv.

    return mnv.
}



global function add_optimized_node {
    parameter mnvParam,
              finalAlt.

    print "MSG: Optimizing maneuver" at (2, 7).

    until false {
        set mnvParam to improve_node(mnvParam, finalAlt).
        local nodeScore to get_node_score(mnvParam, finalAlt)["score"].
        if nodeScore >= 0.99 and nodeScore <= 1.01 break.
    }

    local mnv to add_node(mnvParam).
    print "MSG: Optimized maneuver found                                " at (2, 7).
    wait 2.
    print "                                                             " at (2, 7).
    return mnv.
}


local function improve_node {
    parameter data,
              tgtAlt.

    //hill climb to find the best time
    local curScore is get_node_score(data, tgtAlt).
    local mnvCandidates is list(
        list(data[0] + .05, data[1], data[2], data[3])
        ,list(data[0] - .05, data[1], data[2], data[3])
        ,list(data[0], data[1], data[2], data[3] + .01)
        ,list(data[0], data[1], data[2], data[3] + -.01)
    ).

    for c in mnvCandidates {
        local candScore to get_node_score(c, tgtAlt).
        if candScore["result"] > tgtAlt {
            if candScore["score"] < curScore["score"] {
                set curScore to get_node_score(c, tgtAlt).
                set data to c.
                print "(Current score: " + round(curScore["score"], 5) + ")   " at (27, 7).
            }
        } else {
            if candScore["score"] > curScore["score"] {
                set curScore to get_node_score(c, tgtAlt).
                set data to c.
                print "(Current score: " + round(curScore["score"], 5) + ")   " at (27, 7).
            }
        }
    }

    return data.
}


local function get_node_score {
    parameter data,
              tgtAlt.

    local score to 0.
    local resultAlt to 0.
    local mnvTest to node(data[0], data[1], data[2], data[3]).
    add mnvTest.
    if mnvTest:obt:hasnextpatch {
        set resultAlt to mnvTest:obt:nextPatch:periapsis.
        set score to resultAlt / tgtAlt.
    }
    wait 0.01.
    remove mnvTest.
    return lex("score", score, "result", resultAlt).
}


global function get_node_for_inc_change {
    parameter tObt,
              sObt is ship:orbit.

    local sInc to sObt:inclination.
    local sVel to sObt:velocity:orbit:mag.
    
    local tInc to tObt:inclination.
    local tVel to tObt:velocity:orbit:mag.

    local dv to sqrt( sVel ^ 2 + tVel ^ 2 - 2 * sVel * tVel * cos(tInc - sInc)).
    
    local n to 360 / sObt:period.
    local meanAnomaly to sObt:meananomalyatepoch + (n * (time:seconds - sObt:epoch)). 
    

    return true.
}


//Takes in two orbits, finds the longitude of ascending node
global function find_lan_for_node {
    parameter sObt, 
              tObt.
    
    return true.
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