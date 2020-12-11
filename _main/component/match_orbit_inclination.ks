@lazyGlobal off.

parameter _tgtOrbit.

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

wait 1.


// Inclination match burn data
local burn to get_inc_match_burn(ship, _tgtOrbit).
local utime to burn[0].
local burnVector to burn[1].
local dur to get_burn_dur(burnVector:mag).
local leadTime to utime - get_burn_dur(burnVector:mag / 2).

//Vec draw vars
local burnDone to false.
local burnVDTail to 0.
local burnVD to 0.

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

            set burnVDTail to positionAt(ship, utime).
            set burnVD to 
                vecDraw(
                    burnVDTail,
                    500 * burnVector,
                    magenta,
                    "dV:" + round(burnVector:mag, 1) + " m/s, dur:" + round(dur, 1) + "s",
                    1,
                    true).

            // Keep the draw updating the start position until the burn is done.
            set burnVD:startUpdater to { return positionAt(ship, utime). }.
            set runmode to 2.
        }

        else if runmode = 2 {

            add mnvNode.

            set runmode to 5.
        }

        // Do burn
        else if runmode = 5 {
            
            set sVal to burnVector.
            
            print "Burn Data" at (2, 42).
            print "---------" at (2, 43).
            
            // Wait until we get to the burn
            until time:seconds >= leadTime  - 30 {
                if warp = 0 set warp to 3.

                print "Burn starting in " + round(leadTime - time:seconds) + "s     " at (2, 44).
                set sVal to burnVector.

                update_display().
                wait 0.01.
            }

            if warp > 0 kuniverse:timewarp:cancelwarp().

            until time:seconds >= leadTime {
                print "Burn starting in " + round(leadTime - time:seconds) + "s     " at (2, 44).
                set sVal to burnVector.

                update_display().
                wait 0.01.

            }

            //Start the burn.
            set tVal to 1.
            local startVel to ship:velocity:orbit.
            local dvToGo to 9999999.
            until dvToGo <= 0.1 {
                set sVal to burnVector.
                set dvToGo to burnVector:mag - sqrt(abs(vdot(burnVector, (ship:velocity:orbit - startVel)))).
                //if dvToGo < 10 { set tVal to max(0, min(1, dvToGo / 10)). } 
                print "Burn dV remaining: " + round(dvToGo, 2) + " m/s      " at (2, 44).

                update_display().
                wait 0.01.
            }

            set tVal to 0.
            print "Burn completed                                " at (2, 44).
            wait 1.
            print "                            " at (2, 42).
            print "                            " at (2, 43).
            print "                            " at (2, 44).
            remove mnvNode.
            
            set runmode to 10.
        }

        else if runmode = 10 {
            
            set burnDone to true.
            set burnVD to 0.

            set runmode to 99.
        }

        update_display().

        //Logs the runmode change and writes to disk in case we need to resume the script later
        set stateObj["runmode"] to runmode.
        log_state(stateObj).
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