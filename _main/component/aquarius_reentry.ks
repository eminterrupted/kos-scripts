@lazyGlobal off. 

parameter rVal is 180.

clearScreen.
runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/display/lib_display").
runOncePath("0:/lib/lib_core").
runOncePath("0:/lib/lib_launch").
runOncePath("0:/lib/lib_sci").
runOncePath("0:/lib/lib_warp").
runOncePath("0:/lib/data/engine/lib_engine").
runOncePath("0:/lib/data/engine/lib_isp").
runOncePath("0:/lib/data/engine/lib_thrust").

runOncePath("0:/lib/data/ship/lib_mass").
runOncePath("0:/lib/part/lib_heatshield").
runOncePath("0:/lib/part/lib_chute").

//
//** Main

//Vars
//local stateObj to init_state_obj().
local runmode to stateObj["runmode"].

local sVal to ship:prograde + r(0, 0, rVal).
local tPe to 35000.
local tVal to 0.

if runmode = 99 set runmode to 0. 
lock steering to sVal.
lock throttle to tVal.

clearscreen.

until runmode = 99 {

    if runmode = 0 {
        set sVal to ship:retrograde + r(0, 0, rVal).
        if ship:longitude >= 125 and ship:longitude <= 135 {
            kuniverse:timewarp:cancelwarp().
            wait until kuniverse:timewarp:issettled.
            set runmode to 40.
        } else {
            if steeringManager:angleerror < 0.25 and steeringManager:angleerror > -0.25 set warp to 3.
        }
    }

    else if runmode = 40 {
        set sval to ship:retrograde + r(0, 0, rVal).
        wait 2.
        if steeringManager:angleerror < 0.25 and steeringManager:angleerror > -0.25 {
            if ship:periapsis > tPe {
                set tVal to 1.
            } else {
                set tVal to 0.
                set runmode to 50.
            }
        }
    }

    else if runmode = 50 {
        set sval to ship:retrograde + r(0, 0, rVal).
        local chuteList to ship:partsTaggedPattern("chute"). 
        arm_chutes(chuteList).
        set runmode to 52.
    }

    else if runmode = 52 {
        set sval to ship:retrograde + r(0, 0, rVal).
        wait 5. 
        set runmode to 60.
    }

    //warp to atmosphere interface
    else if runmode = 60 {
        set sval to ship:retrograde + r(0, 0, rVal).
        local warpAlt is body:atm:height + 5000.
        warp_to_alt(warpAlt).
        if ship:altitude <= warpAlt {
            kuniverse:timewarp:cancelWarp().
            when kuniverse:timewarp:issettled then {
                safe_stage().
                set runmode to 70.
            }
        }
    }
        
    else if runmode = 70 {
        set sval to ship:retrograde + r(0, 0, rVal). 
        if ship:altitude <= 12500 {
            set runmode to 71.
        }
    }

    else if runmode = 71 {
        unlock steering.
        set runmode to 72.
    }

    else if runmode = 72 {
        if alt:radar <= 500 and ship:verticalSpeed <= 75 {
            jettison_heatshield(ship:partsTaggedPattern("heatshield")[0]).
            set runmode to 80.
        }
    }

    else if runmode = 80 {
        if alt:radar < 25 set runmode to 99.
    }

    if runmode < 71 {
        lock steering to sVal.
        lock throttle to tVal.
    }
    
    disp_main().
    disp_tel().
    disp_obt_data().

    if stateObj["runmode"] <> runmode {
        set stateObj["runmode"] to runmode.
        log_state(stateObj).
    }
}

clearScreen.

print "Welcome back to Kerbin!" at (2, 4).
wait 10. 

//** End Main
//
