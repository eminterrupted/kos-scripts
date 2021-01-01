@lazyGlobal off.

parameter _tgtArgPe,
          _tgtAp is ship:apoapsis + 1000,
          _tgtPe is ship:periapsis.

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
runOncePath("0:/lib/nav/lib_mnv").

local runmode to 0.

disp_main().

// Inclination match burn data
local utime to time:seconds + 1200.

//Maneuver node structures
local mnvParam is list(utime, 0, 0, 5).
local mnvNode is node(0, 0, 0, 0).
local mnvObj is lex().
local tStamp is 0.

local tgtAnomaly is 360 - (ship:orbit:argumentofperiapsis - _tgtArgPe).

//Steering
local sVal is lookDirUp(ship:prograde:vector, sun:position).
lock steering to sVal.

local tVal is 0.
lock throttle to tVal.

//Staging trigger
when ship:availableThrust < 0.1 and tVal > 0 then {
    safe_stage().
    preserve.
}

main().
end_main().

//Main
local function main {
    until runmode = 99 {
        
        // get wait time
        if runmode = 0 {
            set tStamp to abs(tgtAnomaly - ship:orbit:trueanomaly) * (ship:obt:period / 360).
            set runmode to 1.
        }

        else if runmode = 1 {
            set mnvParam to list(time:seconds + tStamp, mnvParam[1], mnvParam[2], mnvParam[3]).
            set mnvParam to optimize_node_list(mnvParam, _tgtAp, "ap", ship:body, 0.001).
            set runmode to 2.
        }

        else if runmode = 2 {
            set mnvNode to node(mnvParam[0], mnvParam[1], mnvParam[2], mnvParam[3]).
            add mnvNode.
            set mnvObj to get_burn_obj_from_node(mnvNode).
            set runmode to 3.
        }

        else if runmode = 3 {
            warp_to_burn_node(mnvObj).
            set runmode to 5.
        }

        // Do burn
        else if runmode = 5 {
            exec_node(nextNode).
            set runmode to 7.
        }

        // Now do a circ burn at Ap to bring Pe to target
        else if runmode = 7 {
            exec_circ_burn("ap", _tgtPe).

            set runmode to 99.
        }

        update_display().
    }
}


//Functions
local function end_main {
    unlock steering.
    unlock throttle.
}