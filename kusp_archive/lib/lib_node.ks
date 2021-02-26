@lazyGlobal off.

runOncePath("0:/lib/lib_display").
runOncePath("0:/lib/lib_deltav").
runOncePath("0:/lib/lib_nav").

// Functions
global function add_node_mun_return 
{
    parameter tgtAlt.

    local mnvNode to node(time:seconds + eta:periapsis, 0, 0, 0).
    add mnvNode.

    // Make sure we add a node that escapes
    until mnvNode:orbit:hasNextPatch
    {
        local nodeParam to list(mnvNode:time, mnvNode:radialout, mnvNode:normal, mnvNode:burnvector:mag).
        remove mnvNode.
        set mnvNode to node(nodeParam[0], nodeParam[1], nodeParam[2], nodeParam[3] + 25).
        add mnvNode.
        wait 0.01.
    }
    

    // Find the time to burn that will give us the lowest Pe.
    local lastPe to ship:body:altitude + 5000.
    until false
    {
        disp_block(list(
            "return",
            "return data",
            "targetPe", tgtAlt,
            "currentPe", mnvNode:orbit:nextpatch:periapsis,
            "lastPe", lastPe
        )).
        if mnvNode:orbit:nextPatch:periapsis >= lastPe and lastPe < ship:body:altitude 
        {
            break.
        }
        else
        {
            local nodeParam to list(mnvNode:time, mnvNode:radialout, mnvNode:normal, mnvNode:burnvector:mag).
            set lastPe to mnvNode:orbit:nextPatch:periapsis. 
            remove mnvNode.
            set mnvNode to node(nodeParam[0] + 30, nodeParam[1], nodeParam[2], nodeParam[3]).
            add mnvNode.
            wait 0.01.
        }
    }

    local nextApEta to mnvNode:orbit:nextpatch:eta:apoapsis.
    local nextPeEta to mnvNode:orbit:nextpatch:eta:periapsis.
    local nodeTime  to choose nextApEta if nextApEta < nextPeEta else 3600 + time:seconds + mnvNode:orbit:nextpatcheta.
    local dv        to get_dv_for_retrograde(tgtAlt, nextPeEta, mnvNode:obt:nextPatch:body).

    set mnvNode to node(nodeTime, 0, 0, dv).
    add mnvNode.
    set mnvNode to optimize_existing_node(mnvNode, tgtAlt, "pe").
}


global function add_node_to_plan 
{
    parameter mnv.

    //Maneuver node is time, radial, normal, prograde.
    if career():canmakenodes 
    {
        set mnv to node(mnv[0], mnv[1], mnv[2], mnv[3]).
        add mnv.
        return mnv.
    }
}


//TODO - Add a rendezvous node with optional phase angle
global function add_rendezvous_node 
{
    parameter _mnvObj,
              _tgtAlt,
              _tgtObj.

    return false.
}


global function add_transfer_node 
{
    parameter mnvObj,
              tgtAlt,
              impact is false.

    local mnvList to list(mnvObj["nodeAt"], 0, 0, mnvObj["dv"]).
    local mnvNode to node(mnvList[0],mnvList[1], mnvList[2], mnvList[3]).
    
    add mnvNode.
    until nextNode:obt:hasnextpatch 
    {
        local dv to mnvNode:burnvector:mag.
        remove mnvNode.
        set mnvNode to node(mnvList[0],mnvList[1], mnvList[2], dv + 1).
        add mnvNode.
        wait 0.1.
    }

    if not impact 
    {
        local mnvAcc to 0.005.
        set mnvNode to optimize_existing_node(mnvNode, tgtAlt, "pe", target, mnvAcc).
    }

    set mnvObj["nodeAt"] to time:seconds + mnvNode:eta.
    set mnvObj["burnEta"] to (mnvNode:eta + time:seconds) - (mnvObj["burnDur"] / 2).
    set mnvObj["mnv"] to mnvNode.

    return mnvObj.
}


global function add_capture_node 
{
    parameter tgtAlt.

    local dv to get_dv_for_prograde(tgtAlt, ship:periapsis).
    local mnv to list(time:seconds + eta:periapsis, 0, 0, dv).

    local mnvNode to node(mnv[0], mnv[1], mnv[3], mnv[3]).
    add mnvNode.

    until not mnvNode:orbit:hasNextPatch 
    {
        set mnv to list(mnv[0], mnv[1], mnv[2], mnv[3] - 5).
        set mnvNode to node(mnv[0], mnv[1], mnv[2], mnv[3]).
        if hasNode remove nextNode.
        add mnvNode.
        wait 0.01.
    }

    until mnvNode:orbit:apoapsis <= max(tgtAlt, ship:periapsis + 1000) 
    {
        if hasNode remove nextNode.
        set mnv to list(mnv[0], mnv[1], mnv[2], mnv[3] - 0.25).
        set mnvNode to node(mnv[0], mnv[1], mnv[2], mnv[3]).
        add mnvNode.
        wait 0.01.
    }
    
    return mnvNode.
}


