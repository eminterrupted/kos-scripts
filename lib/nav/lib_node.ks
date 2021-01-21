@lazyGlobal off.

runOncePath("0:/lib/display/lib_display").
runOncePath("0:/lib/nav/lib_deltav").
runOncePath("0:/lib/nav/lib_nav").

// Functions
global function add_node_mun_return {
    parameter tgtAlt.

    local dv is 0.
    local mnvNode to node(time:seconds + eta:periapsis, 0, 0, 0).
    add mnvNode.

    until nextNode:obt:hasNextPatch {
        remove mnvNode.
        set dv to dv + 5.
        set mnvNode to node(time:seconds + eta:periapsis, 0, 0, dv).
        add mnvNode.
        wait 0.01.
    }

    set dv to get_dv_for_retrograde(tgtAlt, mnvNode:obt:nextPatch:periapsis, mnvNode:obt:nextPatch:body).

    set mnvNode to node(7200 + time:seconds + mnvNode:obt:nextpatcheta, 0, 0, dv).
    add mnvNode.

    set mnvNode to optimize_existing_node(mnvNode, tgtAlt, "pe").
}


global function add_node_to_plan {
    parameter mnv.

    //Maneuver node is time, radial, normal, prograde.
    if career():canmakenodes {
        set mnv to node(mnv[0], mnv[1], mnv[2], mnv[3]).
        add mnv.
        return mnv.
    }
}


//TODO - Add a rendezvous node with optional phase angle
global function add_rendezvous_node {
    parameter _mnvObj,
              _tgtAlt,
              _tgtObj.

    return false.
}


global function add_transfer_node {
    parameter mnvObj,
              tgtAlt,
              impact is false.

    local mnvList to list(mnvObj["nodeAt"], 0, 0, mnvObj["dv"]).
    local mnvNode to node(mnvList[0],mnvList[1], mnvList[2], mnvList[3]).
    
    add mnvNode.
    until nextNode:obt:hasnextpatch {
        local dv to mnvNode:burnvector:mag.
        remove mnvNode.
        set mnvNode to node(mnvList[0],mnvList[1], mnvList[2], dv + 1).
        add mnvNode.
    }

    if not impact {
        local mnvAcc to 0.005.
        set mnvNode to optimize_existing_node(mnvNode, tgtAlt, "pe", target, mnvAcc).
    }

    set mnvObj["nodeAt"] to time:seconds + mnvNode:eta.
    set mnvObj["burnEta"] to (mnvNode:eta + time:seconds) - (mnvObj["burnDur"] / 2).
    set mnvObj["mnv"] to mnvNode.

    return mnvObj.
}


global function add_capture_node {
    parameter tgtAlt.

    local dv to get_dv_for_prograde(tgtAlt, ship:periapsis).
    local mnv to list(time:seconds + eta:periapsis, 0, 0, dv).

    local mnvNode to node(mnv[0], mnv[1], mnv[3], mnv[3]).
    add mnvNode.

    until not mnvNode:orbit:hasNextPatch {
        set mnv to list(mnv[0], mnv[1], mnv[2], mnv[3] - 5).
        set mnvNode to node(mnv[0], mnv[1], mnv[2], mnv[3]).
        if hasNode remove nextNode.
        add mnvNode.
        wait 0.01.
    }

    until mnvNode:orbit:apoapsis <= max(tgtAlt, ship:periapsis + 1000) {
        if hasNode remove nextNode.
        set mnv to list(mnv[0], mnv[1], mnv[2], mnv[3] - 0.25).
        set mnvNode to node(mnv[0], mnv[1], mnv[2], mnv[3]).
        add mnvNode.
        wait 0.01.
    }
    
    return mnvNode.
}


global function add_optimized_node {
    parameter _mnvParam,
              _tgtAlt,
              _compMode,
              _tgtBody,
              _mnvAcc.

    local mnv to optimize_node_list(_mnvParam, _tgtAlt, _compMode, _tgtBody, _mnvAcc).
    set mnv to add_node_to_plan(mnv).

    return mnv.
}


global function add_simple_circ_node {
    parameter _nodeAt,
              _tgtAlt.

    local dv to choose get_dv_for_retrograde(_tgtAlt, ship:apoapsis) if _nodeAt = "pe" else get_dv_for_prograde(_tgtAlt, ship:periapsis).
    if dv > 9999 set dv to 50.

    local mnv is list().
    local mode is "".

    if _nodeAt = "ap" {
        set mnv to list(time:seconds + eta:apoapsis, 0, 0, dv).
        set mode to "pe".
    } else {
        set mnv to list(time:seconds + eta:periapsis, 0, 0, dv).
        set mode to "ap".
    }

    local mnvAcc is 0.005.

    set mnv to optimize_node_list(mnv, _tgtAlt, mode, ship:body, mnvAcc).
    set mnv to add_node_to_plan(mnv).
    
    return mnv.
}


