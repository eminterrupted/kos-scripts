@lazyGlobal off.

global function format_timestamp {
    parameter pSec.

    local hour is floor(pSec / 3600).
    local min is floor((pSec / 60) - (hour * 60)).
    local sec is round(pSec - (hour * 3600 + min * 60)).

    return hour + "h " + min + "m " + sec + "s".
}

global function warp_to_timestamp {
    parameter pStamp.

    lock steering to "kill".
    wait 1. 
    local tDelta is pStamp - time:seconds.
    
    if tDelta > 151200 and warp <> 7 set warp to 7.
    else if tDelta > 21600 and warp <> 6 set warp to 6.
    else if tDelta > 1800 and warp <> 5 set warp to 5. 
    else if tDelta > 300 and warp <> 4 set warp to 4. 
    else if tDelta > 120 and warp <> 3 set warp to 3.
    else if tDelta > 30 and warp <> 2 set warp to 2. 
    else if tDelta > 15 and warp <> 1 set warp to 1.
    else if tDelta <= 15 kuniverse:timewarp:cancelwarp().
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