//Data Vessel Engine library
@lazyGlobal off.

// Delegates
    local get_ship_engs is get_engines_obj_by_stage@.


//Returns all engines in the vessel
global function get_engines {
    local pList is false.

    local eList is list().

    if pList {
        for p in pList {
            if p:isType("engine") eList:add(p).
        }
    }
    else list engines in eList.

    return eList. 
}.


global function get_engines_obj_by_stage {
    local pList is list().
    local eLex is lex().

    for p in pList set eLex[p:stage] to p.
    return eLex.
}


//Returns engines by a given stage on the current vessel
global function get_engines_for_stage {
    parameter pStage is stage:number.

    local pList is get_engines().
    local eList is list().

    for p in pList {
        if p:stage = pStage {
            eList:add(p).
        }
    }
    
    return pList.
}.


//Returns active engines
global function get_active_engines {
    parameter pList is ship:parts.
    
    set pList to get_engines().
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
            )
        ).
    }

    return perfObj.
}