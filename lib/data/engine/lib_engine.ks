//Data Vessel Engine library
@lazyGlobal off.

runOncePath("0:/lib/data/engine/lib_isp.ks").

// Delegates
    local get_ship_engs is get_engs_obj_by_stg@.


//Returns all engines in the vessel
global function get_engs {
    parameter pList is list().

    if pList:length > 0 {
        local eList is list().
        for p in pList {
            if p:isType("engine") eList:add(p).
        }
        return eList.
    }
    else list engines in pList.

    return pList. 
}.


global function get_engs_obj_by_stg {
    
    local eLex is lex().
    local stgTag to "".
    
    for p in ship:partsTaggedPattern("eng.") {
        set stgtag to p:tag:replace("eng.stgId:", "").
        set eLex[stgTag] to p.
    }

    return eLex.
}


//Returns engines by a given stage on the current vessel
global function get_engs_for_stg {
    parameter pStage is stage:number.
    logStr("get_engs_for_stg").
    logStr("pstage: " + pstage).

    local ret is ship:partsTaggedPattern("eng.stgId:" + pStage).
    logStr("return: " + ret:join(";")).
    return ret.
}


global function get_engs_for_next_stg {
    
    logStr("get_engs_for_next_stg").

    local eList is list().
    from {local n is 1.} until eList:length > 0 step { set n to n + 1.} do {
        set eList to get_engs_for_stg(stage:number - n).
    }
    
    logStr("return: " + eList:join(";")).
    return eList.
}


global function get_next_stage_with_eng {
    parameter stg is stage:number.
    
    logStr("get_next_stage_with_eng").
    logStr("stg: " + stg).

    local eList is list().
    from { local n is stg - 1.} until eList:length > 0 or n < -1 step { set n to n - 1.} do {
        set stg to n.
        set eList to get_engs_for_stg(stg).
    }

    logStr("return: " + stg).
    return stg.
}


//Returns active engines
global function get_active_engs {
    parameter pList is ship:parts.

    set pList to get_engs().
    local eList is list().

    for e in pList {
        if e:isType("engine") {
            if e:ignition and not e:flameout eList:add(e).
        }
    }
    
    return eList.
}


global function get_eng_perf_obj {
    parameter eList is get_ship_engs().
    
    local perfObj is lex().
    
    for e in elist {
        set perfObj[e:name + "|" + e:cid] to lex(
            "thr", lex(
                "poss", e:possiblethrust,
                "sl", e:possiblethrustat(body:atm:sealevelpressure),
                "vac", e:possibleThrustAt(0)
	        ),
            "isp", lex(
                "sl", e:slisp,
                "vac", e:visp
            ),
            "exhvel", lex(
                "sl", get_eng_exh_vel(e, 0),
                "vac", get_eng_exh_vel(e, body:atm:height)
            )
        ).
    }

    return perfObj.
}


global function get_engs_exh_vel {
    parameter engList to get_active_engs(),
              pAlt to ship:apoapsis.

    //local apIsp to choose eng:visp if pAlt >= body:atm:height else eng:ispAt(body:atm:altitudepressure(pAlt)).
    
    local apIsp to get_avail_isp(body:atm:altitudePressure(pAlt), engList).
    return constant:g0 * apIsp.
}


global function get_eng_exh_vel {
    parameter eng,
              pAlt to body:atm:height.

    local apIsp to choose eng:visp if pAlt >= body:atm:height else eng:ispAt(body:atm:altitudepressure(pAlt)).
    return constant:g0 * apIsp.
}