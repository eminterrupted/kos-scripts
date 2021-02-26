@lazyGlobal off.

parameter _tgtOrbit.

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
runOncePath("0:/lib/lib_mnv").

local runmode to 0.

disp_main().


// Inclination match burn data
local burn to get_inc_match_burn(ship, _tgtOrbit).
local utime to burn[0].
local burnVector to burn[1].
local leadTime to utime - get_burn_dur(burnVector:mag / 2).

//Maneuver node structures
local mnvNode is burn[2].

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

        
        // Vecdraw to show the maneuver
        if runmode = 0 {
            set runmode to 2.
        }

        else if runmode = 2 {

            add mnvNode.

            set runmode to sr(5).
        }

        // Do burn
        else if runmode = 5 {
            
            set sVal to burnVector.
            
            // Wait until we get to the burn
            warpTo(leadTime  - 30). 
            
            until time:seconds >= leadTime - 30 {
                set sVal to burnVector.
                update_display().
                disp_timer(leadTime).
                wait 0.01.
            }

            if warp > 0 kuniverse:timewarp:cancelwarp().

            until time:seconds >= leadTime {
                disp_timer(leadTime).
                set sVal to burnVector.

                update_display().
                wait 0.01.
            }

            disp_clear_block("timer").

            set runmode to sr(6).
        }

        else if runmode = 6 {
            
            //Start the burn.
            set tVal to 1.
            local startVel to ship:velocity:orbit.
            local dvToGo to 9999999.
            until dvToGo <= 0.1 {
                set sVal to burnVector.
                set dvToGo to burnVector:mag - sqrt(abs(vdot(burnVector, (ship:velocity:orbit - startVel)))).
                update_display().
                disp_burn_data().
                wait 0.01.
            }

            set tVal to 0.
            remove mnvNode.
            
            set runmode to sr(10).
        }

        else if runmode = 10 {
            set runmode to sr(99).
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