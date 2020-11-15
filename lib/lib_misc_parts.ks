@lazyGlobal off.


//shrouded decoupler
    //-- jettison shroud without decoupling
    global function jettison_decoupler_shroud {
        parameter p.

        local m is p:getModule("ModuleDecouplerShroud").
        if m:hasEvent("jettison") m:doEvent("jettison").
    }