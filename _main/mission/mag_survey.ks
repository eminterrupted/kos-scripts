@lazyGlobal off.

parameter _rVal is 0.

// Change these variables per orbit
local tgtEcc is .175.
local tgtInc is 20.
// End user-managed variables

clearscreen.

runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/display/lib_display").

runOncePath("0:/lib/lib_core").
runOncePath("0:/lib/lib_sci").
runOncePath("0:/lib/lib_util").
runOncePath("0:/lib/lib_warp").
runOncePath("0:/lib/nav/lib_calc_mnv").
runOncePath("0:/lib/nav/lib_deltav").
runOncePath("0:/lib/nav/lib_mnv").
runOncePath("0:/lib/nav/lib_nav").
runOncePath("0:/lib/nav/lib_node").
runOncePath("0:/lib/nav/lib_mnv").
runOncePath("0:/lib/part/lib_antenna").

local matchIncScript is "0:/_main/adhoc/simple_inclination_change".
compile(matchIncScript) to "local:/matchInc".
set matchIncScript to "local:/matchInc".

local orbitChangeScript is "0:/_main/adhoc/orbit_change".
copyPath(orbitChangeScript, "local:/orbit_change").
set orbitChangeScript to "local:/orbit_change".

local desiredApo is 0.
local mnvNode is node(0, 0, 0, 0).
local mnvObj is lex().
local sciList is get_sci_mod_for_parts(ship:parts).

local runmode to stateObj["runmode"].
if runmode = 99 set runmode to 0.

local sVal is lookDirUp(ship:prograde:vector, sun:position) + r(0, 0, _rVal).
lock steering to sVal.
local tVal is 0.
lock throttle to tVal.

//Staging trigger
when stage:liquidFuel < 0.1 and throttle > 0 then {
    safe_stage().
    preserve.
}

// Program
update_display().
main().

//Main function
local function main {
    until runmode = 99 {

        //Deploy the sat panels / antennas if not already
        if runmode = 0 {
            set sVal to lookDirUp(ship:prograde:vector, sun:position) + r(0, 0, _rVal).

            panels on.

            local dish is ship:partsTaggedPattern("comm.dish").
            for d in dish {
                activate_dish(d).
                logStr("Comm object Dish activated").
                wait 1.
                set_dish_target(d, kerbin:name).
                logStr("Dish target: " + get_dish_target(d)).
            }

            set runmode to 2.
        }

        // Setup the science triggers
        else if runmode = 2 {
            when ship:altitude < info:altForSci[ship:body:name] then {
                log_sci_list(sciList).
                recover_sci_list(sciList, true).
            }

            when ship:altitude > info:altForSci[ship:body:name] then {
                log_sci_list(sciList).
                recover_sci_list(sciList, true).
            }

            set runmode to 5.
        }
            
        // Check to see if launch script placed us in proper eccentricity
        // If not, run orbit change routine
        else if runmode = 5 {   
            if ship:orbit:eccentricity < tgtEcc {
                set runmode to 10.
            } else {
                set runmode to 20.
            }
        }

        // Calculate how much to raise from our periapsis to reach proper ecc
        else if runmode = 10 {
            local eccDiff is tgtEcc * (ship:periapsis + ship:apoapsis + (body:radius * 2)).
            set desiredApo to ship:periapsis + eccDiff + (eccDiff * (tgtEcc / 2)) .
            set runmode to 12.
        }

        // Set up the node
        else if runmode = 12 {
            set mnvNode to add_simple_circ_node("pe", desiredApo).
            set mnvObj to get_burn_obj_from_node(mnvNode).
            set runmode to 14.
        }

        // Warp to node
        else if runmode = 14 {
            warp_to_burn_node(mnvObj).
            set runmode to 16.
        }

        // Execute the burn
        else if runmode = 16 {
            exec_node(mnvNode).
            set runmode to 20.
        }
        
        // Check our inclination. If low, run inclination change routine
        else if runmode = 20 {
            if ship:orbit:inclination < tgtInc {
                set runmode to 22.
            } else {
                set runmode to 30.
            }
        }

        else if runmode = 22 {
            runPath(matchIncScript, tgtInc).
            set runmode to 30.
        }

        //Runmode 88MPH - You're going to see some seriously mild shit
        else if runmode = 88 {
            set sVal to lookDirUp(ship:prograde:vector, sun:position) + r(0, 0, _rVal).

            end_main().

            set runmode to 99.
        }
        
        update_display().
    }
}

local function end_main {
    set sVal to lookDirUp(ship:prograde:vector, sun:position) + r(0, 0, _rVal).
    lock steering to sVal.

    set tVal to 0.
    lock throttle to tVal.

    logStr("Mission completed").
}