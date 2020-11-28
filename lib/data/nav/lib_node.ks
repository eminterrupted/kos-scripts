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
    parameter nodeAt is "ap".

    local mnv is node(0, 0, 0, 0).

    if nodeAt = "ap" {
        set mnv to node(time:seconds + eta:apoapsis, 0, 0, get_dv_for_maneuver(ship:apoapsis, ship:periapsis, ship:body)).
    } else {
        set mnv to node(time:seconds + eta:periapsis, 0, 0, get_dv_for_maneuver(ship:periapsis, ship:apoapsis, ship:body)).
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
