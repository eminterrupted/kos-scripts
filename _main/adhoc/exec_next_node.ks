@lazyGlobal off.

parameter rVal is 180,
          runmodeReset is false.

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

//local stateObj to init_state_obj().
local runmode to stateObj["runmode"].
if runmode = 99 set runmode to 0.
if runmodeReset set runmode to 0.

update_display().
wait 1.

local mnvCache is "local:/mnvCache.json".
local mnvObj is choose readJson(mnvCache) if exists(mnvCache) else lex().
local mnvNode is 0.
local tStamp is 0.


local sVal is lookDirUp(nextnode:burnvector, sun:position) + r(0, 0, rVal).
lock steering to sVal.

local tVal is 0.
lock throttle to tVal.


until runmode = 99 {
    
    //Make sure dish is deployed
    if runmode = 0 {
        set sVal to lookDirUp(nextnode:burnvector, sun:position) + r(0, 0, rVal).
        set mnvNode to nextNode.
        set mnvObj to get_burn_obj_from_node(mnvNode).
        cache_mnv_obj(mnvObj).
        set runmode to 7.
    }


    else if runmode = 7 {
        set tStamp to choose 30 if tStamp < mnvNode:eta else mnvNode:eta.
        set tStamp to time:seconds + tStamp.
        until time:seconds >= tStamp {
            update_display().
            disp_timer(tStamp).
        }

        disp_clear_block("timer").

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