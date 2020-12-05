@lazyGlobal off.

runOncePath("0:/lib/lib_display").
runOncePath("0:/lib/nav/lib_deltav").
runOncePath("0:/lib/nav/lib_nav").


//
global function add_node_to_plan {
    parameter mnv.

    //Maneuver node is time, radial, normal, prograde.
    if career():canmakenodes {
        set mnv to node(mnv[0], mnv[1], mnv[2], mnv[3]).
        add mnv.
        return mnv.
    }
}


//
global function add_transfer_node {
    parameter mnvObj,
              tgtAlt.

    local mnvList to list(mnvObj["nodeAt"], 0, 0, mnvObj["dv"]).
    local mnvNode to add_optimized_node(mnvList, tgtAlt, "pe").

    set mnvObj["nodeAt"] to time:seconds + mnvNode:eta.
    set mnvObj["burnEta"] to (mnvNode:eta + time:seconds) - (mnvObj["burnDur"] / 2).
    set mnvObj["mnv"] to mnvNode.

    return mnvObj.
}



global function exec_node {
    parameter nd.

    local sVal to lookDirUp(nd:burnvector, sun:position).
    lock steering to sVal.

    local tVal to 0.
    lock throttle to tVal.

    local done to false.
    local dv0 to nd:deltav.
    local maxAcc to ship:maxThrust / ship:mass.

    until done {
        set maxAcc to ship:maxThrust / ship:mass.

        set tVal to min(nd:deltaV:mag / maxAcc, 1).

        if vdot(dv0, nd:deltaV) < 0 {
            lock throttle to 0.
            set done to true.
            break.
        }

        else if nd:deltaV:mag < 0.1 {
            wait until vDot(dv0, nd:deltaV) < 0.1.

            lock throttle to 0.
            set done to true.
        }

        update_display().
        disp_burn_data().
    }

    remove nd.
    disp_clear_block("burn_data").
}


global function add_simple_circ_node {
    parameter nodeAt is "ap",
              tgtAlt is ship:apoapsis.

    local mnv is list().
    local mode is "".

    if nodeAt = "ap" {
        set mnv to list(time:seconds + eta:apoapsis, 0, 0, get_dv_for_mnv(tgtAlt, ship:periapsis, ship:body)).
        set mode to "pe".
    } else {
        set mnv to list(time:seconds + eta:periapsis, 0, 0, get_dv_for_mnv(tgtAlt, ship:apoapsis, ship:body)).
        set mode to "ap".
    }

    set mnv to optimize_node(mnv, tgtAlt, mode).
    set mnv to add_node_to_plan(mnv).
    
    return mnv.
}


global function add_optimized_node {
    parameter mnvParam,
              tgtAlt,
              mode.

    local mnv to optimize_node(mnvParam, tgtAlt, mode).
    set mnv to add_node_to_plan(mnv).

    return mnv.
}


global function optimize_node {
    parameter mnv,
              tgtAlt,
              mode.

    print "MSG: Optimizing maneuver                                     " at (2, 7).

    until false {
        set mnv to improve_node(mnv, tgtAlt, mode).
        local nodeScore to get_node_score(mnv, tgtAlt, mode)["score"].
        if nodeScore >= 0.9985 and nodeScore <= 1.0015 break.
    }

    print "MSG: Optimized maneuver found                                " at (2, 7).
    return mnv.
}


local function improve_node {
    parameter data,
              tgtAlt,
              mode.

    //hill climb to find the best time
    local curScore is get_node_score(data, tgtAlt, mode).
    local mnvFactor is choose 0.25 if curScore:score < 0.75 else 0.01.
    set mnvFactor to choose 0.25 if curScore:score > 1.25 else 0.01.

    local mnvCandidates is list(
        list(data[0] + mnvFactor, data[1], data[2], data[3])
        ,list(data[0] - mnvFactor, data[1], data[2], data[3])
        ,list(data[0], data[1] + mnvFactor, data[2], data[3])
        ,list(data[0], data[1] - mnvFactor, data[2], data[3])
        ,list(data[0], data[1], data[2] + mnvFactor, data[3])
        ,list(data[0], data[1], data[2] - mnvFactor, data[3])
        ,list(data[0], data[1], data[2], data[3] + mnvFactor)
        ,list(data[0], data[1], data[2], data[3] + - mnvFactor)
    ).

    for c in mnvCandidates {
        local candScore to get_node_score(c, tgtAlt, mode).
        if candScore["result"] > tgtAlt {
            if candScore["score"] < curScore["score"] {
                set curScore to get_node_score(c, tgtAlt, mode).
                set data to c.
                print "(Current score: " + round(curScore["score"], 5) + ")   " at (27, 7).
            }
        } else {
            if candScore["score"] > curScore["score"] {
                set curScore to get_node_score(c, tgtAlt, mode).
                set data to c.
                print "(Current score: " + round(curScore["score"], 5) + ")   " at (27, 7).
            }
        }
    }

    return data.
}


local function get_node_score {
    parameter data,
              tgtAlt,
              mode is "pe".

    local score to 0.
    local resultAlt to 0.
    local mnvTest to node(data[0], data[1], data[2], data[3]).

    add mnvTest.
    
    if mode = "pe" {
        set resultAlt to choose mnvTest:obt:periapsis if not mnvTest:obt:hasnextpatch else mnvTest:obt:nextPatch:periapsis.
    }

    else if mode = "ap" {
        set resultAlt to choose mnvTest:obt:apoapsis if not mnvTest:obt:hasnextpatch else mnvTest:obt:nextPatch:apoapsis.
    }

    set score to resultAlt / tgtAlt.
    
    wait 0.01.
    remove mnvTest.
    return lex("score", score, "result", resultAlt).
}

//WIP
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