@lazyGlobal off.

local _returnAlt is 35000.

clearscreen.

runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/lib_display").
runOncePath("0:/lib/lib_core").
runOncePath("0:/lib/lib_util").
runOncePath("0:/lib/lib_warp").
runOncePath("0:/lib/lib_calc_mnv").
runOncePath("0:/lib/lib_deltav").
runOncePath("0:/lib/lib_nav").
runOncePath("0:/lib/lib_node").

//FilePaths
local mnvCache is "local:/mnvCache.json".
local reentryPath is "local:/mariner_reentry". 
compile("0:/_main/mission/simple_reentry") to reentryPath.

//local stateObj to init_state_obj().
local runmode to stateObj["runmode"].
if runmode = 99 set runmode to 0.

update_display().

local mnvNode is 0.
local mnvObj is lex().
if exists(mnvCache) set mnvObj to readJson(mnvCache).

local sVal is lookDirUp(ship:prograde:vector, sun:position).
lock steering to sVal.

local tVal is 0.
lock throttle to tVal.


until runmode = 99 {
    
// Add a pair of maneuver nodes to return to Kerbin
    // One to escape the current mun, burned at Pe
    // Second to reduce alt around Kerbin to tgtAlt
    if runmode = 0 {
        out_msg("Adding return nodes from mun").
        set sVal to lookDirUp(ship:prograde:vector, sun:position).
        add_node_mun_return(_returnAlt).
        
        set runmode to 1.
    }

    else if runmode = 1 {
        if hasNode {
            out_msg("Maneuver node found on flight plan").
            set runmode to 4.
        } else {
            out_msg("No nodes present").
            set runmode to 12.
        }
    }

//Execute transfer
    else if runmode = 4 {
        out_msg("Getting burn object from maneuver node").
        set mnvNode to nextNode.
        set mnvObj to get_burn_obj_from_node(mnvNode).
        cache_mnv_obj(mnvObj).
  
        out_msg("Warping to burn node").
        set sVal to lookDirUp(nextNode:burnvector, sun:position).
        local tStamp to time:seconds + 15.

        until time:seconds >= tStamp {
            update_display().
            disp_burn_data(tStamp).
        }
        warp_to_burn_node(mnvObj).
        set runmode to 8.
    }

    else if runmode = 8 {
        out_msg("Executing node").
        set sVal to lookDirUp(nextNode:burnvector, sun:position).
        exec_node(nextNode).
        deletePath(mnvCache).
        disp_clear_block("burn_data").
        set runmode to 1.
    }

    else if runmode = 12 {
        out_msg("Checking flight plan for additional nodes").
        if not check_value(ship:periapsis, _returnAlt, 2500) {
            if not hasNode {
                out_msg("Free return trajectory pe adjustment needed").
                out_info("Current: " + ship:periapsis + " Target: " + _returnAlt).
                set runmode to 14.
            } else {
                set runmode to 1.
            }
        } else {
            out_msg("Free return trajectory confirmed, current Pe: " + ship:periapsis).
            set runmode to 20.
        }
    }

//Correction burn
    else if runmode = 14 {
        out_msg("Adding free return trajectory correction burn").
        set mnvNode to add_optimized_node(list(time:seconds + 300, 0, 0, 10), _returnAlt, "pe", ship:body, 0.005).
        out_info().
        set runmode to 1.
    }

    else if runmode = 20 {
        out_msg("Vessel ready for reentry").
        logStr("Transfer maneuvers completed, ready for simple_reentry").
        runPath(reentryPath).
        
        set runmode to 99.
    }

    rm(runmode).
}

unlock steering.
unlock throttle.