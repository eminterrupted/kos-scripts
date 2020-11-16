@lazyGlobal off. 

set config:ipu to 150.

clearScreen.
runOncePath("0:/lib/lib_init.ks").
runOncePath("0:/lib/lib_display.ks").
runOncePath("0:/lib/lib_core.ks").
runOncePath("0:/lib/lib_launch.ks").
runOncePath("0:/lib/lib_sci.ks").
runOncePath("0:/lib/lib_warp.ks").
runOncePath("0:/lib/data/engine/lib_engine.ks").
runOncePath("0:/lib/data/engine/lib_isp.ks").
runOncePath("0:/lib/data/engine/lib_thrust.ks").
runOncePath("0:/lib/data/engine/lib_twr.ks").
runOncePath("0:/lib/data/ship/lib_mass.ks").


//
//** Main

//Vars
local stateObj to init_state_obj().
set stateObj["program"] to scriptPath():name:replace(".ks","").
local runmode to stateObj["runmode"].

local sVal to ship:prograde + r(0, 0, 180).
local tPe to 35000.
local tStamp is 0.
local tVal to 0.

if runmode = 99 set runmode to 0. 
lock steering to sVal.

clearscreen.

until runmode = 99 {

    if runmode = 0 {
        
        local sciMod is get_sci_mod().
        log_sci_list(sciMod).
        transmit_sci_list(sciMod).
        set tStamp to time:seconds + 3600.
        set runmode to 10.
    }

    else if runmode = 10 {
        set sVal to ship:prograde + r(0, 0, 180).
        if warp = 0 and time:seconds < tStamp - 30 {
            if steeringManager:angleerror < 0.25 and steeringManager:angleerror > -0.25 {
                if kuniverse:timewarp:mode = "RAILS" warpTo(tStamp - 15).
            }
        }
        if time:seconds >= tStamp set runmode to 20.
    }

    else if runmode = 20 {
        set sval to ship:retrograde + r(0, 0, 180).
        set runmode to 30.
    }

    else if runmode = 30 {
        if steeringManager:angleerror < 0.1 and steeringManager:angleerror > -0.1 {
            set runmode to 40.
        }
    }

    else if runmode = 40 {
        set sval to ship:retrograde + r(0, 0, 180).
        if ship:periapsis > tPe {
            set tVal to 1.
        } else {
            set tVal to 0.
            set runmode to 50.
        }
    }

    else if runmode = 50 {
        set sval to ship:retrograde + r(0, 0, 180).
        local chuteList to ship:partsTaggedPattern("chute"). 
        arm_chutes(chuteList).
        set runmode to 52.
    }

    else if runmode = 52 {
        set sval to ship:retrograde + r(0, 0, 180).
        wait 5. 
        safe_stage().
        set runmode to 60.
    }

    else if runmode = 60 {
        set sval to ship:retrograde + r(0, 0, 180). 
        if ship:altitude <= 10000 {
            unlock steering.
            set runmode to 70.
        }
    }

    else if runmode = 70 {
        if alt:radar < 25 set runmode to 99.
    }
    
    if runmode < 60 {
        lock steering to sVal.
        lock throttle to tVal.
    }
    
    disp_launch_main().
    disp_launch_tel().
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
