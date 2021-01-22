@lazyGlobal off.

parameter _tgtAp,
          _tgtPe,
          _tgtArgPe is ship:obt:argumentofperiapsis.

clearscreen.

runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/display/lib_display").
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
local utime to time:seconds + 60.

//Variables
local burnMode to "".
local mnvParam is list(utime, 0, 0, 100).
local mnvNode is node(0, 0, 0, 0).
local mnvObj is lex().
local tgtAnomaly is 0.
local tStamp is 0.

//local tgtAnomaly is mod(360 - _tgtArgPe + (ship:orbit:longitudeOfAscendingNode / 2), 360).
set tgtAnomaly to mod(360 + _tgtArgPe - ship:orbit:argumentofperiapsis, 360).

print "tgtAnomaly: " + tgtAnomaly at (2, 25).
print "_tgtArgPe:  " + _tgtArgPe at (2,26).
print "argPe:      " + ship:orbit:argumentofperiapsis at (2, 27).
print "LAN:        " + ship:orbit:lan at (2, 28).


//Steering
lock steering to lookDirUp(ship:prograde:vector, sun:position).

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
            set tStamp to eta_to_ta(ship:orbit, tgtAnomaly).
            set runmode to 1.
        }

        else if runmode = 1 {
            set burnMode    to choose "ap" if _tgtAp > ship:periapsis else "pe".
            set mnvParam    to list(time:seconds + tStamp, mnvParam[1], mnvParam[2], GetDVForPrograde(_tgtAp, ship:periapsis, ship:body)).
            set mnvParam    to OptimizeNodeData(mnvParam, _tgtAp, burnMode, ship:body, 0.001).
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
            ExecuteNode(nextNode).
            set runmode to 7.
        }

        // Now do a circ burn at Ap to bring Pe to target
        else if runmode = 7 {
            set burnMode to choose "ap" if eta:apoapsis < eta:periapsis else "pe".
            exec_circ_burn(burnMode, _tgtPe).

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