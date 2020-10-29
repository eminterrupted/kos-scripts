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
    else if tDelta > 600 and warp <> 4 set warp to 4. 
    else if tDelta > 300 and warp <> 3 set warp to 3.
    else if tDelta > 150 and warp <> 2 set warp to 2. 
    else if tDelta > 60 and warp <> 1 set warp to 1.
    else if tDelta <= 15 kuniverse:timewarp:cancelwarp().
}


global function test_part {
    parameter p.

    local mod is "ModuleTestSubject".

    return true.
}

//shrouded decoupler
//-- jettison
global function jettison_decoupler_shroud {
    parameter p.

    local m is p:getModule("ModuleDecouplerShroud").
    if m:hasEvent("jettison") m:doEvent("jettison").
}