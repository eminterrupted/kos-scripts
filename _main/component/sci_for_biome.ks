@lazyGlobal off. 

parameter resetLog is false.

clearScreen.
runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/lib_core").
runOncePath("0:/lib/lib_display").
runOncePath("0:/lib/lib_dmag_sci").
runOncePath("0:/lib/lib_launch").
runOncePath("0:/lib/lib_sci").
runOncePath("0:/lib/lib_warp").
runOncePath("0:/lib/data/engine/lib_engine").
runOncePath("0:/lib/data/engine/lib_isp").
runOncePath("0:/lib/data/engine/lib_thrust").
runOncePath("0:/lib/data/engine/lib_twr").
runOncePath("0:/lib/data/ship/lib_mass").
runOncePath("0:/lib/part/lib_heatshield").

//
//** Main

//Vars
//local stateObj to init_state_obj().
local runmode to stateObj["runmode"].

local biome is "".
local biomeLog to "local:/biomeLog.json".
local biomeList to list().
local situation is "".

local sVal to lookDirUp(ship:prograde:vector, sun:position).
local tStamp is 0.
local tVal to 0.

set runmode to 0. 
lock steering to sVal.
lock throttle to tVal.

clearscreen.

until runmode = 99 {

    local sciMod is get_sci_mod_for_parts(ship:parts).
    
    if runmode = 0 {
        set sVal to lookDirUp(ship:prograde:vector, sun:position).
        bays on.
        set runmode to 1.
    }

    else if runmode = 1 {
        set sVal to lookDirUp(ship:prograde:vector, sun:position).
        wait 2.
        panels on.
        set tStamp to time:seconds + 21600.
        set runmode to 2.
    }

    else if runmode = 2 {

        local bayList to ship:partsTaggedPattern("doors.us").
        if bayList:length > 0 {
            for p in bayList {
                local m to p:getModule("USAnimateGeneric").
                if m:hasEvent("deploy primary bays") {
                    m:doEvent("deploy primary bays").
                }
            }
        }

        set runmode to 3.
    }

    else if runmode = 3 {
        if resetLog deletePath(biomeLog).
        set runmode to 4.
    }

    else if runmode = 4 {
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
        set situation to choose "[LOW]" if ship:altitude < info:altForSci[ship:body:name] else "[HIGH]".
        if not biomeList:join(";"):matchesPattern(addons:scanSat:currentbiome + situation) {
            set runmode to 7.
        }

        else {
            set runmode to 12.
        }

        
    }

    else if runmode = 7 {
        set sVal to lookDirUp(ship:prograde:vector, sun:position).
        set situation to choose "[LOW]" if ship:altitude < info:altForSci[ship:body:name] else "[HIGH]".
        set biome to addons:scansat:currentBiome + situation.
        log_sci_list(sciMod).
        biomeList:add(biome).
        writeJson(biomeList, biomeLog).

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
        set sVal to lookDirUp(ship:prograde:vector, sun:position).
        recover_sci_list(sciMod).
        
        set runmode to 12.
    }

    if runmode = 12 {
        set sVal to lookDirUp(ship:prograde:vector, sun:position).
        set situation to choose "[LOW]" if ship:altitude < info:altForSci[ship:body:name] else "[HIGH]".
        if biome <> addons:scansat:currentbiome + situation {
            if not biomeList:join(";"):contains(addons:scanSat:currentbiome + situation) {
                kuniverse:timewarp:cancelwarp().
                set runmode to 4.
            }
        }
        
        if time:seconds > tStamp {
            kuniverse:timewarp:cancelwarp().
            if kuniverse:timewarp:issettled set runmode to 99.
        } 
        
        disp_timer(tStamp).
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
