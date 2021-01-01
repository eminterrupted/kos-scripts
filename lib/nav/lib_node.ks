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


//
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

    local limLo to 1 - _mnvAcc.
    local limHi to 1 + _mnvAcc. 

    until false {
        set _data to improve_node(_data, _tgtVal, _compMode, _tgtBody, _mnvAcc).
        local nodeScore to get_node_score(_data, _tgtVal, _compMode, _tgtBody)["score"].

        // print "_tgtVal    : " + _tgtVal at (2, 20).
        // print "_compMode  : " + _compMode at (2, 21).
        // print "_data[eta] : " + _data[0] at (2, 22).
        // print "_data[rad] : " + _data[1] at (2, 23).
        // print "_data[nrm] : " + _data[2] at (2, 24).
        // print "_data[prg] : " + _data[3] at (2, 25).

        wait 0.001.

        if nodeScore >= limLo and nodeScore <= limHi {
            break.
        }
    }

    out_info().
    out_msg("Optimized maneuver found").
    return _data.
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

    // Base maneuver factor - the amount of dV that is used for hill
    // climb iterations
    local mnvFactor is 1.

    // If this is an altitude-only change (_compMode - ap or pe), adjust for 
    // _tgtBody gravity.
    if _compMode = "ap" or _compMode = "pe" {
        set mnvFactor to mnvFactor * sqrt(_tgtBody:radius) / 500.
    }

    if curScore:score > (limLo * 0.975) and curScore:score < (limHi * 1.025) {
        set mnvFactor to 0.015625 * mnvFactor.
    } else if curScore:score > (limLo * 0.875) and curScore:score < (limHi * 1.125) {
        set mnvFactor to 0.03125 * mnvFactor. 
    // } else if curScore:score > (limLo * 0.75) and curScore:score < (limHi * 1.25) {
    //     set mnvFactor to 0.125 * mnvFactor.
    } else if curScore:score > (limLo * 0.50) and curScore:score < (limHi * 1.50) {
        set mnvFactor to 0.5 * mnvFactor.
    } else if curScore:score > (limLo * 0.25) and curScore:score < (limHi * 1.75) {
        set mnvFactor to 1 * mnvFactor.
    } else if curScore:score > -1 * limLo and curScore:score < limHi * 3 {
        set mnvFactor to 2 * mnvFactor.
    } else if curScore:score > -10 * limLo and curScore:score < limHi * 11 {
        set mnvFactor to 4 * mnvFactor. 
    } else {
        set mnvFactor to 12 * mnvFactor.
    }
    
    out_msg("Optimizing node.").

    local mnvCandidates is list(
        list(_data[0] + mnvFactor, _data[1], _data[2], _data[3]) //Time
        ,list(_data[0] - mnvFactor, _data[1], _data[2], _data[3]) //Time
        ,list(_data[0], _data[1] + mnvFactor, _data[2], _data[3]) //Radial
        ,list(_data[0], _data[1] - mnvFactor, _data[2], _data[3]) //Radial
        ,list(_data[0], _data[1], _data[2] + mnvFactor, _data[3]) //Normal
        ,list(_data[0], _data[1], _data[2] - mnvFactor, _data[3]) //Normal
        ,list(_data[0], _data[1], _data[2], _data[3] + mnvFactor)    //Prograde
        ,list(_data[0], _data[1], _data[2], _data[3] + - mnvFactor) //Prograde

        ).

    // if not _lockTime {
    //     mnvCandidates:add(list(_data[0] + mnvFactor, _data[1], _data[2], _data[3])).
    //     mnvCandidates:add(list(_data[0] - mnvFactor, _data[1], _data[2], _data[3])).
    // }

    for c in mnvCandidates {
        local candScore to get_node_score(c, _tgtVal, _compMode, _tgtBody).
        if candScore:result > _tgtVal {
            if candScore:score < curScore:score {
                set curScore to get_node_score(c, _tgtVal, _compMode, _tgtBody).
                set _data to c.
                out_info("Current score: " + round(curScore:score, 5)).
            }
        } else {
            if candScore:score > curScore:score {
                set curScore to get_node_score(c, _tgtVal, _compMode, _tgtBody).
                set _data to c.
                out_info("Current score: " + round(curScore:score, 5)).
            }
        }
    }

    return _data.
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

    local score to 0.
    local result to 0.
    local mnvTest to node(_data[0], _data[1], _data[2], _data[3]).

    add mnvTest.
    
    if mnvTest:obt:body = _tgtBody {
        set result to get_node_result(_compMode, mnvTest:obt).
    } else if mnvTest:obt:hasNextPatch {
        if mnvTest:obt:nextpatch:body = _tgtBody {
            set result to get_node_result(_compMode, mnvTest:obt:nextPatch).
        } else if mnvTest:obt:nextpatch:hasnextpatch {
            if mnvTest:obt:nextpatch:nextpatch:body = _tgtBody {
                set result to get_node_result(_compMode, mnvTest:obt:nextpatch:nextpatch).
            } else if mnvTest:obt:nextpatch:nextpatch:hasnextpatch {
                if mnvTest:obt:nextpatch:nextpatch:nextpatch:body = _tgtBody {
                    set result to get_node_result(_compMode, mnvTest:obt:nextpatch:nextpatch:nextpatch).
                }
            }
        }
    }
    
    set score to result / _tgtVal.

    remove mnvTest.

    return lex("score", score, "result", result).
}


