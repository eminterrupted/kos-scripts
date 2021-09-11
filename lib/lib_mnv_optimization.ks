runOncePath("0:/lib/lib_disp").

// -- Hill Climbing
//#region
// Evaluates candidates
local function mnv_eval_candidates
{
    parameter data,
              candList,
              tgtVal,
              tgtBody,
              compMode.

    local curScore to mnv_score(data, tgtVal, tgtBody, compMode).
    
    for c in candList 
    {
        local candScore to mnv_score(c, tgtVal, tgtBody, compMode).
        if candScore:intercept 
        {
            if candScore:result > tgtVal 
            {
                if candScore:score < curScore:score 
                {
                    //set curScore to mnv_score(c, tgtVal, tgtBody, compMode).
                    set data to c.
                }
            } 
            else if candScore:result < tgtVal 
            {
                if candScore:score > curScore:score 
                {
                    //set curScore to mnv_score(c, tgtVal, tgtBody, compMode).
                    set data to c.
                }
            }
        }
    }

    return lex("data", data, "curScore", curScore).
}


// Returns a list of candidates given node data and addition factors
global function mnv_get_candidates
{
    parameter data,
              mnvFactor,
              timeFactor to 1,
              radialFactor to 1,
              normalFactor to 1,
              progradeFactor to 1,
              positiveTimeOnly to false.

    local mnvCandidates to list(
        list(data[0] + mnvFactor, data[1], data[2], data[3])  //Time
        ,list(data[0] - mnvFactor, data[1], data[2], data[3]) //Time
        ,list(data[0], data[1] + mnvFactor, data[2], data[3]) //Radial
        ,list(data[0], data[1] - mnvFactor, data[2], data[3]) //Radial
        ,list(data[0], data[1], data[2] + mnvFactor, data[3]) //Normal
        ,list(data[0], data[1], data[2] - mnvFactor, data[3]) //Normal
        ,list(data[0], data[1], data[2], data[3] + mnvFactor) //Prograde
        ,list(data[0], data[1], data[2], data[3] - mnvFactor) //Prograde
    ).
    if progradeFactor = 0
    {
        mnvCandidates:remove(7).
        mnvCandidates:remove(6).    
    }
    if normalFactor = 0
    {
        mnvCandidates:remove(5).
        mnvCandidates:remove(4).
    }
    if radialFactor = 0
    {
        mnvCandidates:remove(3).
        mnvCandidates:remove(2).
    }
    if timeFactor = 0
    {
        mnvCandidates:remove(1).
        mnvCandidates:remove(0).
    }
    if positiveTimeOnly
    {
        mnvCandidates:remove(1).
    }

    return mnvCandidates.
}

// Returns a maneuver factor for multiplication by the individual node component factors
local function mnv_factor
{
    parameter score.

    local mnvFactor to 1.

    // Score-based
    // if      score >= -0.95 and score <= 1.05   set mnvFactor to (score * 0.01)  * mnvFactor.
    // else if score >= -0.75 and score <= 1.25   set mnvFactor to (score * 0.1)   * mnvFactor.
    // else if score >= -0.50 and score <= 1.50   set mnvFactor to (score * 0.5)   * mnvFactor.
    // else if score >= -1.0  and score <= 2.0    set mnvFactor to score           * mnvFactor.
    // else if score >= -100  and score <= 101    set mnvFactor to (score * 2)     * mnvFactor.
    // else set mnvFactor to 250. 

    // Newest
    if score >= 0.975        and score <= 1.025 set mnvFactor to mnvFactor * 0.025.
    else if score >= 0.950   and score <= 1.050 set mnvFactor to mnvFactor * 0.035.
    else if score >= 0.925   and score <= 1.075 set mnvFactor to mnvFactor * 0.05. 
    else if score >= 0.85    and score <= 1.15  set mnvFactor to mnvFactor * 0.125. 
    else if score >= 0.75    and score <= 1.25  set mnvFactor to mnvFactor * 0.25.
    else if score >= 0.65    and score <= 1.35  set mnvFactor to mnvFactor * 0.50.
    else if score >= 0.5     and score <= 1.5   set mnvFactor to mnvFactor * 0.75.
    else if score >= 0.25    and score <= 1.75  set mnvFactor to mnvFactor * 1.
    else if score >= 0       and score <= 2     set mnvFactor to mnvFactor * 2.
    else if score >= -4      and score <= 5     set mnvFactor to mnvFactor * 4.
    else if score >= -10     and score <= 11    set mnvFactor to mnvFactor * 5.
    else if score >= -100    and score <= 101   set mnvFactor to mnvFactor * 10.
    else set mnvFactor to mnvFactor * 25.

    // Reference
    // if score > 0.975        and score < 1.025   set mnvFactor to mnvFactor * 0.05.
    // else if score > 0.925   and score < 1.075   set mnvFactor to mnvFactor * 0.125. 
    // else if score > 0.85    and score < 1.15    set mnvFactor to mnvFactor * 0.25. 
    // else if score > 0.75    and score < 1.25    set mnvFactor to mnvFactor * 0.50.
    // else if score > 0.65    and score < 1.35    set mnvFactor to mnvFactor * 0.75.
    // else if score > 0.5     and score < 1.5     set mnvFactor to mnvFactor * 1.
    // else if score > -10     and score < 11      set mnvFactor to mnvFactor * 2. 
    // else set mnvFactor to mnvFactor * 5.

    return mnvFactor.
}


