@lazyGlobal off.

global function format_timestamp {
    parameter pSec.

    local hour is floor(pSec / 3600).
    local min is floor((pSec / 60) - (hour * 60)).
    local sec is round(pSec - (hour * 3600 + min * 60)).

    return hour + "h " + min + "m " + sec + "s".
}

global function test_part {
    parameter p.

    local tMod is "ModuleTestSubject".

    if p:hasModule(tMod) {
        local m is p:getModule(tMod).

        if m:hasEvent("run test") {
            m:doEvent("run test").
        }

        else {
            if p:stage = stage:number - 1 stage.
            else if p:stage = stage:number - 2 {
                stage. 
                stage.
            }

            else if p:stage = stage:number - 3 {
                stage.
                stage.
                stage.
            }
        }
    }
}


global function get_module_fields {
    parameter m.

    local retObj is lexicon().
    
    for f in m:allFieldNames {
        set retObj[f] to m:getField(f).
    }

    return retObj.
}