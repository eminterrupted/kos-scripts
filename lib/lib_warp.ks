@lazyGlobal off. 

runOncePath("0:/lib/lib_log").

global function cust_warp_to_timestamp {
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


global function warp_to_timestamp {
    parameter ts.
    
    logStr("[warp_to_timestamp] Warp mode: " + kuniverse:timewarp:mode).
    logStr("[warp_to_timestamp] Warping to timestamp: [UTC: " + round(ts) + "][MET: " + round(missionTime + (ts - time:seconds)) + "]").

    if ship:altitude > ship:body:atm:height + 2500 set kuniverse:timewarp:mode to "RAILS".
    else set kuniverse:timewarp:mode to "PHYSICS".

    until time:seconds >= ts - 30 {

        if warp = 0 {
            if steeringmanager:angleerror >= -0.1 and steeringmanager:angleerror <= 0.1 {
                if steeringmanager:rollerror >= -0.1 and steeringmanager:rollerror <= 0.1 warpTo(ts - 15).
            }
        }

        update_display().
    }
}


global function warp_to_alt {
    parameter pAlt.

    //local altWarpMode to choose 1 if ship:altitude >= pAlt else 0.

    if kuniverse:timewarp:warp = 0 and kuniverse:timewarp:issettled {
        set kuniverse:timewarp:mode to choose "RAILS" if ship:altitude > body:atm:height else "PHYSICS".
    }

    if ship:altitude >= pAlt * 15 {
        if kuniverse:timewarp:warp <> 5 {
            set kuniverse:timewarp:warp to 5.
            wait until kuniverse:timewarp:issettled.
        }
    }

    else if ship:altitude >= pAlt * 5 {
        if kuniverse:timewarp:warp <> 4 {
            set kuniverse:timewarp:warp to 4.
            wait until kuniverse:timewarp:issettled.
        }
    }

    else if ship:altitude >= pAlt * 2.5 {
        if kuniverse:timewarp:warp <> 3 {
            set kuniverse:timewarp:warp to 3.
            wait until kuniverse:timewarp:issettled.
        }
    }

    else if ship:altitude >= pAlt * 1.25 {
        if kuniverse:timewarp:warp <> 2 {
            set kuniverse:timewarp:warp to 2.
            wait until kuniverse:timewarp:issettled.
        }
    }

    else if ship:altitude >= pAlt * 1.075 {
        if kuniverse:timewarp:warp <> 1 {
            set kuniverse:timewarp:warp to 1.
            wait until kuniverse:timewarp:issettled.
        }
    }

    else if ship:altitude > pAlt {
        if kuniverse:timewarp:warp > 0 kuniverse:timewarp:cancelwarp().
    }
}