global function add_optimized_node 
{
    parameter _mnvParam,
              _tgtAlt,
              _compMode,
              _tgtBody,
              _mnvAcc.

    local mnv to optimize_node_list(_mnvParam, _tgtAlt, _compMode, _tgtBody, _mnvAcc).
    set mnv to add_node_to_plan(mnv).

    return mnv.
}


global function add_simple_circ_node 
{
    parameter _nodeAt,
              _tgtAlt,
              _mnvAcc is 0.01.

    local dv to choose get_dv_for_retrograde(_tgtAlt, ship:apoapsis) if _nodeAt = "pe" else get_dv_for_prograde(_tgtAlt, ship:periapsis).
    if dv > 9999 set dv to 50.

    local mnv is list().
    local mode is "".

    if _nodeAt = "ap" 
    {
        set mnv to list(time:seconds + eta:apoapsis, 0, 0, dv).
        set mode to "pe".
    } 
    else 
    {
        set mnv to list(time:seconds + eta:periapsis, 0, 0, dv).
        set mode to "ap".
    }

    set mnv to optimize_node_list(mnv, _tgtAlt, mode, ship:body, _mnvAcc).
    set mnv to node(mnv[0], mnv[1], mnv[2], mnv[3]).
    add mnv.
    //set mnv to add_node_to_plan(mnv).
    
    return mnv.
}


local function eval_candidates 
{
    parameter _data,
              _candList,
              _tgtVal,
              _compMode,
              _tgtBody.

    local curScore to get_node_score(_data, _tgtVal, _compMode, _tgtBody).
    
    for c in _candList 
    {
        local candScore to get_node_score(c, _tgtVal, _compMode, _tgtBody).
        if candScore:intercept 
        {
            if candScore:result > _tgtVal 
            {
                if candScore:score < curScore:score 
                {
                    set curScore to get_node_score(c, _tgtVal, _compMode, _tgtBody).
                    set _data to c.
                }
            } 
            else if candScore:result < _tgtVal 
            {
                if candScore:score > curScore:score 
                {
                    set curScore to get_node_score(c, _tgtVal, _compMode, _tgtBody).
                    set _data to c.
                }
            }
        }
    }

    return lex("_data", _data, "curScore", curScore).
}


global function exec_node 
{
    parameter nd.
    
    local sVal to lookDirUp(nd:burnvector, sun:position).
    lock steering to sVal.

    local tVal to 0.
    lock throttle to tVal.

    //vNext
    // local startVel to ship:velocity:orbit.
    // local dvToGo to 9999999.
    // set tVal to 1. 
    // until dvToGo <= 0.1 
    // {
    //     set sVal to nd:burnVector.
    //     set dvToGo to nd:burnVector:mag - sqrt(abs(vdot(nd:burnVector, (ship:velocity:orbit - startVel)))).

    //     update_display().
    //     disp_burn_data().
    //     wait 0.01.
    // }
    // set tVal to 0.

    // Old
    local dv0 to nd:deltav.
    local maxAcc to ship:maxThrust / ship:mass.

    until false
    {
        set maxAcc to ship:maxThrust / ship:mass.

        if vdot(dv0, nd:deltaV) <= 0 
        {
            set tVal to 0.
            break.
        }
        else
        {
            set tVal to max(0, min(nd:deltaV:mag / maxAcc, 1)).
        }

        update_display().
        disp_burn_data().
    }

    remove nd.
    disp_clear_block("burn_data").
}


local function get_node_result 
{

    parameter _compMode,
              _obt.

    if _compMode = "pe" 
    {     
        return _obt:periapsis.
    } 
    else if _compMode = "ap" 
    {
        return _obt:apoapsis.
    } 
    else if _compMode = "inc" 
    {
        return _obt:inclination.
    } 
    else if _compMode = "tliInc" 
    { 
        return _obt:inclination.
    } 
    else if _compMode = "lan" 
    {
        return _obt:longitudeOfAscendingNode.
    } 
    else if _compMode = "argpe" 
    {
        return _obt:argumentofperiapsis.
    }
}


