@lazyGlobal off.

parameter _tgtArgPe,
          _tgtLAN,
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
runOncePath("0:/lib/nav/lib_circ_burn").

local runmode to 0.

disp_main().

wait 2.

// Creating the new orbit
local tgtObt is createOrbit(
    ship:orbit:inclination, 
    (((_tgtAp + ship:body:radius) - (_tgtPe + ship:body:radius)) / (_tgtAp + _tgtPe + (ship:body:radius * 2))),
    ((_tgtAp + _tgtPe) / 2), 
    _tgtLAN,
    _tgtArgPe,
    ship:orbit:meanAnomalyAtEpoch,
    ship:orbit:epoch,
    ship:body).

// Inclination match burn data
local utime to time:seconds + 1200.

//Maneuver node structures
local mnvParam is list(utime, 0, 0, 50).
local mnvNode is node(0, 0, 0, 0).
local mnvObj is lex().
local tStamp is 0.

local tgtAnomaly is 360 - (ship:orbit:argumentofperiapsis - _tgtArgPe).

//Steering
local rVal is 0.

local sVal is lookDirUp(ship:facing:forevector, sun:position) + r(0, 0, rVal).
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
            set mnvParam to optimize_node_list(mnvParam, _tgtAp, "ap", list(0.975, 1.025), true).

            set runmode to 2.
        }

        else if runmode = 2 {
            
            set mnvNode to node(mnvParam[0], mnvParam[1], mnvParam[2], mnvParam[3]).
            add mnvNode.
            
            set mnvObj to get_burn_obj_from_node(mnvNode).

            set runmode to 3.
        }

        else if runmode = 3 {
            warpTo(mnvObj["burnEta"] - 15).
            until time:seconds >= mnvObj["burnEta"] {
                update_display().
                disp_timer(mnvObj["burnEta"]).
            }

            if warp > 0 set warp to 0.
            wait until kuniverse:timewarp:issettled.

            disp_clear_block("timer").

            set runmode to 5.
        }

        // Do burn
        else if runmode = 5 {

            exec_node(nextNode).

            remove mnvNode.

            set runmode to 99.
        }

        update_display().
    }
}


//Functions
local function end_main {
    set sVal to lookDirUp(ship:facing:forevector, sun:position).
    lock steering to sVal.

    set tVal to 0.
    lock throttle to tVal.

    wait 5.
}