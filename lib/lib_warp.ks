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
            if steeringmanager:angleerror >= -0.05 and steeringmanager:angleerror <= 0.05 {
                if steeringmanager:rollerror >= -0.05 and steeringmanager:rollerror <= 0.05 warpTo(ts - 15).
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

    local check to { return true.}. 

    if ship:altitude > pAlt {
        set check to utils:checkAltHi@.
    } else {
        set check to utils:checkAltLo@.
    }

    local setWarp to { parameter _warp. set warp to _warp. wait until kuniverse:timewarp:issettled. }.
    local subroutine to init_subroutine().

    until not check(pAlt) {

        if ship:altitude >= pAlt * 15 {
            if kuniverse:timewarp:warp <> 6 {
                setWarp(6).
                set subroutine to set_sr(1).
            }
        }

        else if ship:altitude >= pAlt * 5 {
            if kuniverse:timewarp:warp <> 5 {
                setWarp(5).
                set subroutine to set_sr(2).
            }
        }

        else if ship:altitude >= pAlt * 2.5 {
            if kuniverse:timewarp:warp <> 4 {
                setWarp(4).
                set subroutine to set_sr(3).
            }
        }

        else if ship:altitude >= pAlt * 1.25 {
            if kuniverse:timewarp:warp <> 3 {
                setWarp(3).
                set subroutine to set_sr(4).
            }
        }

        else if ship:altitude >= pAlt * 1.0125 {
            if kuniverse:timewarp:warp <> 1 {
                setWarp(1).
                set subroutine to set_sr(5).
            }
        }
        
        else if ship:altitude > pAlt {
            if warp > 0 kuniverse:timewarp:cancelwarp().
            wait until kuniverse:timewarp:issettled.
            break.
        }

        update_display().
        wait 0.01.
    }
}


global function warp_to_next_soi {
    local sVal to lookDirUp(ship:prograde:forevector, sun:position).
    lock steering to sval.

    if ship:obt:hasnextpatch {
        set target to "".
        wait until steeringmanager:angleerror >= -0.1 and steeringmanager:angleerror <= 0.1. 
        warpTo(ship:obt:nextpatcheta + time:seconds - 15).
    }

    until warp = 0 {
        set sVal to lookDirUp(ship:prograde:forevector, sun:position).
        update_display().
    }
}


global function warp_to_ksc_reentry_window {
    parameter rVal is 0.

    local sVal to lookDirUp( - ship:prograde:forevector, sun:position) + r(0, 0, rVal).
    lock steering to sVal.

    local minLongitude to 125.
    local maxLongitude to 135.
    local ts is time:seconds + 5.

    if ship:body:name = "Kerbin" {
        

        print "MSG: Sampling longitude advancement during orbit       " at (2, 7).
        local longitudeSample is ship:longitude.
        until time:seconds >= ts {
            update_display().
            disp_timer(ts).
        }

        set longitudeSample to mod(ship:longitude - longitudeSample, 360).
        local longPerSec is longitudeSample / 5.

        local shipLong to choose ship:longitude if ship:longitude < minLongitude else ship:longitude + 360.

        set ts to time:seconds + mod(minLongitude - shipLong, 360) / longPerSec.
        
        warpTo(ts - 60).

        until time:seconds >= ts - 60 {
            update_display().
            disp_timer(ts).
            print "MSG: Warping to reentry window for KSC landing       " at (2, 7).
        }
    }

    print "                                                        " at (2, 7).
    if warp > 0 set warp to 0.
    wait until kuniverse:timewarp:issettled.

    until time:seconds >= ts {
        update_display().
        disp_timer(ts, "Timestamp").
    }

    if warp > 0 set warp to 0.

    disp_clear_block("timer").
}


global function warp_to_burn_node {
    parameter mnvObj.
    
    local rVal is ship:facing:roll - lookDirUp(ship:facing:forevector, sun:position):roll.
    lock steering to lookdirup(nextnode:burnVector, sun:position) + r(0, 0, rVal).
    
    until time:seconds >= (mnvObj["burnEta"] - 30) {
        warp_to_timestamp(mnvObj["burnEta"]).
        disp_burn_data().
        update_display().
    }

    if warp > 0 set warp to 0.
    wait until kuniverse:timewarp:issettled.
    
    until time:seconds >= mnvObj["burnEta"] {
        update_display().
        disp_burn_data().
    }

    update_display().
}