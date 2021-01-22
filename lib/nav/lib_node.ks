@LazyGlobal off.

RunOncePath("0:/lib/display/lib_display").
RunOncePath("0:/lib/nav/lib_deltav").
RunOncePath("0:/lib/nav/lib_nav").

// Functions
global function AddNodeToPlan {
    parameter _maneuver.

    //Maneuver node is time, radial, normal, prograde.
    if career():CanMakeNodes {
        set _maneuver to node(_maneuver[0], _maneuver[1], _maneuver[2], _maneuver[3]).
        add _maneuver.
        return _maneuver.
    }
}


//TODO - add a rendezvous node with optional phase angle
global function AddRendezvousNode {
    parameter _maneuverObj,
              _targetAlt,
              _targetObj.

    return false.
}


global function AddReturnNode {
    parameter _targetAlt.

    local dV is 0.
    local maneuverNode to node(Time:Seconds + Eta:Periapsis, 0, 0, 0).
    add maneuverNode.

    until NextNode:Orbit:HasNextPatch {
        remove maneuverNode.
        set dV to dV + 5.
        set maneuverNode to node(Time:Seconds + Eta:Periapsis, 0, 0, dV).
        add maneuverNode.
        wait 0.01.
    }

    set dV to GetDVForRetrograde(_targetAlt, maneuverNode:Orbit:NextPatch:Periapsis, maneuverNode:Orbit:NextPatch:Body).
    set maneuverNode to node(7200 + Time:Seconds + maneuverNode:Orbit:NextPatchEta, 0, 0, dV).
    add maneuverNode.

    set maneuverNode to OptimizeManeuverNode(maneuverNode, _targetAlt, "pe").
}


global function AddTransferNode {
    parameter _maneuverObj,
              _targetAlt,
              _impact is false.

    local maneuverList to list(_maneuverObj["nodeAt"], 0, 0, _maneuverObj["dV"]).
    local maneuverNode to node(maneuverList[0],maneuverList[1], maneuverList[2], maneuverList[3]).
    
    add maneuverNode.
    until nextNode:Orbit:HasNextPatch {
        local dV to maneuverNode:burnvector:mag.
        remove maneuverNode.
        set maneuverNode to node(maneuverList[0],maneuverList[1], maneuverList[2], dV + 1).
        add maneuverNode.
        wait 0.1.
    }

    if not _impact {
        local maneuverAccuracy to 0.005.
        set maneuverNode to OptimizeManeuverNode(maneuverNode, _targetAlt, "pe", Target, maneuverAccuracy).
    }

    set _maneuverObj["nodeAt"] to Time:Seconds + maneuverNode:Eta.
    set _maneuverObj["burnEta"] to (maneuverNode:Eta + Time:Seconds) - (_maneuverObj["burnDur"] / 2).
    set _maneuverObj["mnv"] to maneuverNode.

    return _maneuverObj.
}


global function AddCaptureNode {
    parameter _targetAlt.

    local dV to GetDVForPrograde(_targetAlt, ship:Periapsis).
    local maneuver to list(Time:Seconds + Eta:Periapsis, 0, 0, dV).

    local maneuverNode to node(maneuver[0], maneuver[1], maneuver[3], maneuver[3]).
    add maneuverNode.

    until not maneuverNode:orbit:hasNextPatch {
        set maneuver     to list(maneuver[0], maneuver[1], maneuver[2], maneuver[3] - 5).
        set maneuverNode to node(maneuver[0], maneuver[1], maneuver[2], maneuver[3]).
        if hasNode {
            remove nextNode.
        }
        add maneuverNode.
        wait 0.01.
    }

    until maneuverNode:orbit:Apoapsis <= max(_targetAlt, ship:Periapsis + 1000) {
        if hasNode {
            remove nextNode.
        }
        set maneuver     to list(maneuver[0], maneuver[1], maneuver[2], maneuver[3] - 0.25).
        set maneuverNode to node(maneuver[0], maneuver[1], maneuver[2], maneuver[3]).
        add maneuverNode.
        wait 0.01.
    }
    
    return maneuverNode.
}


global function AddOptimizedNode {
    parameter _maneuverParam,
              _targetAlt,
              _comparisonMode,
              _targetBody,
              _maneuverAccuracy.

    local maneuver  to OptimizeNodeData(_maneuverParam, _targetAlt, _comparisonMode, _targetBody, _maneuverAccuracy).
    set   maneuver  to AddNodeToPlan(maneuver).

    return maneuver.
}