//-- WIP --//
// global function get_node_for_inc_change {
//     parameter tObt,
//               sObt is ship:orbit.

//     local sInc to sObt:inclination.
//     local sVel to sObt:velocity:orbit:mag.
    
//     local tInc to tObt:inclination.
//     local tVel to tObt:velocity:orbit:mag.

//     local dv to sqrt( sVel ^ 2 + tVel ^ 2 - 2 * sVel * tVel * cos(tInc - sInc)).
    
//     local n to 360 / sObt:period.
//     local meanAnomaly to sObt:meananomalyatepoch + (n * (time:seconds - sObt:epoch)). 
    
//     return true.
// }


global function optimize_node_list_next {
    parameter mnvList,
              tgtObt,
              mode,
              dir is "all".

    out_msg("Optimizing maneuver").

    local cnt to 0. 
    local prevScore to 0.

    until cnt >= 5 {
        set prevScore to get_node_score_next(mnvList, tgtObt, mode)["score"].
        set mnvList to improve_node_next(mnvList, tgtObt, mode, dir).
        local nodeScore to get_node_score_next(mnvList, tgtObt, mode)["score"].

        if nodeScore >= 0.99 and nodeScore <= 1.01 {
            break.
        } else if nodeScore = prevScore {
            set cnt to cnt + 1.
        } else {
            set cnt to 0.
        }
    }

    out_info().
    out_msg("Optimized maneuver found").
    return mnvList.
}


local function get_node_score_next {
    parameter data,
              tgtObt,
              mode.

    local score to 0.
    local scoreAlt to 0.
    local scoreArgPe to 0.
    local scoreInc to 0.

    local mnvTest to node(data[0], data[1], data[2], data[3]).

    add mnvTest.
    
    set scoreAlt to choose get_node_prograde_score(data, tgtObt:periapsis, mode) if mode = "pe" else get_node_prograde_score(data, tgtObt:apoapsis, mode).
    set scoreArgPe to get_node_radial_score(data, tgtObt:argumentOfPeriapsis).
    set scoreInc to get_node_normal_score(data, tgtObt:inclination).

    set score to (scoreAlt:score + scoreArgPe:score + scoreInc:score) / 3.

    wait 0.01.
    remove mnvTest.
    return lex("score", score, "scoreAlt", scoreAlt, "scoreArgPe", scoreArgPe, "scoreInc", scoreInc).
}



local function improve_node_next {
    parameter _data,
              _tgtObt,
              mode,
              dir.


    set mode to choose "pe" if _tgtObt:apoapsis > ship:apoapsis else "ap".
    local tgtAlt to choose _tgtObt:apoapsis if mode = "pe" else _tgtObt:periapsis.

    local best is _data.
    if dir = "all" {
        set best to improve_node_prograde(best, tgtAlt, mode).
        set best to improve_node_radial(best, _tgtObt:argumentofperiapsis, mode).
        set best to improve_node_normal(best, _tgtObt:inclination).
    } else if dir = "prograde" {
        set best to improve_node_prograde(_data, tgtAlt, mode).
    } else if dir = "radial" {
        set best to improve_node_radial(best, _tgtObt:argumentofperiapsis, mode).
    } else if dir = "normal" {
        set best to improve_node_normal(best, _tgtObt:inclination).
    }

    return best.
}