// Improves a maneuver node based on tgtVal and compMode
global function mnv_improve_node 
{
    parameter data,
              tgtVal,
              tgtBody,
              compMode,
              changeModes.

    
    //hill climb to find the best time
    local curScore is mnv_score(data, tgtVal, tgtBody, compMode).

    // mnvCandidates placeholder
    local bestCandidate  to list().
    local mnvCandidates  to list().
    local timeFactor     to changeModes[0].
    local radialFactor   to changeModes[1].
    local normalFactor   to changeModes[2].
    local progradeFactor to changeModes[3].

    // Base maneuver factor - the amount of dV that is used for hill
    // climb iterations
    local mnvFactor is mnv_factor(curScore["score"]).
    
    disp_info("Optimizing node.").

    set mnvCandidates to mnv_get_candidates(data, mnvFactor, timeFactor, radialFactor, normalFactor, progradeFactor).
    set bestCandidate to mnv_eval_candidates(data, mnvCandidates, tgtVal, tgtBody, compMode).
    return bestCandidate.
}


// Optimizes an exit node for highest ap
global function mnv_optimize_exit_ap
{
    parameter mnvNode,
              apThresh.
    
    // Sweep timing to lowest Pe
    local lastAp to mnvNode:orbit:nextPatch:apoapsis.
    remove mnvNode.
    until false
    {
        add mnvNode.
        disp_info("Current Ap: " + mnvNode:orbit:nextPatch:apoapsis).
        disp_info2("LastAp    : " + lastAp).
        if lastAp > mnvNode:orbit:nextPatch:apoapsis or lastAp >= apThresh
        {
            remove mnvNode.
            break.
        }
        set lastAp to mnvNode:orbit:nextPatch:apoapsis. 
        remove mnvNode.
        set mnvNode to mnv_opt_change_node(mnvNode, "time", 10).
    }
    disp_info().
    disp_info2().
    return mnvNode.
}


// Optimizes an exit node for lowest pe
global function mnv_optimize_exit_pe
{
    parameter mnvNode,
              peThresh,
              tgtBody is ship:body:body.
    
    // Sweep timing to lowest Pe
    if not hasNode add mnvNode.
    local lastPe to mnvNode:orbit:nextPatch:periapsis.
    remove mnvNode.
    until false
    {
        add mnvNode.
        disp_info("Current Pe: " + mnvNode:orbit:nextPatch:periapsis).
        disp_info2("LastPe    : " + lastPe).
        if (lastPe < mnvNode:orbit:nextPatch:periapsis or lastPe <= peThresh) and mnvNode:orbit:nextPatch:body = tgtBody
        {
            remove mnvNode.
            break.
        }
        set lastPe to mnvNode:orbit:nextPatch:periapsis. 
        remove mnvNode.
        set mnvNode to mnv_opt_change_node(mnvNode, "time", 10).
    }
    disp_info().
    disp_info2().

    return mnvNode.
}

global function mnv_opt_return_node
{
    parameter mnvNode,
              returnBody,
              returnAlt.

    local data  to list(mnvNode:time, mnvNode:radialOut, mnvNode:normal, mnvNode:prograde).
    set data    to mnv_optimize_node_data(data, returnAlt, returnBody, "pe", "1101").
    return node(data[0], data[1], data[2], data[3]).
}