global function AddCircularizationNode {
    parameter _nodeAt,
              _targetAlt.

    local dV to choose GetDVForRetrograde(_targetAlt, ship:Apoapsis) if _nodeAt = "pe" else GetDVForPrograde(_targetAlt, ship:Periapsis).
    if dV > 9999 {
        set dV to 50.
    }

    local maneuver is list().
    local mode is "".

    if _nodeAt = "ap" {
        set maneuver to list(Time:Seconds + Eta:Apoapsis, 0, 0, dV).
        set mode to "pe".
    } else {
        set maneuver to list(Time:Seconds + Eta:Periapsis, 0, 0, dV).
        set mode to "ap".
    }

    local mnvAcc is 0.005.
    set   maneuver to OptimizeNodeData(maneuver, _targetAlt, mode, ship:Body, mnvAcc).
    set   maneuver to AddNodeToPlan(maneuver).
    
    return maneuver.
}


local function EvaluateCandidates {
    parameter _maneuverData,
              _candidates,
              _targetValue,
              _comparisonMode,
              _targetBody.

    local currenScore to NodeScore(_maneuverData, _targetValue, _comparisonMode, _targetBody).
    
    for c in _candidates {
        local candidateScore to NodeScore(c, _targetValue, _comparisonMode, _targetBody).
        
        if candidateScore:intersect {
            
            if candidateScore:result > _targetValue {
                
                if candidateScore:score < currenScore:score {
                    set currenScore to NodeScore(c, _targetValue, _comparisonMode, _targetBody).
                    set _maneuverData to c.
                }    

            } else if candidateScore:result < _targetValue {
                
                if candidateScore:score > currenScore:score {
                    set currenScore to NodeScore(c, _targetValue, _comparisonMode, _targetBody).
                    set _maneuverData to c.
                }
            }
        }
    }

    return lex("_data", _maneuverData, "curScore", currenScore).
}


global function ExecuteNode {
    parameter _maneuverNode.
    
    local sVal      to LookDirUp(_maneuverNode:BurnVector, sun:Position).
    lock steering   to sVal.
    local tVal      to 0.
    lock throttle   to tVal.

    local done  to false.
    local dV    to _maneuverNode:DeltaV.
    local maxAcceleration to ship:MaxThrust / ship:Mass.

    until done {
        set maxAcceleration to ship:MaxThrust / ship:Mass.

        set tVal to min(_maneuverNode:DeltaV:Mag / maxAcceleration, 1).

        if VDot(dV, _maneuverNode:DeltaV) < 0 {
            lock throttle to 0.
            set done to true.
            break.

        } else if _maneuverNode:DeltaV:Mag < 0.1 {
            wait until VDot(dV, _maneuverNode:DeltaV) < 0.1.

            lock throttle to 0.
            set done to true.
        }

        update_display().
        disp_burn_data().
    }

    remove _maneuverNode.
    disp_clear_block("burn_data").
}


local function ImproveNode {
    parameter _maneuverData,
              _targetVal,
              _comparisonMode,
              _targetBody,
              _maneuverAccuracy.

    local limLow  to 1 - _maneuverAccuracy.
    local limHigh to 1 + _maneuverAccuracy.

    //hill climb to find the best time
    local currenScore is NodeScore(_maneuverData, _targetVal, _comparisonMode, _targetBody).

    // mnvCandidates placeholder
    local candidates is list().

    // Base maneuver factor - the amount of dV that is used for hill
    // climb iterations
    local maneuverFactor is 1.

    if currenScore:score > (limLow * 0.975) and currenScore:score < (limHigh * 1.025) {
        set maneuverFactor to 0.05 * maneuverFactor.

    } else if currenScore:score > (limLow * 0.875) and currenScore:score < (limHigh * 1.125) {
        set maneuverFactor to 0.125 * maneuverFactor. 

    } else if currenScore:score > (limLow * 0.75) and currenScore:score < (limHigh * 1.25) {
        set maneuverFactor to 0.25 * maneuverFactor.

    } else if currenScore:score > (limLow * 0.50) and currenScore:score < (limHigh * 1.50) {
        set maneuverFactor to 0.50 * maneuverFactor.

    } else if currenScore:score > (limLow * 0.25) and currenScore:score < (limHigh * 1.75) {
        set maneuverFactor to 0.75 * maneuverFactor.

    } else if currenScore:score > -1 * limLow and currenScore:score < limHigh * 3 {
        set maneuverFactor to 1 * maneuverFactor.

    } else if currenScore:score > -10 * limLow and currenScore:score < limHigh * 11 {
        set maneuverFactor to 2 * maneuverFactor. 

    } else {
        set maneuverFactor to 5 * maneuverFactor.
    }
    
    out_msg("Optimizing node.").

    set candidates to list(
         list(_maneuverData[0] + maneuverFactor, _maneuverData[1], _maneuverData[2], _maneuverData[3])  //Time
        ,list(_maneuverData[0] - maneuverFactor, _maneuverData[1], _maneuverData[2], _maneuverData[3]) //Time
        ,list(_maneuverData[0], _maneuverData[1], _maneuverData[2], _maneuverData[3] + maneuverFactor) //Prograde
        ,list(_maneuverData[0], _maneuverData[1], _maneuverData[2], _maneuverData[3] - maneuverFactor) //Prograde
        ,list(_maneuverData[0], _maneuverData[1] + maneuverFactor, _maneuverData[2], _maneuverData[3]) //Radial
        ,list(_maneuverData[0], _maneuverData[1] - maneuverFactor, _maneuverData[2], _maneuverData[3]) //Radial
        ,list(_maneuverData[0], _maneuverData[1], _maneuverData[2] + maneuverFactor, _maneuverData[3]) //Normal
        ,list(_maneuverData[0], _maneuverData[1], _maneuverData[2] - maneuverFactor, _maneuverData[3]) //Normal
    ).

    local bestCandidate to EvaluateCandidates(_maneuverData, candidates, _targetVal, _comparisonMode, _targetBody).
    return bestCandidate.
}


