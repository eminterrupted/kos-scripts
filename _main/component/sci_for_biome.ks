@lazyGlobal off. 

parameter resetLog is false.

clearScreen.
runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/lib_core").
runOncePath("0:/lib/display/lib_display").
runOncePath("0:/lib/lib_dmag_sci").
runOncePath("0:/lib/lib_sci").
runOncePath("0:/lib/lib_warp").

//
//** Main

//Vars
local runmode to stateObj["runmode"].

local biome is "".
local biomeLog to "local:/biomeLog.json".
local biomeList to list().
local sciMod is get_sci_mod_for_parts(ship:parts).
local situation is "".
local tStamp is 21600.

lock steering to lookDirUp(ship:prograde:vector, sun:position).

set runmode to 0. 

clearscreen.

until runmode = 99 {
    
    if runmode = 0 {
        out_msg("Confirming bays and panels are open").
        
        local usBayList to ship:partsTaggedPattern("doors.us").
        if usBayList:length > 0 {
            out_msg("Deploying US Bay Doors").
            for p in usBayList {
                local m to p:getModule("USAnimateGeneric").
                do_event(m, "deploy primary bays").
                do_event(m, "deploy secondary bays").
                } 
        } else {
            bays on.
        }

        panels on.
        set runmode to 2.
    }

    else if runmode = 2 {
        out_msg("Setting duration for mission to " + tStamp + "s").
        set tStamp to time:seconds + tStamp.
        set runmode to 3.
    }

    else if runmode = 3 {
        if resetLog {
            deletePath(biomeLog).
            out_msg("Resetting biome log").
        }
        set runmode to 4.
    }

    else if runmode = 4 {
        out_msg("Printing biome list").
        set biomeList to choose readJson(biomeLog) if exists(biomeLog) else list().
        
        print "BiomeList" at (2, 40).
        print "---------" at (2, 41).
        local n is 42. 
        for b in biomeList {
            print b + "            " at (2, n).
            set n to n + 1.
        }

        set runmode to 5.
    }

    else if runmode = 5 {
        set situation to choose "(LOW)" if ship:altitude < info:altForSci[ship:body:name] else "(HIGH)".
        set biome to "[" + addons:scanSat:currentbiome + "]" + situation.
        
        if not biomeList:join(";"):matchesPattern(biome) {
            out_msg("New biome / situation: " + biome).
            set runmode to 7.
        }

        else {
            out_msg("Current biome / situation: " + biome).
            set runmode to 12.
        }

        
    }

    else if runmode = 7 {
        set situation to get_situation().
        set biome to "[" + addons:scansat:currentBiome + "]" + situation.
        log_sci_list(sciMod).
        biomeList:add(biome).
        writeJson(biomeList, biomeLog).

        out_msg("New biome / situation logged: " + biome).

        print "BiomeList" at (2, 40).
        print "---------" at (2, 41).
        local n is 42. 
        for b in biomeList {
            print b + "            " at (2, n).
            set n to n + 1.
        }

        set runmode to 9.
    }

    else if runmode = 9 {
        out_msg("Recovering science from experiments").
        recover_sci_list(sciMod).
        
        set runmode to 12.
    }

    if runmode = 12 {
        set situation to get_situation().

        out_msg("Current biome / situation: " + biome).
        if biome <> "[" + addons:scansat:currentbiome + "]" + situation {
            if not biomeList:join(";"):contains("[" + addons:scanSat:currentbiome + "]" + situation) {
                kuniverse:timewarp:cancelwarp().
                set runmode to 4.
            }
        }
        
        if time:seconds > tStamp {
            kuniverse:timewarp:cancelwarp().
            if kuniverse:timewarp:issettled set runmode to 99.
        } 
        
        disp_timer(tStamp, "Mission Duration").
    }
    
    update_display().

    if stateObj["runmode"] <> runmode {
        set stateObj["runmode"] to runmode.
        log_state(stateObj).
    }
}

clearScreen.

//** End Main
//

local function get_situation {
    local situ to choose "(LOW)" if ship:altitude < info:altForSci[ship:body:name] else "(HIGH)".
    return situ.
}