global function improve_node_prograde {
    parameter data,
              tgtAlt,
              mode.

    //hill climb to find the best time
    local curScore is get_node_prograde_score(data, tgtAlt, mode).

    local mnvFactor is 1.0.
    if curScore:score > 0.975 and curScore:score < 1.025 {
        set mnvFactor to 0.0025.
    } else if curScore:score > 0.925 and curScore:score < 1.075 {
        set mnvFactor to 0.005.
    } else if curScore:score > 0.85 and curScore:score < 1.15 {
        set mnvFactor to 0.25.
    } else if curScore:score > 0.75 and curScore:score < 1.25 {
        set mnvFactor to 0.50.
    }
    
    local mnvCandidates is list(
        list(data[0] + mnvFactor, data[1], data[2], data[3])    //Time
        ,list(data[0] - mnvFactor, data[1], data[2], data[3])   //Time
        ,list(data[0], data[1] + mnvFactor, data[2], data[3])   //Radial
        ,list(data[0], data[1] - mnvFactor, data[2], data[3])   //Radial
        ,list(data[0], data[1], data[2] + mnvFactor, data[3])   //Normal
        ,list(data[0], data[1], data[2] - mnvFactor, data[3])   //Normal
        ,list(data[0], data[1], data[2], data[3] + mnvFactor)   //Dv
        ,list(data[0], data[1], data[2], data[3] + - mnvFactor) //Dv
    ).

    for c in mnvCandidates {
        local candScore to get_node_prograde_score(c, tgtAlt, mode).
        if candScore["result"] > tgtAlt {
            if candScore["score"] < curScore["score"] {
                set curScore to get_node_prograde_score(c, tgtAlt, mode).
                set data to c.
                out_info("Current score: " + round(curScore:score, 5)).
            }
        } else {
            if candScore["score"] > curScore["score"] {
                set curScore to get_node_prograde_score(c, tgtAlt, mode).
                set data to c.
                out_info("Current score: " + round(curScore:score, 5)).
            }
        }
    }

    return data.
}


