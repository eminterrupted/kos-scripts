@lazyGlobal off.

// Dependencies
runOncePath("0:/lib/lib_mnv").

// Variables

// Global functions

//#region -- Timing and measurement
// Time to impact
global function land_time_to_impact 
{
    parameter currentVelocity,
              distance.

    local v to -currentVelocity.
    local d to distance.
    local g to ((ship:body:mu * (ship:mass * 1000)) / (ship:body:radius + ship:altitude)^2) /  (ship:mass * 1000). // Current gravity
    //local g to ship:body:mu / ship:body:radius^2. // Surface gravity
    return (sqrt(v^2 + 2 * (g * d)) - v) / g.
}
//#endregion -- Timing and measurement

//#region -- Control
// return srfRetrograde if verticalSpeed < 0, else up
global function land_srfretro_or_up
{
    if ship:verticalSpeed < 0 
    {
        return srfRetrograde.
    }
    else
    {
        return up.
    }
}
//#endregion -- Control

//#region -- Impact Position Hill Climb

// Compares the parameter geoposition with current impact position. 
global function land_deorbit_mnv
{
    parameter geoPos.

    local mnvData to list(0, 0, 0, 0).
    local mnvNode to node(mnvData[0], mnvData[1], mnvData[2], mnvData[3]).
    add mnvNode. 

    // Add the initial deorbit burn
    until addons:tr:hasImpact 
    {
        remove mnvNode.
        set mnvData to list(mnvData[0], mnvData[1], mnvData[2], mnvData[3] - 1).
        set mnvNode to node(mnvData[0], mnvData[1], mnvData[2], mnvData[3]).
        add mnvNode.
    }

    // Optimization
    remove mnvNode.
    set mnvNode to land_optimize_landing_node_data(mnvData, geoPos, geoPos:Body, "impactPos").
    add mnvNode. 
}

global function land_deorbit_score
{
    parameter data,
              tgtGeoPos.

    local mnvTest   to node(data[0], data[1], data[2], data[3]).
    local result to latlng(0, 0).
    local score to -999999.

    add mnvTest.
    if addons:tr:hasImpact 
    {
        set result to addons:tr:impactPos.
    }
    
    print "Result: " + result at (2, 50).
    print "tgtGeoPos: " + tgtGeoPos at (2, 51).
    local latCheck to result:lat / tgtGeoPos:lat.
    local lngCheck to result:lng / tgtGeoPos:lng.
    set score to (latCheck + (3 * lngCheck)) / 4.
    
    disp_mnv_score(tgtGeoPos, ship:body, true, result, score).
    remove mnvTest.

    return lex("score", score, "result", result).
}

// Evaluates candidates
local function land_eval_deorbit_candidates
{
    parameter data,
              candList,
              tgtGeoPos.

    local curScore to land_deorbit_score(data, tgtGeoPos).
    
    for c in candList 
    {
        local candScore to land_deorbit_score(c, tgtGeoPos).
        if candScore:result:lat > tgtGeoPos:lat and candScore:result:lng < tgtGeoPos:lng
        {
            if candScore:score < curScore:score 
            {
                set curScore to land_deorbit_score(c, tgtGeoPos).
                set data to c.
            }
        } 
        else if candScore:result:lat > tgtGeoPos:lat and candScore:result:lng > tgtGeoPos:lng
        {
            if candScore:score < curScore:score 
            {
                set curScore to land_deorbit_score(c, tgtGeoPos).
                set data to c.
            }
        } 
        else if candScore:result:lat < tgtGeoPos:lat and candScore:result:lng > tgtGeoPos:lng
        {
            if candScore:score > curScore:score 
            {
                set curScore to land_deorbit_score(c, tgtGeoPos).
                set data to c.
            }
        }
        else if candScore:result:lat < tgtGeoPos:lat and candScore:result:lng < tgtGeoPos:lng
        {
            if candScore:score > curScore:score 
            {
                set curScore to land_deorbit_score(c, tgtGeoPos).
                set data to c.
            }
        }
    }

    return lex("data", data, "curScore", curScore).
}


