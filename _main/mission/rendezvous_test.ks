@lazyGlobal off.

parameter tgt is "Mun",
          rVal is 0.

clearscreen.

runOncePath("0:/lib/lib_display").
runOncePath("0:/lib/data/nav/lib_deltav").
runOncePath("0:/lib/data/nav/lib_nav").
runOncePath("0:/lib/lib_util").
runOncePath("0:/lib/data/nav/lib_node").

local stateObj to init_state_obj().
//local runmode to stateObj["runmode"].
local runmode to 0.
if runmode = 99 set runmode to 0.

set target to body(tgt).
local finalAlt is 25000.

disp_obt_main().
local xfrObj is mun_xfr_burn_obj().
local xfrNode is 0.

local sVal is ship:prograde + r(0, 0, rVal).
lock steering to sVal.
local tVal is 0.
lock throttle to tVal.

until runmode = 99 {
    
    if runmode = 0 {
        set sVal to ship:prograde + r(0, 0, rVal).
        set xfrObj["window"]["phaseAng"] to get_phase_angle().
        update_disp().
        set runmode to 1.
    }

    else if runmode = 1 {
        if get_phase_angle() > xfrObj["window"]["xfrPhaseAng"] {//= 135 and get_phase_angle() <= 235 {
            if warp > 0 kuniverse:timewarp:cancelwarp().
            wait until kuniverse:timewarp:issettled .
            set runmode to 10.
        }
        else {
            if warp = 0 set warp to 3.
            set xfrObj["window"]["phaseAng"] to get_phase_angle().
            if time:seconds > xfrObj["burn"]["burnEta"] + time:seconds {
                set xfrObj to lex(). 
                set xfrObj to mun_xfr_burn_obj().
            }
            update_disp().
        }
    }

    else if runmode = 10 {
        set sVal to ship:prograde + r(0, 0, rVal).

        local mnvList to list(xfrObj["window"]["nodeAt"], 0, 0, xfrObj["burn"]["dv"]).
        set xfrNode to add_optimized_node(mnvList).

        set xfrObj["window"]["nodeAt"] to time:seconds + xfrNode:eta.
        set xfrObj["burn"]["burnEta"] to (xfrNode:eta + time:seconds) - (xfrObj["burn"]["burnDur"] / 2) - 5.
        update_disp().
        set runmode to 20.
    }

    else if runmode = 20 {
        lock steering to ship:prograde + r(0, 0, rval).
        if time:seconds >= xfrObj["burn"]["burnEta"] - 30 set runmode to 30.
        else {
            set xfrObj["window"]["phaseAng"] to get_phase_angle().
            update_disp().
        }
    }

    else if runmode = 30 {
        lock steering to xfrNode:burnVector:direction + r(0, 0, rval).
        until xfrNode:burnvector:mag <= 2 {
            //set tval to 1.
            set xfrObj["window"]["phaseAng"] to get_phase_angle().
            update_disp().
        }
        set runmode to 40.
    }

    else if runmode = 40 {
        lock steering to xfrNode:burnVector:direction + r(0, 0, rval).
        set tval to 1 - max(0, min(1, xfrNode:burnVector:mag * 0.25)).

        set xfrObj["window"]["phaseAng"] to get_phase_angle().
        update_disp().

        if xfrNode:burnVector:mag <= 0.1 {
            set tVal to 0.
            set runmode to 50.
        }
    }

    else if runmode = 50 {
        set xfrObj["window"]["phaseAng"] to get_phase_angle().
        update_disp().
    }

    if stateObj["runmode"] <> runmode {
        set stateObj["runmode"] to runmode.
        log_state(stateObj).
    }
}


local function add_optimized_node {
    parameter mnvParam.

    print "MSG: Finding optimized maneuver node for transfer" at (2, 7).
   
    until false {
        set mnvParam to improve_node(mnvParam).
        if get_node_score(mnvParam) >= 1 break.
    }

    local mnv to add_node(mnvParam).
    set xfrObj["window"]["nodeAt"] to mnv:eta + time:seconds.
    set xfrObj["burn"]["burnEta"] to (mnv:eta + time:seconds) - (xfrObj["burn"]["burnDur"] / 2).
    print "MSG: Optimized maneuver found                    " at (2, 7).
    wait 2.
    print "                                                 " at (2, 7).
    return mnv.
}


local function improve_node {
    parameter data.

    //hill climb to find the best time
    local curScore is get_node_score(data).
    local mnvCandidates is list(
        list(data[0] + .05, data[1], data[2], data[3])
        ,list(data[0] - .05, data[1], data[2], data[3])
        ,list(data[0], data[1], data[2], data[3] + .01)
        ,list(data[0], data[1], data[2], data[3] + -.01)
    ).

    for c in mnvCandidates {
        local candScore to get_node_score(c).
        if candScore > curScore {
            set curScore to get_node_score(c).
            set data to c.
            print "Current score: " + curScore at (2, 55).
        }
    }

    return data.
}


local function get_node_score {
    parameter data.

    local score to 0.
    local mnvTest to node(data[0], data[1], data[2], data[3]).
    add mnvTest.
    if mnvTest:obt:hasnextpatch {
        set score to (mnvTest:obt:nextpatch:periapsis) / finalalt.
    }
    wait 0.01.
    remove mnvTest.
    return score.
}


local function mun_xfr_burn_obj {
    disp_obt_main().

    local retObj is lex().
    set retObj to lex("tgt", target, "window", get_mun_xfr_window()).
    set retObj["burn"] to get_mun_xfr_burn_data(retObj["window"]["nodeAt"]).
    set retObj["window"]["phaseAng"] to get_phase_angle().

    return retObj.
}


local function update_disp {
    disp_obt_main().
    disp_obt_data().
    disp_tel().
    disp_eng_perf_data().
    disp_rendezvous_data(xfrObj).
}