local function get_node_score 
{
    parameter _data,
              _tgtVal,
              _compMode,
              _tgtBody.

    local intercept to false.
    local mnvTest to node(_data[0], _data[1], _data[2], _data[3]).
    local result to -999999.
    local score to -999999.
    
    add mnvTest.
    local scoredObt to mnvTest:obt.

    until intercept 
    {
        if scoredObt:body = _tgtBody 
        {
            set result to get_node_result(_compMode, scoredObt).
            set score to result / _tgtVal.
            set intercept to true.
        } 
        else if scoredObt:hasnextpatch 
        {
            set scoredObt to scoredObt:nextpatch.
        } 
        else
        {
            break.
        }
    }
    
    disp_block(list(
        "nodeResult",
        "node result",
        "tgtBody",     _tgtBody,
        "intercept",    intercept,
        "score",        round(score, 5),
        "tgtVal",      _tgtVal,
        "resultVal",    round(result)
    )).
    remove mnvTest.

    return lex("score", score, "result", result, "intercept", intercept).
}


local function improve_node 
{
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

    if curScore:score > (limLo * 0.975) and curScore:score < (limHi * 1.025) 
    {
        set mnvFactor to 0.05 * mnvFactor.
    } 
    else if curScore:score > (limLo * 0.875) and curScore:score < (limHi * 1.125) 
    {
        set mnvFactor to 0.125 * mnvFactor. 
    } 
    else if curScore:score > (limLo * 0.75) and curScore:score < (limHi * 1.25) 
    {
        set mnvFactor to 0.25 * mnvFactor.
    } 
    else if curScore:score > (limLo * 0.50) and curScore:score < (limHi * 1.50) 
    {
        set mnvFactor to 0.50 * mnvFactor.
    } 
    else if curScore:score > (limLo * 0.25) and curScore:score < (limHi * 1.75) 
    {
        set mnvFactor to 0.75 * mnvFactor.
    } 
    else if curScore:score > -1 * limLo and curScore:score < limHi * 3 
    {
        set mnvFactor to 1 * mnvFactor.
    } 
    else if curScore:score > -10 * limLo and curScore:score < limHi * 11 
    {
        set mnvFactor to 2 * mnvFactor. 
    } 
    else 
    {
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


local function improve_transfer_node 
{
    parameter _data,
              _tgtVal,
              _tgtBody.
    
    local obtRetro      to choose false if _tgtVal <= 90 else true.
    local nodeScore     to get_node_score(_data, _tgtVal, "tliInc", _tgtBody).
    local intercept     to nodeScore["intercept"].

    out_msg("Current maneuver does not intercept target, adjusting timing").
    
    if not intercept 
    {
        until intercept 
        {
            set   _data    to list(_data[0] + 10, _data[1], _data[2], _data[3]).
            local _mnvNode to node(_data[0], _data[1], _data[2], _data[3]).
            add   _mnvNode.
            local np to last_patch_for_node(_mnvNode).

            if np:body = _tgtBody
            {
                remove _mnvNode.
                set intercept to true.
            }
            else 
            {
                remove _mnvNode.
            }
        }
    }
    
    out_msg("Optimizing transfer node timing for proper orbital direction.").

    set nodeScore to get_node_score(_data, _tgtVal, "tliInc", _tgtBody).
    if obtRetro 
    {
        until nodeScore["intercept"] and nodeScore["result"] > 90 
        {
            set _data to list(_data[0] - 1, _data[1], _data[2], _data[3]).
            set nodeScore to get_node_score(_data, _tgtVal, "tliInc", _tgtBody).
        }
        return _data.
    } 
    else 
    {
        until nodeScore["intercept"] and nodeScore["result"] <= 90 
        {
            set _data to list(_data[0] + 1, _data[1], _data[2], _data[3]).
            set nodeScore to get_node_score(_data, _tgtVal, "tliInc", _tgtBody).
        }
        return _data.
    }
}


global function last_patch 
{
    local curPatch to ship:orbit.
    until not curPatch:hasNextPatch 
    {
        set curPatch to curPatch:nextPatch.
    }

    return curPatch.
}


// Returns the last patch for a given node
global function last_patch_for_node
{
    parameter _node.

    local curPatch to _node:orbit.
    until not curPatch:hasNextPatch 
    {
        set curPatch to curPatch:nextPatch.
    }

    return curPatch.
}


global function optimize_existing_node 
{
    parameter _mnvNode,
              _tgtVal,
              _compMode,
              _tgtBody is _mnvNode:obt:body,
              _mnvAcc is 0.005.

    local mnvParam to list(_mnvNode:time, _mnvNode:radialOut, _mnvNode:normal, _mnvNode:prograde).
    remove _mnvNode.

    local optParam to optimize_node_list(mnvParam, _tgtVal, _compMode, _tgtBody, _mnvAcc).
    
    set _mnvNode to node(optParam[0], optParam[1], optParam[2], optParam[3]).
    add _mnvNode.

    return _mnvNode.
}


global function optimize_rendezvous_node
{
    parameter _mnvNode,
              _tgt is target.

    local mnvParam  to list(_mnvNode:time, _mnvNode:radialOut, _mnvNode:normal, _mnvNode:prograde).
    local myPos     to vCrs(velocityAt(ship, _mnvNode:time + (_mnvNode:orbit:period / 2)):orbit, ship:body:position).
    local tgtPos    to vCrs(velocityAt(_tgt, _mnvNode:time + (_mnvNode:orbit:period / 2)):orbit, _tgt:body:position).
    lock  posAng    to vAng(myPos, tgtPos).
    
    local function ang_factor  
    {
        if posAng >= 100 return 50.
        else if posAng >= 25 return 10.
        else if posAng >= 5  return 2.5.
        else return 1.
    }

    local done to false.
    until done
    {
        local candidates to list(
            list(mnvParam[0] + ang_factor(), mnvParam[1], mnvParam[2], mnvParam[3])
            //,list(mnvParam[0] - 1, mnvParam[1], mnvParam[2], mnvParam[3])
        ).
        
        for c in candidates
        {
            local lastPosAng to posAng.
            remove _mnvNode.
            set mnvParam to c.
            set _mnvNode to node(mnvParam[0], mnvParam[1], mnvParam[2], mnvParam[3]).
            add _mnvNode.

            set myPos   to positionAt(ship, _mnvNode:time + (_mnvNode:orbit:period / 2)).
            set tgtPos  to positionAt(_tgt, _mnvNode:time + (_mnvNode:orbit:period / 2)).
            out_info("Current position angle diff: " + round(posAng, 5)).
            wait 0.01.
            if posAng <= 0.25
            {
                if posAng >= lastPosAng 
                {
                    out_info("Final position angle diff: " + round(posAng, 5)).
                    wait 1.
                    out_info().
                    set done to true.
                }
            }
        }
    }

    return _mnvNode.
}


global function optimize_node_list 
{
    parameter _data,
              _tgtVal,
              _compMode,
              _tgtBody,
              _mnvAcc.

    out_msg("Optimizing node.").

    local iteration     to 0.
    local improvedData  to lex().
    local lastScore     to 0.
    local limLo         to 1 - _mnvAcc.
    local limHi         to 1 + _mnvAcc. 
    local nodeScore     to 0.

    until iteration >= 10
    {
        set lastScore to get_node_score(_data, _tgtVal, _compMode, _tgtBody):score.
        set improvedData to improve_node(_data, _tgtVal, _compMode, _tgtBody, _mnvAcc).
        set _data to improvedData["_data"].
        set nodeScore to improvedData["curScore"]:score.
        wait 0.01.
        if nodeScore >= limLo and nodeScore <= limHi 
        {
            break.
        }
        else if round(nodeScore, 5) = round(lastScore, 5)
        {
            print "Same score iteration: " + iteration at (2, 25).
            set iteration to iteration + 1.
        }
    }

    print "                        " at (2, 25).
    disp_clear_block("nodeOptimize").
    disp_clear_block("nodeResult").

    out_info().
    out_msg("Optimized maneuver found (score: " + nodeScore + ")").
    return _data.
}


global function optimize_transfer_node 
{
    parameter _mnvNode,
              _tgtAlt,
              _tgtInc,
              _tgtBody,
              _mnvAcc.

    local   mnvParam to list(_mnvNode:eta + time:seconds, _mnvNode:radialOut, _mnvNode:normal, _mnvNode:prograde + 1).
    remove _mnvNode.
    
    local optParam to improve_transfer_node(mnvParam, _tgtInc, _tgtBody).
    set   optParam to optimize_node_list(optParam, _tgtAlt, "pe", _tgtBody, _mnvAcc).
    set   _mnvNode to node(optParam[0], optParam[1], optParam[2], optParam[3]).
    add   _mnvNode.

    return _mnvNode.
}


//-- WIP --//