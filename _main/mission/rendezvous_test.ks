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
local runmode to stateObj["runmode"].
if runmode = 99 set runmode to 0.

set target to body(tgt).
local finalAlt is 25000.

disp_obt_main().
local xfrObj is mun_xfr_burn_obj().

local sVal is ship:prograde + r(0, 0, rVal).
lock steering to sVal.

until runmode = 99 {
    
    if runmode = 0 {
        set sVal to ship:prograde + r(0, 0, rVal).
        local phase to get_phase_angle().
        set xfrObj["window"]["phaseAng"] to phase.

        if phase < xfrObj["window"]["xfrPhaseAng"] and phase > 0 set runmode to 10.
        else update_disp().
    }

    else if runmode = 10 {
        set sVal to ship:prograde + r(0, 0, rVal).

        local mnvList to list(xfrObj["window"]["nodeAt"], 0, 0, xfrObj["burn"]["dv"]).
        local xfrNode to add_optimized_node(mnvList).
        set xfrObj["window"]["nodeAt"] to time:seconds + xfrNode:eta.
        update_disp().
        set runmode to 20.
    }

    else if runmode = 20 {
        lock steering to ship:prograde + r(0, 0, rval).
        set xfrObj["window"]["phaseAng"] to 180 - get_phase_angle().
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
        local oldScore is get_node_score(mnvParam).
        set mnvParam to improve_node(mnvParam).
        local newScore is get_node_score(mnvParam).
        if oldScore >= newScore break.
    }

    local mnv to add_node(mnvParam).
    print "MSG: Optimized maneuver found                    " at (2, 7).
    wait 2.
    print "                                                 " at (2, 7).
    return mnv.
}


local function improve_node {
    parameter data.

    //hill climb to find the best time
    local curScore is get_node_score(data).
    local bestMnv is data.
    local mnvCandidates is list(
        list(data[0] + 0.1, data[1], data[2], data[3])
        ,list(data[0] - 0.1, data[1], data[2], data[3])
    ).

    for c in mnvCandidates {
        local candScore to get_node_score(c).
        if candScore >= curScore {
            set curScore to get_node_score(c).
            set bestMnv to c.
        }
        if curScore >= 1 break.
    }

    return bestMnv.
}


local function get_node_score {
    parameter dataToScore.

    local score to 0.
    local mnvTest to add_node(dataToScore).
    if mnvTest:obt:hasnextpatch {
        set score to (mnvTest:obt:nextpatch:periapsis) / finalalt.
    }
    set xfrObj["window"]["nodeAt"] to time:seconds + mnvTest:eta.
    remove_node(mnvTest).
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