//Data Vessel Engine library
@lazyGlobal off.

runOncePath("0:/lib/lib_init").
//runOncePath("0:/lib/data/engine/lib_isp").

// -- Functions -- //

// Engine lists / references / associations
    // Returns a list of all engines for the current vessel
    global function active_engs {
        if verbose logStr("[active_engs]").

        local eList is list().
        for p in ship:partsTaggedPattern("eng.") {
            if p:ignition eList:add(p).
        }

        if verbose logStr("[active_engs]-> return: " + eList).
        return eList.
    }

    // Returns all engines for a given ship, defaults to current vessel
    global function ship_engs {
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
    global function engs_for_stg {
        parameter pStage is stage:number.
        
        if verbose logStr("[get_engs_for_stg] pStage:" + pstage).

        local eList is ship:partsTaggedPattern("eng.*.stgId:" + pStage).

        if verbose logStr("[get_engs_for_stage]-> return: " + eList:join(";")).
        return eList.
    }


    // Returns the next set of engines that will be lit after the current stage
    global function engs_for_next_stg {
        
        if verbose logStr("[get_engs_for_next_stg]").

        local eList is list().
        from {local n is 1.} until eList:length > 0 step { set n to n + 1.} do {
            set eList to engs_for_stg(stage:number - n).
        }

        if verbose logStr("[get_engs_for_next_stg]-> return: " + eList:join(";")).
        return eList.
    }


    // Given a starting stage number, returns the next stage number with engines
    global function next_stg_with_eng {
        parameter stg is stage:number.
        
        if verbose logStr("[get_next_stage_with_eng] stg:" + stg).
        
        local eList is list().
        from { local n is stg - 1.} until eList:length > 0 or n < -1 step { set n to n - 1.} do {
            set stg to n.
            set eList to engs_for_stg(stg).
        }

        if verbose logStr("[get_next_stage_with_eng]-> return: " + stg).
        return stg.
    }


// Exhaust velocity calculations
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


// Isp calculations
    // Current aggregate Isp
    global function isp_for_stage {
        parameter _stg.

        if verbose logStr("[isp_for_stage]").

        local avIsp  is 0.
        local relThr is 0. 
        local stgThr is 0.

        local eList is engs_for_stg(_stg).
        
        for eng in eList {
            set stgThr to stgThr + eng:thrust.
            set relThr to relThr + (stgThr / eng:isp).
        }

        if stgThr = 0 or relThr = 0 {
            set avIsp to 0.
        } else {
            set avIsp to stgThr / relThr. 
        }

        if verbose logStr("[isp_for_stage]-> return: " + avIsp).

        return avIsp.
    }


    // Returns combined isp for a set of engines at a given pressure.
    global function get_avail_isp {
        parameter   _eList is active_engs(),
                    _pres is body:atm:altitudepressure(ship:altitude).
    
        if verbose logStr("[get_avail_isp] _pres: " + _pres + "   _eList: " + _eList:join(";")).

        local avIsp  is 0.
        local relThr is 0.
        local stgThr is 0.
        
        for e in _eList {
            set stgThr to stgThr + e:possibleThrustAt(_pres).
            set relThr to relThr + (stgThr / e:ispAt(_pres)).
        }

        if stgThr = 0 or relThr = 0 {
            set avIsp to 0. 
        } else {
            set avIsp to stgThr / relThr. 
        }


        if verbose logStr("[get_avail_isp]-> return: " + avIsp).

        return avIsp.
    }

    // ISP for a list of engine parts
    global function get_avail_isp_for_parts {
        parameter _pres is body:atm:altitudePressure(ship:altitude),
                _pList is engs_for_stg(stage:number).

        if verbose logStr("[get_avail_isp_for_parts] _pres: " + _pres + "   _pList: " + _pList:join(";")).

        local avIsp  is 0.
        local relThr is 0.
        local stgThr is 0.
        
        for e in _pList {
            set stgThr to stgThr + e:possibleThrustAt(_pres).
            set relThr to relThr + (stgThr / e:ispAt(_pres)).
        }

        if stgThr = 0 or relThr = 0 {
            set avIsp to 0. 
        } else {
            set avIsp to stgThr / relThr. 
        }

        if verbose logStr("[get_avail_isp_for_parts]-> return: " + avIsp).

        return avIsp.
    }


// Performance objects for all engines / by stage

    // Returns a lexicon contain performance information for each in a given 
    // list of engines. Used for maneuver calculations and telemetry displays.
    // Will return most data from cache if present. 
    global function eng_perf_obj {
        parameter eList is ship_engs().

        if verbose logStr("[get_eng_perf_obj] eList: " + eList:join(";")).

        // Load from cache if present
        local perfObj is choose lex() if from_cache("engPerfObj") = "null" else from_cache("engPerfObj").
        
        // Loop through the engines in the list. Only update possible changed values 
        // if the key already exists, else create the initial dictionary for the engine
        for e in elist {
            local id to e:name + "|" + e:uid.
            if perfObj:hasKey(id) {
                set perfObj[id]["possThr"] to e:possibleThrust.
            } else {
                set perfObj[id] to lex(
                    "tag",      e:tag,
                    "massStg",  e:decoupledIn,
                    "burnStg",  e:stage,
                    "possThr",  e:possibleThrust,
                    "vThr",     e:possibleThrustAt(0),
                    "vIsp",     e:visp,
                    "vExhVel",  get_eng_exh_vel(e, body:atm:height)
                ).
            }
        }

        // Write the result to cache
        to_cache("engPerfObj", perfObj).

        if verbose logStr("[get_eng_perf_obj]-> return: " + perfObj).
        return perfObj.
    }


// Thrust
    // Return the current available combined thrust for a list of engines at a 
    // specific atmospheric pressure. Default pressure is vacuum.
    global function avail_thr_for_eng_list {
        parameter _engList,
                _pres is 0.

        if verbose logStr("[avail_thr_for_eng_list] _engList: " + _engList:join(";") + "   _pres: " + _pres).
        local allThr to 0.

        if _pres > 0 {
            for e in _engList {
                set allThr to allThr + e:availableThrustAt(_pres).
            }
        } else {
            for e in _engList {
                set allThr to allThr + e:availableThrust.
            }
        }

        if verbose logStr("[avail_thr_for_eng_list]-> return: " + allThr).
        return allThr.
    }


    //


    // Return the possible combined thrust for a list of engines at a specific
    // atmospheric pressure. Default pressure is vacuum.
    global function poss_thr_for_eng_list {
        parameter _engList,
                _pres is 0.

        if verbose logStr("[poss_thr_for_eng_list] _engList: " + _engList:join(";") + "   _pres: " + _pres).
        local allThr to 0.

        if _pres > 0 {
            for e in _engList {
                set allThr to allThr + e:possibleThrustAt(_pres).
            }
        } else {
            for e in _engList {
                set allThr to allThr + e:possibleThrust.
            }
        }

        if verbose logStr("[poss_thr_for_eng_list]-> return: " + allThr).
        return allThr.
    }


// TWR
    // Returns the current TWR for the vessel.
    global function get_cur_twr {
        return ship:thrust / (ship:mass * body:mu / (ship:altitude + body:radius)^2).
    }