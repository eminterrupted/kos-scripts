//Data Vessel Engine library
@lazyGlobal off.

//Returns all engines in the vessel
declare global function get_engines {
    local eList is list().

    list engines in eList.

    return eList. 
}.


//Returns engines by a given stage on the current vessel
declare global function get_engines_for_stage {
    parameter pStage is stage:number.

    local eList is list().
    local eSet is list().

    list engines in eSet.
    for eng in eSet {
        if eng:stage = pStage {
            eList:add(eng).
        }
    }
    
    return eList.
}.


global function get_engine_perf_obj {
    local perfObj is lex().

    return perfObj.
}