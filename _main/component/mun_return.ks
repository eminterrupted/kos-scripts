@lazyGlobal off.

parameter tgt is "Kerbin",
          rVal is 180.

clearscreen.

runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/lib_display").
runOncePath("0:/lib/lib_core").
runOncePath("0:/lib/lib_util").
runOncePath("0:/lib/lib_sci").
runOncePath("0:/lib/lib_warp").
runOncePath("0:/lib/nav/lib_calc_mnv").
runOncePath("0:/lib/nav/lib_deltav").
runOncePath("0:/lib/nav/lib_nav").
runOncePath("0:/lib/nav/lib_node").
runOncePath("0:/lib/part/lib_antenna").

//local stateObj to init_state_obj().
local runmode to stateObj["runmode"].
if runmode = 99 set runmode to 0.

update_display().
wait 5.

local tgtAlt is 35000.

local mnvCache is "local:/mnvCache.json".
local mnvObj is lex().
    if exists(mnvCache) set mnvObj to readJson(mnvCache).
local mnvNode is 0.

local sVal is lookDirUp(ship:prograde:vector, sun:position) + r(0, 0, rVal).
lock steering to sVal.

local tVal is 0.
lock throttle to tVal.


until runmode = 99 {
    
    //Make sure dish is deployed
    if runmode = 0 {
        set target to Body(tgt).
        set runmode to 4.
    }


    //Prep transfer object and node
    else if runmode = 4 {
        set sVal to lookDirUp(ship:prograde:vector, sun:position) + r(0, 0, rVal).
        set mnvObj to get_transfer_obj().
        set runmode to 6.
    }

    else if runmode = 6 {
        set sVal to lookDirUp(ship:prograde:vector, sun:position) + r(0, 0, rVal).
        set mnvObj to add_transfer_node(mnvObj, tgtAlt).
        set mnvObj["mnv"] to optimize_existing_node(mnvObj["mnv"]).
        cache_mnv_obj(mnvObj).
        set mnvNode to mnvObj["mnv"].
        set runmode to 7.
    }


    else if runmode = 7 {
        local tStamp to choose 60 if tStamp < mnvNode:eta else mnvNode:eta.
        set tStamp to time:seconds + tStamp.
        until time:seconds >= tStamp {
            update_display().
        }

        set runmode to 8.
    }

    //Execute Transfer
    else if runmode = 8 {
        set sVal to lookDirUp(mnvNode:burnvector, sun:position) + r(0, 0, rVal).
        warp_to_burn_node(mnvObj).
        set runmode to 10.
    }

    else if runmode = 10 {
        set sVal to lookDirUp(mnvNode:burnvector, sun:position) + r(0, 0, rVal).
        exec_node(nextNode).
        deletePath(mnvCache).
        set sVal to lookDirUp(ship:prograde:vector, sun:position) + r(0, 0, rVal).
        set runmode to choose 11 if ship:crewCapacity > 0 else 12.
    }

    // Time in high orbit to perform EVA
    else if runmode = 11 {
        until ship:altitude >= 250000 {
            update_display().
        }

        local tstamp is time:seconds + 60.

        until time:seconds >= tstamp {
            update_display().
        }

        set runmode to 12.
    }

    //Warp to the next sphere of influence
    else if runmode = 12 {
        set sVal to lookDirUp(ship:prograde:vector, sun:position) + r(0, 0, rVal).
        warp_to_next_soi().
        set target to "".
        until ship:body:name = tgt {
            update_display().
        }
        set runmode to 14.
    }

    else if runmode = 14 {
        set sVal to lookDirUp(ship:prograde:vector, sun:position) + r(0, 0, rVal).
        wait 5.
        warp_to_alt(125000).
        until ship:altitude <= 125000 {
            update_display().
        }

        if warp > 0 set warp to 0.
        set runmode to 26.
    }
    
    
    //Finish script
    else if runmode = 26 {
        logStr("Transfer maneuvers completed, ready for Reentry").
        runpath("0:/_main/component/mariner_reentry").
        
        set runmode to 99.
    }
        

    if ship:availableThrust < 0.1 and tVal > 0 {
        logStr("Staging").
        safe_stage().
    }

    if stateObj["runmode"] <> runmode {
        set stateObj["runmode"] to runmode.
        log_state(stateObj).
    }
}