local function ImproveTransferNode {
    parameter _maneuverData,
              _targetVal,
              _targetBody.
    
    local bestCandidate to lex().
    local orbitRetro    to choose false if _targetVal <= 90 else true.
    local nodeScore     to NodeScore(_maneuverData, _targetVal, "tliInc", _targetBody).
    local intersect     to nodeScore["intersect"].

    out_msg("Optimizing transfer node timing for proper inclination.").
    
    if not intersect {
        until intersect {
            local mnvCandidates to list(
                 list(_maneuverData[0] + 1, _maneuverData[1], _maneuverData[2], _maneuverData[3])
                ,list(_maneuverData[0] - 1, _maneuverData[1], _maneuverData[2], _maneuverData[3])
                ,list(_maneuverData[0], _maneuverData[1], _maneuverData[2], _maneuverData[3] + 1)
                ,list(_maneuverData[0], _maneuverData[1], _maneuverData[2], _maneuverData[3] - 1)
            ).
            set bestCandidate to EvaluateCandidates(_maneuverData, mnvCandidates, _targetVal, "tliInc", _targetBody).
            set _maneuverData to bestCandidate["_data"].
            set nodeScore to bestCandidate["curScore"]:score.
            set intersect to bestCandidate["curScore"]:intersect.
            wait 0.01.
        }
    }

    set nodeScore to NodeScore(_maneuverData, _targetVal, "tliInc", _targetBody).

    if orbitRetro {
        until nodeScore["intersect"] and nodeScore["result"] > 90 {
            set _maneuverData to list(_maneuverData[0] - 1, _maneuverData[1], _maneuverData[2], _maneuverData[3]).
            set nodeScore to NodeScore(_maneuverData, _targetVal, "tliInc", _targetBody).
        }
        return _maneuverData.

    } else {
        until nodeScore["intersect"] and nodeScore["result"] <= 90 {
            set _maneuverData to list(_maneuverData[0] + 1, _maneuverData[1], _maneuverData[2], _maneuverData[3]).
            set nodeScore to NodeScore(_maneuverData, _targetVal, "tliInc", _targetBody).
        }

        return _maneuverData.
    }
}


local function NodeResultValue {
    parameter _comparisonMode,
              _orbit.

    if _comparisonMode = "pe" {     
        return _orbit:Periapsis.
    } else if _comparisonMode = "ap" {
        return _orbit:Apoapsis.
    } else if _comparisonMode = "inc" {
        return _orbit:Inclination.
    } else if _comparisonMode = "tliInc" { 
        return _orbit:Inclination.
    } else if _comparisonMode = "lan" {
        return _orbit:LongitudeOfAscendingNode.
    } else if _comparisonMode = "argpe" {
        return _orbit:ArgumentOfPeriapsis.
    }
}


