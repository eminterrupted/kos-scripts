@lazyGlobal off. 

runOncePath("0:/lib/lib_log").

global function warp_to_timestamp 
{
    parameter _ts, _buffer is 30.
    
    if verbose 
    {
        logStr("[warp_to_timestamp] Warp mode: " + kuniverse:timewarp:mode).
        logStr("[warp_to_timestamp] Warping to timestamp: [UTC: " + round(_ts) + "][MET: " + round(missionTime + (_ts - time:seconds)) + "]").
    }

    if ship:altitude > ship:body:atm:height + 2500 set kuniverse:timewarp:mode to "RAILS".
    else set kuniverse:timewarp:mode to "PHYSICS".

    lock steering to lookDirUp(ship:facing:forevector, sun:position).
    wait 0.1. 
    until shipSettled() 
    {
        update_display().
        print "Ship settled: " + shipSettled() at (2, 35).
    }
    print "                    " at (2, 35).

    until time:seconds >= _ts - _buffer 
    {
        if warp = 0 warpTo(_ts - _buffer).
        update_display().
    }

    unlock steering.
}


global function warp_to_alt 
{
    parameter pAlt.

    //local altWarpMode to choose 1 if ship:altitude >= pAlt else 0.
    if kuniverse:timewarp:warp = 0 and kuniverse:timewarp:issettled 
    {
        set kuniverse:timewarp:mode to choose "RAILS" if ship:altitude > body:atm:height else "PHYSICS".
    }

    local function checkFunction 
    { 
        parameter _alt.

        if ship:altitude > _alt 
        {
            return utils:checkAltHi(_alt).
        } 
        else 
        {
            return utils:checkAltLo(_alt).
        }
    }

    local cd to checkFunction(pAlt).
    local setWarp to { parameter _warp. set warp to _warp. wait until kuniverse:timewarp:issettled. }.
    init_subroutine().

    until not cd 
    {
        if ship:altitude >= pAlt * 16 
        {
            if kuniverse:timewarp:warp <> 6 
            {
                setWarp(6).
                sr(1).
            }
        }
        else if ship:altitude >= pAlt * 8 
        {
            if kuniverse:timewarp:warp <> 5 
            {
                setWarp(5).
                sr(2).
            }
        }
        else if ship:altitude >= pAlt * 4 
        {
            if kuniverse:timewarp:warp <> 4 
            {
                setWarp(4).
                sr(3).
            }
        }
        else if ship:altitude >= pAlt * 2
        {
            if kuniverse:timewarp:warp <> 3 
            {
                setWarp(3).
                sr(4).
            }
        }
        else if ship:altitude >= pAlt * 1.05 
        {
            if kuniverse:timewarp:warp <> 1 
            {
                setWarp(1).
                sr(5).
            }
        }
        else
        {
            if warp > 0 kuniverse:timewarp:cancelwarp().
            wait until kuniverse:timewarp:issettled.
            break.
        }

        set cd to checkFunction(pAlt).
        update_display().
        wait 0.01.
    }
}


global function warp_to_next_soi 
{
    local sVal to lookDirUp(ship:prograde:forevector, sun:position).
    lock steering to sval.

    if ship:obt:hasnextpatch 
    {
        set target to "".
        wait until shipSettled().
        warpTo(ship:obt:nextpatcheta + time:seconds - 5).
    }

    until warp = 0 
    {
        set sVal to lookDirUp(ship:prograde:forevector, sun:position).
        update_display().
    }
}


global function warp_to_ksc_reentry_window 
{
    parameter rVal is 0.

    local sVal to lookDirUp( - ship:prograde:forevector, sun:position) + r(0, 0, rVal).
    lock steering to sVal.

    local minLongitude to choose 125 if ship:obt:inclination <= 90 else 135.
    local ts is time:seconds + 5.

    if ship:body:name = "Kerbin" 
    {
        out_msg("Sampling longitude advancement during orbit").
        local longitudeSample is ship:longitude.
        until time:seconds >= ts 
        {
            update_display().
            disp_timer(ts).
        }

        set longitudeSample to mod(ship:longitude - longitudeSample, 360).
        local longPerSec is longitudeSample / 5.
        local shipLong to choose ship:longitude if ship:longitude < minLongitude else ship:longitude + 360.
        set ts to time:seconds + mod(minLongitude - shipLong, 360) / longPerSec.

        warpTo(ts - 30).
        until time:seconds >= ts - 30 
        {
            update_display().
            disp_timer(ts).
            out_msg("Warping to reentry window for KSC landing").
        }
    }

    print "                                                        " at (2, 7).
    if warp > 0 set warp to 0.
    wait until kuniverse:timewarp:issettled.

    until time:seconds >= ts 
    {
        update_display().
        disp_timer(ts, "Timestamp").
    }

    if warp > 0 set warp to 0.

    disp_clear_block("timer").
}


global function stop_warp_at_mark 
{
    parameter _ts.
        
    local rVal is ship:facing:roll - lookDirUp(ship:facing:forevector, sun:position):roll.
    lock steering to lookdirup(nextnode:burnVector, sun:position) + r(0, 0, rVal).
    
    until time:seconds >= (_ts - 60) 
    {
       update_display().
       disp_timer(_ts, "Wait until").
       wait 1.
    }

    if warp > 2 set warp to 2.

    until time:seconds >= (_ts - 30) 
    {
       update_display().
       disp_timer(_ts, "Wait until").
       wait 1.
    }

    if warp > 1 set warp to 1.

    until time:seconds >= (_ts - 15) 
    {
       if warp > 1 set warp to 1.
       update_display().
       disp_timer(_ts, "Wait until").
    }

    if warp > 0 set warp to 0.
    wait until kuniverse:timewarp:issettled.

    update_display().
}