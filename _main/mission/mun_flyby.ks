@lazyGlobal off.

parameter tgt is "Mun",
          rVal is 0.

clearscreen.

runOncePath("0:/lib/lib_display").
runOncePath("0:/lib/lib_core").
runOncePath("0:/lib/nav/lib_deltav").
runOncePath("0:/lib/nav/lib_nav").
runOncePath("0:/lib/lib_util").
runOncePath("0:/lib/nav/lib_node").
runOncePath("0:/lib/part/lib_antenna").
runOncePath("0:/lib/lib_dmag_sci").
runOncePath("0:/lib/lib_sci").

//local stateObj to init_state_obj().
local runmode to stateObj["runmode"].
if runmode = 99 set runmode to 0.

disp_main().
set target to body(tgt).

wait 5.

local finalAlt is 25000.
local waitTime is 300 + time:seconds.
local sciMod is get_sci_mod().
local dmagMod is get_dmag_mod().

if hastarget local xfrObj is mun_xfr_burn_obj().
local xfrNode is 0.


local sVal is ship:prograde + r(0, 0, rVal).
lock steering to sVal.
local tVal is 0.
lock throttle to tVal.


until runmode = 99 {
    
    if runmode = 0 {
        local dish is ship:partsTaggedPattern("comm.dish").
        for d in dish {
            activate_dish(d).
            logStr("Comm object Dish activated").
            wait 1.
            set_dish_target(d, kerbin:name).
            logStr("Dish target: " + kerbin:name).
        }

        set runmode to 1.
    }

    else if runmode = 1 {
        set sVal to ship:prograde + r(0, 0, rVal).
        
        if time:seconds < waitTime - 30 {
            if warp = 0 warpTo(waitTime - 30).
            set xfrObj["window"]["phaseAng"] to get_phase_angle().
            update_display().
        }
        update_display().
        disp_rendezvous_data(xfrObj).
        if time:seconds >= waitTime set runmode to 10.
    }

    else if runmode = 3 {
        set sVal to ship:prograde + r(0, 0, rVal).

        if get_phase_angle() < xfrObj["window"]["xfrPhaseAng"] + 180 {
            set xfrObj["window"]["phaseAng"] to get_phase_angle().
            update_display().
            disp_rendezvous_data(xfrObj).
        } else {
            set runmode to 10.
        }
    }

    else if runmode = 10 {
        set sVal to ship:prograde + r(0, 0, rVal).

        local mnvList to list(xfrObj["window"]["nodeAt"], 0, 0, xfrObj["burn"]["dv"]).
        set xfrNode to add_optimized_node(mnvList, finalAlt).
        add xfrNode.

        set xfrObj["window"]["nodeAt"] to time:seconds + xfrNode:eta.
        set xfrObj["burn"]["burnEta"] to (xfrNode:eta + time:seconds) - (xfrObj["burn"]["burnDur"] / 2).
        update_display().
        disp_rendezvous_data(xfrObj).
        set runmode to 20.
    }

    else if runmode = 20 {
        set sVal to ship:prograde + r(0, 0, rVal).
        if time:seconds >= xfrObj["burn"]["burnEta"] - 30 {
            if warp > 0 kuniverse:timewarp:cancelwarp().
            wait until kuniverse:timewarp:issettled.
            set runmode to 30.
        }
        else {
            if warp = 0 warpTo(xfrObj["burn"]["burnEta"] - 30).
            set xfrObj["window"]["phaseAng"] to get_phase_angle().
            update_display().
            disp_rendezvous_data(xfrObj).
        }
    }

    else if runmode = 30 {
        set sVal to xfrNode:burnVector:direction + r(0, 0, rval - 90).
        if time:seconds >= xfrObj["burn"]["burnEta"] set runmode to 31.
    }

    else if runmode = 31 {
        if xfrNode:burnvector:mag >= 5 {
            set sVal to xfrNode:burnVector:direction + r(0, 0, rval - 90).
            set tval to 1.
            set xfrObj["window"]["phaseAng"] to get_phase_angle().
            update_display().
            disp_rendezvous_data(xfrObj).
        } else {
            set runmode to 40.
        }
    }

    else if runmode = 40 {
        set sVal to xfrNode:burnVector:direction + r(0, 0, rval - 90).
        set tval to max(0, min(1, xfrNode:burnVector:mag / 5)).

        set xfrObj["window"]["phaseAng"] to get_phase_angle().
        update_display().
        disp_rendezvous_data(xfrObj).

        if xfrNode:burnVector:mag <= 0.05 {
            set tVal to 0.
            remove xfrNode.
            set runmode to 41.
        }
    }

    else if runmode = 41 {
        disp_clear_block("rendezvous").
        set runmode to 42.
    }

    else if runmode = 42 {
        when ship:body:name = "Mun" then {
            logStr("Collecting science from space around the Mun").
            deploy_sci_list(sciMod).
            log_sci_list(sciMod).
            log_dmag_list(dmagMod).
            wait 10.
            recover_sci_list(sciMod).
            recover_sci_list(dmagMod).
            wait 5.
            reset_sci_list(sciMod).
            reset_sci_list(dmagMod).
            logStr("Science collected, now coasting").

            set target to "Kerbin".
        }

        
        set runmode to 50.
    }

    else if runmode = 50 {
        update_display().
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


// local function add_optimized_node {
//     parameter mnvParam.

//     print "MSG: Optimizing transfer maneuver" at (2, 7).

//     until false {
//         set mnvParam to improve_node(mnvParam).
//         if get_node_score(mnvParam) >= 1 break.
//     }

//     local mnv to add_node(mnvParam).
//     set xfrObj["window"]["nodeAt"] to mnv:eta + time:seconds.
//     set xfrObj["burn"]["burnEta"] to (mnv:eta + time:seconds) - (xfrObj["burn"]["burnDur"] / 2).
//     print "MSG: Optimized maneuver found                                " at (2, 7).
//     wait 2.
//     print "                                                             " at (2, 7).
//     return mnv.
// }


// local function improve_node {
//     parameter data.

//     //hill climb to find the best time
//     local curScore is get_node_score(data).
//     local mnvCandidates is list(
//         list(data[0] + .05, data[1], data[2], data[3])
//         ,list(data[0] - .05, data[1], data[2], data[3])
//         ,list(data[0], data[1], data[2], data[3] + .01)
//         ,list(data[0], data[1], data[2], data[3] + -.01)
//     ).

//     for c in mnvCandidates {
//         local candScore to get_node_score(c).
//         if candScore > curScore {
//             set curScore to get_node_score(c).
//             set data to c.
//             print "(Current score: " + round(curScore, 5) + "     " at (35, 7).
//         }
//     }

//     return data.
// }


// local function get_node_score {
//     parameter data.

//     local score to 0.
//     local mnvTest to node(data[0], data[1], data[2], data[3]).
//     add mnvTest.
//     if mnvTest:obt:hasnextpatch {
//         set score to (mnvTest:obt:nextpatch:periapsis) / finalalt.
//     }
//     wait 0.01.
//     remove mnvTest.
//     return score.
// }


local function mun_xfr_burn_obj {
    disp_main().

    local retObj is lex().
    set retObj to lex("tgt", target, "window", get_mun_xfr_window()).
    set retObj["burn"] to get_mun_xfr_burn_data(retObj["window"]["nodeAt"]).
    set retObj["window"]["phaseAng"] to get_phase_angle().

    return retObj.
}