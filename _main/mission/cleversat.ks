@lazyGlobal off.

// Change these variables per orbit
local tgtBody is kerbin.

local obtAp is 8509523.
local obtPe is 7303756.
local obtInc is 1.
local obtLAN is ship:orbit:longitudeofascendingnode.
local obtArgPe is 50.6.
// End user-managed variables

parameter _rVal is 0.

clearscreen.

runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/lib_display").

runOncePath("0:/lib/lib_core").
runOncePath("0:/lib/lib_math").
runOncePath("0:/lib/lib_sci").
runOncePath("0:/lib/lib_util").
runOncePath("0:/lib/lib_warp").
runOncePath("0:/lib/nav/lib_calc_mnv").
runOncePath("0:/lib/nav/lib_deltav").
runOncePath("0:/lib/nav/lib_mnv").
runOncePath("0:/lib/nav/lib_nav").
runOncePath("0:/lib/nav/lib_node").
runOncePath("0:/lib/part/lib_antenna").

local matchIncScript is "0:/_main/adhoc/simple_inclination_change".
copyPath(matchIncScript, "local:/matchInc").
set matchIncScript to "local:/matchInc".

local runmode to 0.

local tgtObt to createOrbit(
    obtInc,
    calc_ecc(obtAp, obtPe, tgtBody),
    (tgtBody:radius + obtAp) + (tgtBody:radius + obtPe) / 2,   // Avg SMA
    obtLAN,
    obtArgPe,       
    0,              //MeanTime Anomaly 
    ship:obt:epoch,
    tgtBody
).

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

    //Deploy dish if not already
        if runmode = 0 {
            set sVal to lookDirUp(ship:prograde:vector, sun:position) + r(0, 0, _rVal).

            local dish is ship:partsTaggedPattern("comm.dish").
            for d in dish {
                activate_dish(d).
                logStr("Comm object Dish activated").
                wait 1.
                set_dish_target(d, kerbin:name).
                logStr("Dish target: " + kerbin:name).
            }

            set runmode to 5.
        }
        
    // Boost Orbit Raise Burn
        
        // Adds a burn to this flight plan. 
        // If isCircBurn is false, raise; else, circularize
        else if runmode = 5 {
            print ("I'm in cleversat:runmode 5") at (2, 50).

            if ship:orbit:argumentofperiapsis < tgtObt:argumentofPeriapsis - 5 or ship:orbit:argumentofperiapsis > tgtObt:argumentOfPeriapsis + 5 {
                exec_match_arg_pe(tgtObt).
            }

            set runmode to 6.
        }

        
        else if runmode = 6 {
            print ("I'm in cleversat:runmode 6") at (2, 50).
            
            exec_hohmann_burn((obtAp + ship:apoapsis) / 2, (obtPe + ship:periapsis) / 2).

            set runmode to 8.
        }

    // Match inclination of final orbit
        else if runmode = 8 {
            
            print ("I'm in cleversat:runmode 8") at (2, 50).

            runPath(matchIncScript, obtInc, obtLAN).

            set runmode to 15.
        }

    // Raise orbit to final parameters
        else if runmode = 15 {
            exec_hohmann_burn(obtAp, obtPe).
            set runmode to 88.
        }

    //Runmode 88MPH - You're going to see some seriously mild shit
        else if runmode = 88 {
            set sVal to lookDirUp(ship:prograde:vector, sun:position) + r(0, 0, _rVal).

            end_main().

            set runmode to 99.
        }

        //Logs the runmode change and writes to disk in case we need to resume the script later
        if runmode <> stateObj["runmode"] {
            set stateObj["runmode"] to runmode.
            log_state(stateObj).
        }
    }
}

local function end_main {
    set sVal to lookDirUp(ship:prograde:vector, sun:position) + r(0, 0, _rVal).
    lock steering to sVal.

    set tVal to 0.
    lock throttle to tVal.

    logStr("Mission completed").
}