//#region -- Transfer Nodes
// Optimizes a transfer node to another vessel using position prediction and hill climbing.
global function mnv_opt_object_transfer_node
{
    parameter mnvNode,
              tgtVAng is 0.25.

    local bestCandidate to list().
    local candidates    to list().
    local data          to list(mnvNode:time, mnvNode:radialOut, mnvNode:normal, mnvNode:prograde).

    local orbitCount    to 0.
    local nodeScore     to mnv_score(data, tgtVAng, target:body, "rendezvousAng").
    local curScore      to nodeScore["score"].
    local intercept     to nodeScore["intercept"].
    local mnvFactor     to mnv_factor(curScore).

    until allNodes:length = 0
    {
        remove nextNode.
    }
    
    // Make sure we will be in the same SOI
    if not intercept 
    {
        set data to mnv_optimize_node_data(data, (target:orbit:semiMajorAxis - target:body:radius) * 2, target:body, "pe").
    }
    
    // Hill climb - eval candidates until within acceptable range
    until curScore >= 0.995 and curScore <= 1.005
    {
        if data[0] <= (time:seconds + (ship:orbit:period * orbitCount))
        {
            set orbitCount to orbitCount + 4. 
            set data to list(data[0] + (ship:orbit:period * orbitCount), data[1], data[2], data[3]).
        }
        set mnvFactor  to mnv_factor(curScore).
        set candidates to mnv_get_candidates(data, mnvFactor, 10, 0, 0, 0).
        set bestCandidate to mnv_eval_candidates(data, candidates, tgtVAng, target:body, "rendezvousAng").
        set data to bestCandidate["data"].

        set curScore to bestCandidate["curScore"]["score"].
    }

    clr_disp().
    
    set mnvNode to node(data[0], data[1], data[2], data[3]).
    return mnvNode.
}

// Optimizes a standard transfer node to another celestial body (not ships!)
global function mnv_opt_transfer_node
{
    parameter mnvNode,
              tgtBody,
              tgtAlt,
              tgtInc.

    local  data         to list(mnvNode:time, mnvNode:radialOut, mnvNode:normal, mnvNode:prograde + 1).
    if hasNode remove mnvNode.

    local optimizedData to list().
    local obtRetro      to choose false if tgtInc <= 90 and tgtInc >= -90 else true.
    
    local nodeScore     to mnv_score(data, tgtInc, tgtBody, "tliInc").
    local intercept     to nodeScore["intercept"].

    disp_msg("Adjusting timing to intercept").
    
    if not intercept 
    {
        until intercept 
        {
            set   data    to list(data[0] + 100, data[1], data[2], data[3]).
            local mnv to node(data[0], data[1], data[2], data[3]).
            add   mnv.
            local testPatch to nav_next_patch_for_node(mnv).
            
            wait 0.01.

            if testPatch:body = tgtBody
            {
                remove mnv.
                set intercept to true.
            }
            else 
            {
                remove mnv.
            }
        }
    }
    
    disp_msg("Adjusting timing for desired orbital direction").

    set nodeScore to mnv_score(data, tgtInc, tgtBody, "tliInc").
    if obtRetro 
    {
        until nodeScore["intercept"] and nodeScore["result"] > 90 
        {
            set data to list(data[0] - 1, data[1], data[2], data[3]).
            set nodeScore to mnv_score(data, tgtInc, tgtBody, "tliInc").
            wait 0.01.
        }
        set optimizedData to data.
    } 
    else 
    {
        until nodeScore["intercept"] and nodeScore["result"] <= 90 
        {
            set data to list(data[0] + 1, data[1], data[2], data[3]).
            set nodeScore to mnv_score(data, tgtInc, tgtBody, "tliInc").
            wait 0.01.
        }
        set optimizedData to data.
    }
    disp_msg().
    clr_disp().
    set optimizedData to mnv_optimize_node_data(optimizedData, tgtAlt, tgtBody, "pe").
    return node(optimizedData[0], optimizedData[1], optimizedData[2], optimizedData[3]).
}
//#endregion