local function eval_candidates {
    parameter _data,
              _candList,
              _tgtVal,
              _compMode,
              _tgtBody.

    local curScore to get_node_score(_data, _tgtVal, _compMode, _tgtBody).
    
    for c in _candList {
        local candScore to get_node_score(c, _tgtVal, _compMode, _tgtBody).
        if candScore:intersect {
            if candScore:result > _tgtVal {
                if candScore:score < curScore:score {
                    set curScore to get_node_score(c, _tgtVal, _compMode, _tgtBody).
                    set _data to c.
                }
            } else if candScore:result < _tgtVal {
                if candScore:score > curScore:score {
                    set curScore to get_node_score(c, _tgtVal, _compMode, _tgtBody).
                    set _data to c.
                }
            }
        }
    }

    return lex("_data", _data, "curScore", curScore).
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


local function get_node_result {

    parameter _compMode,
              _obt.

    if _compMode = "pe" {     
        return _obt:periapsis.
    } else if _compMode = "ap" {
        return _obt:apoapsis.
    } else if _compMode = "inc" {
        return _obt:inclination.
    } else if _compMode = "tliInc" { 
        return _obt:inclination.
    } else if _compMode = "lan" {
        return _obt:longitudeOfAscendingNode.
    } else if _compMode = "argpe" {
        return _obt:argumentofperiapsis.
    }
}


local function get_node_score {
    parameter _data,
              _tgtVal,
              _compMode,
              _tgtBody.

    local intersect to false.
    local mnvTest to node(_data[0], _data[1], _data[2], _data[3]).
    local result to -999999.
    local score to -999999.
    
    add mnvTest.
    local scoredObt to mnvTest:obt.

    until intersect {
        if scoredObt:body = _tgtBody {
            set result to get_node_result(_compMode, scoredObt).
            set score to result / _tgtVal.
            set intersect to true.
        } else if scoredObt:hasnextpatch {
            set scoredObt to scoredObt:nextpatch.
        } else  {
            break.
        }
    }
    
    disp_block(list(
        "nodeResult",
        "node result",
        "tgtBody",     _tgtBody,
        "intersect",    intersect,
        "score",        round(score, 5),
        "tgtVal",      _tgtVal,
        "resultVal",    round(result)
    )).
    remove mnvTest.

    return lex("score", score, "result", result, "intersect", intersect).
}


local function improve_node {
    parameter _data,
              _tgtVal,
              _compMode,
              _tgtBody,
              _mnvAcc.

    local limLo to 1 - _mnvAcc.
    local limHi to 1 + _mnvAcc.

    //hill climb to find the best time
    local curScore is get_node_score(_data, _tgtVal, _compMode, _tgtBody).

    // mnvCandidates placeholder
    local mnvCandidates is list().

    // Base maneuver factor - the amount of dV that is used for hill
    // climb iterations
    local mnvFactor is 1.

    if curScore:score > (limLo * 0.975) and curScore:score < (limHi * 1.025) {
        set mnvFactor to 0.05 * mnvFactor.
    } else if curScore:score > (limLo * 0.875) and curScore:score < (limHi * 1.125) {
        set mnvFactor to 0.125 * mnvFactor. 
    } else if curScore:score > (limLo * 0.75) and curScore:score < (limHi * 1.25) {
        set mnvFactor to 0.25 * mnvFactor.
    } else if curScore:score > (limLo * 0.50) and curScore:score < (limHi * 1.50) {
        set mnvFactor to 0.50 * mnvFactor.
    } else if curScore:score > (limLo * 0.25) and curScore:score < (limHi * 1.75) {
        set mnvFactor to 0.75 * mnvFactor.
    } else if curScore:score > -1 * limLo and curScore:score < limHi * 3 {
        set mnvFactor to 1 * mnvFactor.
    } else if curScore:score > -10 * limLo and curScore:score < limHi * 11 {
        set mnvFactor to 2 * mnvFactor. 
    } else {
        set mnvFactor to 5 * mnvFactor.
    }
    
    out_msg("Optimizing node.").

    set mnvCandidates to list(
        list(_data[0] + mnvFactor, _data[1], _data[2], _data[3])  //Time
        ,list(_data[0] - mnvFactor, _data[1], _data[2], _data[3]) //Time
        ,list(_data[0], _data[1], _data[2], _data[3] + mnvFactor) //Prograde
        ,list(_data[0], _data[1], _data[2], _data[3] - mnvFactor) //Prograde
        ,list(_data[0], _data[1] + mnvFactor, _data[2], _data[3]) //Radial
        ,list(_data[0], _data[1] - mnvFactor, _data[2], _data[3]) //Radial
        ,list(_data[0], _data[1], _data[2] + mnvFactor, _data[3]) //Normal
        ,list(_data[0], _data[1], _data[2] - mnvFactor, _data[3]) //Normal
    ).

    local bestCandidate to eval_candidates(_data, mnvCandidates, _tgtVal, _compMode, _tgtBody).
    return bestCandidate.
}


local function improve_transfer_node_timing {
    parameter _data,
              _tgtVal,
              _tgtBody.
    
    local bestCandidate to lex().
    local obtRetro      to choose false if _tgtVal <= 90 else true.
    local nodeScore     to get_node_score(_data, _tgtVal, "tliInc", _tgtBody).
    local intersect     to nodeScore["intersect"].

    out_msg("Optimizing transfer node timing for proper inclination.").
    
    if not intersect {
        until intersect {
            local mnvCandidates to list(
                list(_data[0] + 1, _data[1], _data[2], _data[3])
                ,list(_data[0] - 1, _data[1], _data[2], _data[3])
                ,list(_data[0], _data[1], _data[2], _data[3] + 1)
                ,list(_data[0], _data[1], _data[2], _data[3] - 1)
            ).
            set bestCandidate to eval_candidates(_data, mnvCandidates, _tgtVal, "tliInc", _tgtBody).
            set _data to bestCandidate["_data"].
            set nodeScore to bestCandidate["curScore"]:score.
            set intersect to bestCandidate["curScore"]:intersect.
        }
    }

    set nodeScore to get_node_score(_data, _tgtVal, "tliInc", _tgtBody).
    if obtRetro {
        until nodeScore["intersect"] and nodeScore["result"] > 90 {
            set _data to list(_data[0] - 1, _data[1], _data[2], _data[3]).
            set nodeScore to get_node_score(_data, _tgtVal, "tliInc", _tgtBody).
        }
        return _data.
    } else {
        until nodeScore["intersect"] and nodeScore["result"] <= 90 {
            set _data to list(_data[0] + 1, _data[1], _data[2], _data[3]).
            set nodeScore to get_node_score(_data, _tgtVal, "tliInc", _tgtBody).
        }
        return _data.
    }
}


global function optimize_existing_node {
    parameter _mnvNode,
              _tgtVal,
              _compMode,
              _tgtBody is _mnvNode:obt:body,
              _mnvAcc is 0.005.

    local mnvParam to list(_mnvNode:eta + time:seconds, _mnvNode:radialOut, _mnvNode:normal, _mnvNode:prograde).
    remove _mnvNode.

    local optParam to optimize_node_list(mnvParam, _tgtVal, _compMode, _tgtBody, _mnvAcc).
    
    set _mnvNode to node(optParam[0], optParam[1], optParam[2], optParam[3]).
    add _mnvNode.

    return _mnvNode.
}


global function optimize_node_list {
    parameter _data,
              _tgtVal,
              _compMode,
              _tgtBody,
              _mnvAcc.

    out_msg("Optimizing node.").

    local improvedData  to lex().
    local limLo         to 1 - _mnvAcc.
    local limHi         to 1 + _mnvAcc. 
    local nodeScore     to 0.

    until false {
        set improvedData to improve_node(_data, _tgtVal, _compMode, _tgtBody, _mnvAcc).
        set _data to improvedData["_data"].
        set nodeScore to improvedData["curScore"]:score.
        wait 0.001.
        if nodeScore >= limLo and nodeScore <= limHi {
            break.
        }
    }

    disp_clear_block("nodeOptimize").
    disp_clear_block("nodeResult").

    out_info().
    out_msg("Optimized maneuver found (score: " + nodeScore + ")").
    return _data.
}


global function optimize_transfer_node {
    parameter _mnvNode,
              _tgtAlt,
              _tgtInc,
              _tgtBody,
              _mnvAcc.

    local   mnvParam to list(_mnvNode:eta + time:seconds, _mnvNode:radialOut, _mnvNode:normal, _mnvNode:prograde).
    remove _mnvNode.

    local   optParam to improve_transfer_node_timing(mnvParam, _tgtInc, _tgtBody).
    set     optParam to optimize_node_list(optParam, _tgtAlt, "pe", _tgtBody, _mnvAcc).
    set     _mnvNode to node(optParam[0], optParam[1], optParam[2], optParam[3]).
    add _mnvNode.

    return _mnvNode.
}



//-- WIP --//
local function get_node_multi_score {
    parameter _data,     // mnv list
              _tgtList,  // list of target parameters in format: (tgtBody, tgtAlt, tgtInc, tgtLAN, tgtArgPe)
              _tgtAcc.   // Accuracy factor

    local intersect to false.
    local mnvTest   to node(_data[0], _data[1], _data[2], _data[3]).
    local result    to -999999.
    local score     to -999999.
    local tgtBody   to _tgtList[0].
    local tgtAlt    to _tgtList[1].
    local tgtInc    to _tgtList[2].
    local tgtLAN    to _tgtList[3].
    local tgtArgPe  to _tgtList[4].

    add mnvTest.
    local scoredObt to mnvTest:obt.
    local scoredObtPeriod to scoredObt:period.

    until intersect {
        if scoredObt:body = tgtBody {
            set intersect to true.
        } else if scoredObt:hasnextpatch {
            set scoredObt to scoredObt:nextpatch.
        } else  {
            return lex("intersect", intersect). // Return a lex with only the intersect value
        }
    }

    

    return false.
}