global function land_optimize_landing_node_data
{
    parameter data,
              tgtGeoPos,
              tgtBody,
              compMode,
              changeModes is "1111".

    disp_info("Optimizing node.").

    local iteration     to 0.
    local improvedData  to lex().
    local lastScoreAvg  to 0.
    local limLo         to 1 - 0.005.
    local limHi         to 1 + 0.005.
    local nodeScore     to 0.

    until iteration >= 5
    {
        set lastScoreAvg to land_deorbit_score(data, tgtGeoPos):score.

        set improvedData to land_improve_deorbit_node(data, tgtGeoPos, tgtBody, compMode, changeModes).
        set data to improvedData["data"].
        set nodeScore to improvedData["curScore"]:score.
        wait 0.01.
        if nodeScore >= limLo and nodeScore <= limHi 
        {
            break.
        }
        else if round(nodeScore, 8) = round(lastScoreAvg, 8)
        {
            print "Same score iteration: " + iteration at (2, 35).
            set iteration to iteration + 1.
        }
        wait 0.01.
    }
    print "                        " at (2, 25).
    disp_info("Optimized maneuver found (score: " + round(nodeScore, 5) + ")").
    clr_disp(). 
    return data.
}

// Improves a maneuver node based on tgtVal and compMode
global function land_improve_deorbit_node
{
    parameter data,
              tgtGeoPos,
              tgtBody,
              compMode,
              changeModes.

    local limLo to 1 - 0.0075.
    local limHi to 1 + 0.0075.

    //hill climb to find the best time
    local curScore is land_deorbit_score(data, tgtGeoPos).

    // mnvCandidates placeholder
    local mnvCandidates is list().

    // Base maneuver factor - the amount of dV that is used for hill
    // climb iterations
    local mnvFactor is 1.

    if curScore:score > (limLo * 0.975) and curScore:score < (limHi * 1.025)        set mnvFactor to 0.05   * mnvFactor.
    else if curScore:score > (limLo * 0.925) and curScore:score < (limHi * 1.075)   set mnvFactor to 0.125  * mnvFactor. 
    else if curScore:score > (limLo * 0.85) and curScore:score < (limHi * 1.15)     set mnvFactor to 0.25   * mnvFactor. 
    else if curScore:score > (limLo * 0.75) and curScore:score < (limHi * 1.25)     set mnvFactor to 0.50   * mnvFactor.
    else if curScore:score > (limLo * 0.65) and curScore:score < (limHi * 1.35)     set mnvFactor to 0.75   * mnvFactor.
    else if curScore:score > 0.5 * limLo and curScore:score < limHi * 1.5               set mnvFactor to 1      * mnvFactor.
    else if curScore:score > -10 * limLo and curScore:score < limHi * 11            set mnvFactor to 2      * mnvFactor. 
    else                                                                            set mnvFactor to 5      * mnvFactor.
    
    disp_info("Optimizing node.").

    set mnvCandidates to list(
        list(data[0] + mnvFactor, data[1], data[2], data[3])  //Time
        ,list(data[0] - mnvFactor, data[1], data[2], data[3]) //Time
        ,list(data[0], data[1] + mnvFactor, data[2], data[3]) //Radial
        ,list(data[0], data[1] - mnvFactor, data[2], data[3]) //Radial
        ,list(data[0], data[1], data[2] + mnvFactor, data[3]) //Normal
        ,list(data[0], data[1], data[2] - mnvFactor, data[3]) //Normal
        ,list(data[0], data[1], data[2], data[3] + mnvFactor) //Prograde
        ,list(data[0], data[1], data[2], data[3] - mnvFactor) //Prograde
    ).
    if changeModes[3] = "0"
    {
        mnvCandidates:remove(7).
        mnvCandidates:remove(6).    
    }
    if changeModes[2] = "0"
    {
        mnvCandidates:remove(5).
        mnvCandidates:remove(4).
    }
    if changeModes[1] = "0"
    {
        mnvCandidates:remove(3).
        mnvCandidates:remove(2).
    }
    if changeModes[0] = "0"
    {
        mnvCandidates:remove(1).
        mnvCandidates:remove(0).
    }

    local bestCandidate to land_eval_deorbit_candidates(data, mnvCandidates, tgtGeoPos).
    return bestCandidate.
}