// Optimize a node list, obvi
global function mnv_optimize_node_data
{
    parameter data,
              tgtVal,
              tgtBody,
              compMode,
              changeModes is list(10, 1, 1, 1),
              accVal is 0.005.

    disp_info("Optimizing node.").

    local iteration     to 0.
    local improvedData  to lex().
    local lastScore     to 0.
    local limLo         to 1 - accVal.
    local limHi         to 1 + accVal.
    local nodeScore     to 0.

    until iteration >= 10
    {
        set lastScore to mnv_score(data, tgtVal, tgtBody, compMode):score.
        set improvedData to mnv_improve_node(data, tgtVal, tgtBody, compMode, changeModes).
        set data to improvedData["data"].
        set nodeScore to improvedData["curScore"]:score.
        if nodeScore >= limLo and nodeScore <= limHi 
        {
            break.
        }
        else if round(nodeScore, 12) = round(lastScore, 12)
        {
            print "Same score iteration: " + iteration at (2, 35).
            set iteration to iteration + 1.
            if iteration = 10 disp_info2("Reached same score iteration limit: " + iteration).
        }
        else 
        {
            set iteration to 0.
            print "Same score iteration: 0 " at (2, 35).
        }
    }
    print "                        " at (2, 25).
    disp_info("Optimized maneuver found (score: " + round(nodeScore, 5) + ")").
    clr_disp(). 
    return data.
}


// Optimize a node list, obvi
global function mnv_opt_result
{
    parameter compMode, 
              testOrbit.

    if compMode = "pe"          return testOrbit:periapsis.
    else if compMode = "ap"     return testOrbit:apoapsis. 
    else if compMode = "inc"    return testOrbit:inclination.
    else if compMode = "tliInc" return testOrbit:inclination.
    else if compMode = "lan"    return testOrbit:longitudeOfAscendingNode.
    else if compMode = "argpe"  return testOrbit:argumentofperiapsis.
    else if compMode = "impactPos" return addons:tr:impactPos.
    else if compMode = "impactPosLat" return addons:tr:impactPos:lat.
    else if compMode = "impactPosLng" return addons:tr:impactPos:lng.
    else if compMode = "rendezvousAng"
    {
        local rendezvousTime to nextNode:time + (nextNode:orbit:period / 2).
        local targetVelocity to velocityAt(target, rendezvousTime).
        local myVelocity     to velocityAt(ship, rendezvousTime).
        return vang(targetVelocity:orbit, myVelocity:orbit).
    }
}


global function mnv_opt_simple_node 
{
    parameter mnvNode,
              tgtVal,
              compMode,
              tgtBody is ship:body,
              accVal is 0.005,
              changeModes is list(10, 1, 1, 1).

    local data to list(mnvNode:time, mnvNode:radialOut, mnvNode:normal, mnvNode:prograde).
    set data to mnv_optimize_node_data(data, tgtVal, tgtBody, compMode, changeModes, accVal).
    return node(data[0], data[1], data[2], data[3]).
}

global function mnv_score
{
    parameter data,
              tgtVal,
              tgtBody,
              compMode.

    local intercept to false.
    local mnvTest   to node(data[0], data[1], data[2], data[3]).
    local result to -999999.
    local score to -999999.

    add mnvTest.
    local scoredOrbit to mnvTest:orbit.

    until intercept
    {
        if scoredOrbit:body = tgtBody
        {
            set result to mnv_opt_result(compMode, scoredOrbit).
            if result:typeName = "GeoCoordinates" 
            {
                local latCheck to result:lat / tgtVal:lat.
                local lngCheck to result:lng / tgtVal:lng.
                set score to (latCheck + (3 * lngCheck)) / 4.
            }
            else
            {
                set score to result / tgtVal.
            }
            set intercept to true.
        }
        else if scoredOrbit:hasNextPatch
        {
            set scoredOrbit to scoredOrbit:nextPatch.
        }
        else
        {
            break.
        }
    }
    disp_mnv_score(tgtVal, tgtBody, intercept, result, score).
    remove mnvTest.

    return lex("score", score, "result", result, "intercept", intercept).
}
//#endregion

// Basic mnv change function
global function mnv_opt_change_node 
{
    parameter checkNode,
              valToChange,
              changeAmount.

    if valToChange      = "time"     return node(checkNode:time + changeAmount, checkNode:radialOut, checkNode:normal, checkNode:prograde).
    else if valToChange = "prograde" return node(checkNode:time, checkNode:radialOut, checkNode:normal, checkNode:prograde + changeAmount).
    else if valToChange = "normal"   return node(checkNode:time, checkNode:radialOut, checkNode:normal + changeAmount, checkNode:prograde).
    else if valToChange = "radial"   return node(checkNode:time, checkNode:radialOut + changeAmount, checkNode:normal, checkNode:prograde).
}