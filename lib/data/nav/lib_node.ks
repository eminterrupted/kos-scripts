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


global function add_optimized_node {
    parameter mnvParam,
              finalAlt.

    print "MSG: Optimizing transfer maneuver" at (2, 7).

    until false {
        set mnvParam to improve_node(mnvParam, finalAlt).
        if get_node_score(mnvParam, finalAlt) >= 1 break.
    }

    local mnv to add_node(mnvParam).
    print "MSG: Optimized maneuver found                                " at (2, 7).
    wait 2.
    print "                                                             " at (2, 7).
    return mnv.
}


local function improve_node {
    parameter data,
              finalAlt.

    //hill climb to find the best time
    local curScore is get_node_score(data, finalAlt).
    local mnvCandidates is list(
        list(data[0] + .05, data[1], data[2], data[3])
        ,list(data[0] - .05, data[1], data[2], data[3])
        ,list(data[0], data[1], data[2], data[3] + .01)
        ,list(data[0], data[1], data[2], data[3] + -.01)
    ).

    for c in mnvCandidates {
        local candScore to get_node_score(c, finalAlt).
        if candScore > curScore {
            set curScore to get_node_score(c, finalAlt).
            set data to c.
            print "(Current score: " + round(curScore, 5) + "     " at (35, 7).
        }
    }

    return data.
}


local function get_node_score {
    parameter data,
              finalAlt.

    local score to 0.
    local mnvTest to node(data[0], data[1], data[2], data[3]).
    add mnvTest.
    if mnvTest:obt:hasnextpatch {
        set score to (mnvTest:obt:nextpatch:periapsis) / finalalt.
    }
    wait 0.01.
    remove mnvTest.
    return score.
}