local function get_node_prograde_score {
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


global function improve_node_radial {
    parameter data,
              tgtArgPe,
              mode.

    //hill climb to find the best time
    local curScore is get_node_radial_score(data, tgtArgPe).

    local mnvFactor is 1.
    if curScore:score > 0.975 and curScore:score < 1.025 {
        set mnvFactor to mnvFactor * 0.0025.
    } else if curScore:score > 0.925 and curScore:score < 1.075 {
        set mnvFactor to mnvFactor * 0.005.
    } else if curScore:score > 0.85 and curScore:score < 1.15 {
        set mnvFactor to mnvFactor * 0.25.
    } else if curScore:score > 0.75 and curScore:score < 1.25 {
        set mnvFactor to mnvFactor * 0.50.
    }
    
    local mnvCandidates is list(
        list(data[0] + mnvFactor, data[1], data[2], data[3])    //Time
        ,list(data[0] - mnvFactor, data[1], data[2], data[3])   //Time
        ,list(data[0], data[1] + mnvFactor, data[2], data[3])   //Radial
        ,list(data[0], data[1] - mnvFactor, data[2], data[3])   //Radial
        ,list(data[0], data[1], data[2] + mnvFactor, data[3])   //Normal
        ,list(data[0], data[1], data[2] - mnvFactor, data[3])   //Normal
        ,list(data[0], data[1], data[2], data[3] + mnvFactor)   //Dv
        ,list(data[0], data[1], data[2], data[3] + - mnvFactor) //Dv
    ).

    for c in mnvCandidates {
        local candScore to get_node_prograde_score(c, tgtArgPe, mode).
        if candScore["result"] > tgtArgPe {
            if candScore["score"] < curScore["score"] {
                set curScore to get_node_prograde_score(c, tgtArgPe, mode).
                set data to c.
                out_info("Current score: " + round(curScore:score, 5)).
            }
        } else {
            if candScore["score"] > curScore["score"] {
                set curScore to get_node_prograde_score(c, tgtArgPe, mode).
                set data to c.
                out_info("Current score: " + round(curScore:score, 5)).
            }
        }
    }

    return data.
}


local function get_node_radial_score {
    parameter data,
              tgtArgPe.

    local score to 0.
    local resultArgPe to 0.
    local mnvTest to node(data[0], data[1], data[2], data[3]).

    add mnvTest.
    set resultArgPe to choose mnvTest:obt:argumentofperiapsis if not mnvTest:obt:hasNextPatch else mnvTest:obt:nextpatch:argumentofperiapsis.
    set score to resultArgPe / tgtArgPe.
    
    wait 0.01.
    remove mnvTest.
    return lex("score", score, "result", resultArgPe).
}


global function improve_node_normal {
    parameter data,
              tgtInc.

    //hill climb to find the best time
    local curScore is get_node_normal_score(data, tgtInc).

    local mnvFactor is 0.1.
    if curScore:score > 0.975 and curScore:score < 1.025 {
        set mnvFactor to mnvFactor * 0.0025.
    } else if curScore:score > 0.925 and curScore:score < 1.075 {
        set mnvFactor to mnvFactor * 0.005.
    } else if curScore:score > 0.85 and curScore:score < 1.15 {
        set mnvFactor to mnvFactor * 0.25.
    } else if curScore:score > 0.75 and curScore:score < 1.25 {
        set mnvFactor to mnvFactor *  0.50.
    }
    
    local mnvCandidates is list(
        list(data[0] + mnvFactor, data[1], data[2], data[3])    //Time
        ,list(data[0] - mnvFactor, data[1], data[2], data[3])   //Time
        ,list(data[0], data[1] + mnvFactor, data[2], data[3])   //Radial
        ,list(data[0], data[1] - mnvFactor, data[2], data[3])   //Radial
        ,list(data[0], data[1], data[2] + mnvFactor, data[3])   //Normal
        ,list(data[0], data[1], data[2] - mnvFactor, data[3])   //Normal
        ,list(data[0], data[1], data[2], data[3] + mnvFactor)   //Dv
        ,list(data[0], data[1], data[2], data[3] + - mnvFactor) //Dv
    ).

    for c in mnvCandidates {
        local candScore to get_node_normal_score(c, tgtInc).
        if candScore["result"] > tgtInc {
            if candScore["score"] < curScore["score"] {
                set curScore to get_node_normal_score(c, tgtInc).
                set data to c.
                out_info("Current score: " + round(curScore:score, 5)).
            }
        } else {
            if candScore["score"] > curScore["score"] {
                set curScore to get_node_normal_score(c, tgtInc).
                set data to c.
                out_info("Current score: " + round(curScore:score, 5)).
            }
        }
    }

    return data.
}


local function get_node_normal_score {
    parameter data,
              tgtInc.

    local score to 0.
    local resultInc to 0.
    local mnvTest to node(data[0], data[1], data[2], data[3]).

    add mnvTest.
    set resultInc to choose mnvTest:obt:inclination if not mnvTest:obt:hasNextPatch else mnvTest:obt:nextpatch:inclination.
    set score to resultInc / tgtInc.
    
    wait 0.01.
    remove mnvTest.
    return lex("score", score, "result", resultInc).
}


local function get_node_score_for_orbit {
    parameter data,
              tgtObt.

    local score is 0.
    local resultInc is 0.
    local resultArgPe is 0.
    local resultAp is 0.
    local resultBody is ship:body.

    local mnvTest is node(data[0], data[1], data[2], data[3]).
    add mnvTest.

    if mnvTest:orbit:hasNextPatch {
        set resultBody to mnvTest:orbit:body.
    }
}













global function optimize_arg_pe_existing_node {
    parameter _mnvNode,
              _tgtArgPe,
              _tgtBody is _mnvNode:obt:body,
              _mnvAcc is 0.005.

    local mnvParam to list(_mnvNode:eta + time:seconds, _mnvNode:radialOut, _mnvNode:normal, _mnvNode:prograde).
    remove _mnvNode.

    local optParam to optimize_arg_pe_node_list(mnvParam, _tgtArgPe, _tgtBody, _mnvAcc).
    
    set _mnvNode to node(optParam[0], optParam[1], optParam[2], optParam[3]).
    add _mnvNode.

    return _mnvNode.
}


global function optimize_arg_pe_node_list {
    parameter _data,
              _tgtArgPe,
              _tgtBody,
              _mnvAcc.

    out_msg("Optimizing maneuver").

    local limLo to 1 - _mnvAcc.
    local limHi to 1 + _mnvAcc. 

    until false {
        set _data to improve_arg_pe_node(_data, _tgtArgPe, _tgtBody, _mnvAcc).
        local nodeScore to get_arg_pe_node_score(_data, _tgtArgPe, _tgtBody)["score"].

        wait 0.01.

        if nodeScore >= limLo and nodeScore <= limHi {
            break.
        }
    }
    out_msg("Optimized maneuver found").
    return _data.
}


local function improve_arg_pe_node {
    parameter _data,
              _tgtArgPe,
              _tgtBody,
              _mnvAcc.

    local limLo to 1 - _mnvAcc.
    local limHi to 1 + _mnvAcc.

    //hill climb to find the best time
    local curScore is get_arg_pe_node_score(_data, _tgtArgPe, _tgtBody).

    local mnvFactor is 0.25.
    if curScore:score > (limLo * 0.985) and curScore:score < (limHi * 1.015) {
        set mnvFactor to 0.015625 * mnvFactor.
    } else if curScore:score > (limLo * 0.875) and curScore:score < (limHi * 1.125) {
        set mnvFactor to 0.03125 * mnvFactor. 
    } else if curScore:score > (limLo * 0.75) and curScore:score < (limHi * 1.25) {
        set mnvFactor to 0.125 * mnvFactor.
    } else if curScore:score > (limLo * 0.25) and curScore:score < (limHi * 1.75) {
        set mnvFactor to .5 * mnvFactor.
    } else if curScore:score > -1 * limLo and curScore:score < limHi * 3 {
        set mnvFactor to 1.75 * mnvFactor.
    } else if curScore:score > -10 * limLo and curScore:score < limHi * 11 {
        set mnvFactor to 3 * mnvFactor. 
    } else {
        set mnvFactor to 10 * mnvFactor.
    }
    
    local mnvCandidates is list(
        list(_data[0] + mnvFactor, _data[1], _data[2], _data[3]) //Time
        ,list(_data[0] - mnvFactor, _data[1], _data[2], _data[3]) //Time
        ,list(_data[0], _data[1], _data[2], _data[3] + mnvFactor)    //Prograde
        ,list(_data[0], _data[1], _data[2], _data[3] + - mnvFactor) //Prograde
        ,list(_data[0], _data[1] + mnvFactor, _data[2], _data[3]) //Radial
        ,list(_data[0], _data[1] - mnvFactor, _data[2], _data[3]) //Radial
        ,list(_data[0], _data[1], _data[2] + mnvFactor, _data[3]) //Normal
        ,list(_data[0], _data[1], _data[2] - mnvFactor, _data[3]) //Normal

        ).

    for c in mnvCandidates {
        local candScore to get_arg_pe_node_score(c, _tgtArgPe, _tgtBody).
        if candScore:result > _tgtArgPe {
            if candScore:score < curScore:score {
                set curScore to get_arg_pe_node_score(c, _tgtArgPe, _tgtBody).
                set _data to c.
                out_info("Current score: " + round(curScore:score, 5)).
            }
        } else {
            if candScore:score > curScore:score {
                set curScore to get_arg_pe_node_score(c, _tgtArgPe, _tgtBody).
                set _data to c.
                out_info("Current score: " + round(curScore:score, 5)).
            }
        }
    }

    return _data.
}


local function get_arg_pe_node_score {
    parameter _data,
              _tgtArgPe,
              _tgtBody.

    local score to 0.
    local resultArgPe to 0.
    local mnvTest to node(_data[0], _data[1], _data[2], _data[3]).

    add mnvTest.
  
    if mnvTest:obt:body = _tgtBody {
         set resultArgPe to mnvTest:obt:apoapsis.
    
    } else if mnvTest:obt:hasNextPatch {
        if mnvTest:obt:nextpatch:body = _tgtBody {
            set resultArgPe to mnvTest:obt:nextpatch:apoapsis.
        
        } else if mnvTest:obt:nextpatch:hasnextpatch {
            if mnvTest:obt:nextpatch:nextpatch:body = _tgtBody {
                set resultArgPe to mnvTest:obt:nextpatch:nextpatch:apoapsis.
                
            } else if mnvTest:obt:nextpatch:nextpatch:hasnextpatch {
                if mnvTest:obt:nextpatch:nextpatch:nextpatch:body = _tgtBody {
                    set resultArgPe to mnvTest:obt:nextpatch:nextpatch:nextpatch:apoapsis.
                }
            }
        }
    }

    set score to resultArgPe / _tgtArgPe.

    remove mnvTest.

    return lex("score", score, "result", resultArgPe).
}