local function NodeScore {
    parameter _maneuverData,
              _targetVal,
              _comparisonMode,
              _targetBody.

    local intersect     to false.
    local maneuverTest  to node(_maneuverData[0], _maneuverData[1], _maneuverData[2], _maneuverData[3]).
    local result        to -999999.
    local score         to -999999.
    
    add maneuverTest.
    local scoredOrbit to maneuverTest:Orbit.

    until intersect {
        if scoredOrbit:Body = _targetBody {
            set result      to NodeResultValue(_comparisonMode, scoredOrbit).
            set score       to result / _targetVal.
            set intersect   to true.
        
        } else if scoredOrbit:HasNextPatch {
            set scoredOrbit to scoredOrbit:NextPatch.
        
        } else {
            break.
        }
    }
    
    disp_block(list(
        "nodeResult",
        "node result",
        "tgtBody",     _targetBody,
        "intersect",    intersect,
        "score",        round(score, 5),
        "tgtVal",      _targetVal,
        "resultVal",    round(result)
    )).

    remove maneuverTest.

    return lex("score", score, "result", result, "intersect", intersect).
}


global function OptimizeManeuverNode {
    parameter _maneuverNode,
              _targetVal,
              _comparisonType,
              _targetBody is _maneuverNode:Orbit:Body,
              _maneuverAccuracy is 0.005.

    local maneuverParam to list(_maneuverNode:Eta + Time:Seconds, _maneuverNode:radialOut, _maneuverNode:normal, _maneuverNode:prograde).
    remove _maneuverNode.
    local optimizedParam to OptimizeNodeData(maneuverParam, _targetVal, _comparisonType, _targetBody, _maneuverAccuracy).
    set _maneuverNode to node(optimizedParam[0], optimizedParam[1], optimizedParam[2], optimizedParam[3]).
    add _maneuverNode.

    return _maneuverNode.
}


global function OptimizeNodeData {
    parameter _maneuverData,
              _targetVal,
              _comparisonType,
              _targetBody,
              _maneuverAccuracy.

    out_msg("Optimizing node.").

    local improvedData  to lex().
    local limLow        to 1 - _maneuverAccuracy.
    local limHigh       to 1 + _maneuverAccuracy. 
    local nodeScore     to 0.

    until false {
        set improvedData    to Improvenode(_maneuverData, _targetVal, _comparisonType, _targetBody, _maneuverAccuracy).
        set _maneuverData   to improvedData["_data"].
        set nodeScore       to improvedData["curScore"]:score.
        wait 0.001.
        
        if nodeScore >= limLow and nodeScore <= limHigh {
            break.
        }
    }

    disp_clear_block("nodeOptimize").
    disp_clear_block("nodeResult").

    out_info().
    out_msg("Optimized maneuver found (score: " + nodeScore + ")").
    return _maneuverData.
}


global function OptimizeTransferNode {
    parameter _maneuverNode,
              _targetAlt,
              _targetInc,
              _targetBody,
              _maneuverAccuracy.

    local   maneuverData    to list(_maneuverNode:Eta + Time:Seconds, _maneuverNode:radialOut, _maneuverNode:normal, _maneuverNode:prograde + 1).
    remove _maneuverNode.

    local   optimizedData   to ImproveTransfernode(maneuverData, _targetInc, _targetBody).
    set     optimizedData   to OptimizeNodeData(optimizedData, _targetAlt, "pe", _targetBody, _maneuverAccuracy).
    set     _maneuverNode   to node(optimizedData[0], optimizedData[1], optimizedData[2], optimizedData[3]).
    add     _maneuverNode.

    return _maneuverNode.
}



//-- WIP --//
local function NodeMultiScore {
    parameter _maneuverData,     // mnv list
              _targetParams,  // list of target parameters in format: (tgtBody, tgtAlt, tgtInc, tgtLAN, tgtArgPe)
              _accuracy.   // Accuracy factor

    local intersect     to false.
    local maneuverTest  to node(_maneuverData[0], _maneuverData[1], _maneuverData[2], _maneuverData[3]).
    local result        to -999999.
    local score         to -999999.
    local targetBody    to _targetParams[0].
    local targetAlt     to _targetParams[1].
    local targetInc     to _targetParams[2].
    local targetLAN     to _targetParams[3].
    local targetArgPe   to _targetParams[4].

    add maneuverTest.
    local scoredOrbit       to maneuverTest:Orbit.
    local scoredOrbitPeriod to scoredOrbit:period.

    until intersect {
        if scoredOrbit:Body = targetBody {
            set intersect to true.
        } else if scoredOrbit:HasNextPatch {
            set scoredOrbit to scoredOrbit:NextPatch.
        } else  {
            return lex("intersect", intersect). // return a lex with only the intersect value
        }
    }

    

    return false.
}