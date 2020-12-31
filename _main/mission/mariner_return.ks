@lazyGlobal off.

parameter tgt is "Kerbin",
          rVal is 180.

local _returnAlt is 35000.

clearscreen.

runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/lib_display").
runOncePath("0:/lib/lib_core").
runOncePath("0:/lib/lib_util").
runOncePath("0:/lib/lib_warp").
runOncePath("0:/lib/nav/lib_calc_mnv").
runOncePath("0:/lib/nav/lib_deltav").
runOncePath("0:/lib/nav/lib_nav").
runOncePath("0:/lib/nav/lib_node").

//FilePaths
local mnvCache is "local:/mnvCache.json".
local reentryPath is "local:/mariner_reentry". 
copyPath("0:/_main/component/mariner_reentry", reentryPath).

//local stateObj to init_state_obj().
local runmode to stateObj["runmode"].
if runmode = 99 set runmode to 0.

update_display().

local mnvNode is 0.
local mnvObj is lex().
if exists(mnvCache) set mnvObj to readJson(mnvCache).

local sVal is lookDirUp(ship:prograde:vector, sun:position) + r(0, 0, rVal).
lock steering to sVal.

local tVal is 0.
lock throttle to tVal.


until runmode = 99 {
    
// Add a pair of maneuver nodes to return to Kerbin
    // One to escape the current mun, burned at Pe
    // Second to reduce alt around Kerbin to tgtAlt
    if runmode = 0 {

        set sVal to lookDirUp(ship:prograde:vector, sun:position) + r(0, 0, rVal).
        add_node_mun_return(_returnAlt).
        
        set runmode to 1.
    }

    else if runmode = 1 {
        if hasNode {
            set runmode to 2.
        } else {
            set runmode to 12.
        }
    }

//Execute transfer
    else if runmode = 2 {
        set mnvNode to nextNode.
        set mnvObj to get_burn_obj_from_node(mnvNode).
        cache_mnv_obj(mnvObj).
        
        set runmode to 4.
    }

    else if runmode = 4 {
        set sVal to lookDirUp(nextNode:burnvector, sun:position) + r(0, 0, rVal).
        local tStamp to choose time:seconds + 15 if time:seconds < mnvObj["burnEta"] else mnvObj["burnEta"].

        until time:seconds >= tStamp {
            update_display().
            disp_timer(tStamp).
        }

        disp_clear_block("timer").
        warp_to_burn_node(mnvObj).
        set runmode to 8.
    }

    else if runmode = 8 {
        set sVal to lookDirUp(nextNode:burnvector, sun:position) + r(0, 0, rVal).
        exec_node(nextNode).
        deletePath(mnvCache).
        set runmode to 1.
    }

    else if runmode = 12 {
        if not check_value(ship:periapsis, _returnAlt, 2500) {
            if not hasNode {
                set runmode to 14.
            } else {
                set runmode to 1.
            }
        }

        else set runmode to 20.
    }

//Correction burn
    else if runmode = 14 {
        set mnvNode to add_optimized_node(list(time:seconds + 300, 0, 0, 10), _returnAlt, "pe", ship:body, 0.005).
        set runmode to 1.
    }

    else if runmode = 20 {
        set sVal to lookDirUp(ship:prograde:vector, sun:position) + r(0, 0, rVal).
        warp_to_alt(125000).
        until ship:altitude <= 125000 {
            update_display().
        }

        if warp > 0 set warp to 0.
        wait until kuniverse:timewarp:issettled.
        set runmode to 26.
    }
    
    
    //Finish script
    else if runmode = 26 {
        logStr("Transfer maneuvers completed, ready for Reentry").
        runPath(reentryPath).
        
        set runmode to 99.
    }

    set_rm(runmode).
}

unlock steering.
unlock throttle.