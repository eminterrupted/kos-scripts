//Data Vessel Engine library
@lazyGlobal off.

runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/data/engine/lib_isp").

// -- Functions -- //

// Engine performance

    // Returns the current twr for the vessel
    global function get_cur_twr {
        return ship:availableThrust / (ship:mass * body:mu / body:radius^2).
    }


// Return engine lists
// Returns a list of all engines for the current vessel
global function get_active_engs {
    if verbose logStr("[get_active_engs]").

    local eList is list().
    for p in ship:partsTaggedPattern("eng.") {
        if p:ignition eList:add(p).
    }

    if verbose logStr("[get_active_engs]-> return: " + eList).
    return eList.
}

// Returns all engines for a given ship, defaults to current vessel
global function get_ship_engs {
    parameter _ves is ship.

    if verbose logStr("[get_ship_engs] _ves: " + _ves).

    local eList is list().
    for p in _ves:partsTaggedPattern("eng.") {
        eList:add(p).
    }

    if verbose logStr("[get_ship_engs]-> return: " + eList).
    return eList.
}


// Returns engines that will be lit for a given stage. 
global function get_engs_for_stage {
    parameter pStage is stage:number.
    
    if verbose logStr("[get_engs_for_stg] pStage:" + pstage).

    local eList is ship:partsTaggedPattern("eng.*.stgId:" + pStage).

    if verbose logStr("[get_engs_for_stage]-> return: " + eList:join(";")).
    return eList.
}


// Returns the next set of engines that will be lit after the current stage
global function get_engs_for_next_stage {
    
    if verbose logStr("[get_engs_for_next_stg]").

    local eList is list().
    from {local n is 1.} until eList:length > 0 step { set n to n + 1.} do {
        set eList to get_engs_for_stage(stage:number - n).
    }

    if verbose logStr("[get_engs_for_next_stg]-> return: " + eList:join(";")).
    return eList.
}


// Given a starting stage number, returns the next stage number with engines
global function get_next_stage_with_eng {
    parameter stg is stage:number.
    
    if verbose logStr("[get_next_stage_with_eng] stg:" + stg).
    
    local eList is list().
    from { local n is stg - 1.} until eList:length > 0 or n < -1 step { set n to n - 1.} do {
        set stg to n.
        set eList to get_engs_for_stage(stg).
    }

    if verbose logStr("[get_next_stage_with_eng]-> return: " + stg).
    return stg.
}


// Returns a lexicon contain performance information for each in a given 
// list of engines. Used for maneuver calculations and telemetry displays.
// Will return most data from cache if present. 
global function eng_perf_obj {
    parameter eList is get_ship_engs().

    if verbose logStr("[get_eng_perf_obj] eList: " + eList:join(";")).

    // Load from cache if present
    local perfObj is choose lex() if from_cache("engPerfObj") = "null" else from_cache("engPerfObj").
    
    // Loop through the engines in the list. Only update possible changed values 
    // if the key already exists, else create the initial dictionary for the engine
    for e in elist {
        if perfObj:hasKey(e:uid) {
            set perfObj[e:uid]["thr"]["poss"] to e:possibleThrust.
        } else {
            set perfObj[e:uid] to lex(
                "part",      e,
                "massStage", e:decoupledIn,
                "burnStage", e:stage,
                "thr",    lex(
                    "poss",  e:possiblethrust,
                    "sl",    e:possiblethrustat(body:atm:sealevelpressure),
                    "vac",   e:possibleThrustAt(0)
                ),
                "isp",    lex(
                    "sl",    e:slisp,
                    "vac",   e:visp
                ),
                "exhvel", lex(
                    "sl",    get_eng_exh_vel(e, 0),
                    "vac",   get_eng_exh_vel(e, body:atm:height)
                )
            ).
        }
    }

    // Write the result to cache
    to_cache("engPerfObj", perfObj).

    if verbose logStr("[get_eng_perf_obj]-> return: " + perfObj).
    return perfObj.
}

// For a given list of engines, return their combined exhaust velocity at a given
// altitude and body, if provided (else defaults to vacuum around current body)
global function get_engs_exh_vel {
    parameter _engList,
              _alt to body:atm:height,
              _body is ship:body.
 
    if verbose logStr("[get_engs_exh_vel] _engList: " + _engList:join(";") + "   _alt: " + _alt + "    _body: " + _body).

    local apIsp to get_avail_isp(_engList, _body:atm:altitudePressure(_alt)).
    local exhVel to constant:g0 * apIsp.

    if verbose logStr("[get_engs_exh_vel]-> return: " + exhVel).
    return exhVel.
}

// For a given engine and altitude, return the exhause velocity at the provided 
// altitude, if provided (else defaults to velocity in vacuum)
global function get_eng_exh_vel {
    parameter _eng,
              _alt to body:atm:height.

    if verbose logStr("[get_eng_exh_vel] _eng: " + _eng + "   _alt: " + _alt).

    local apIsp to choose _eng:visp if _alt >= body:atm:height else _eng:ispAt(body:atm:altitudepressure(_alt)).
    local exhVel to constant:g0 * apIsp.

    if verbose logStr("[get_eng_exh_vel]-> return: " + exhVel).
    return exhVel.
}