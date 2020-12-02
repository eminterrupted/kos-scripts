@lazyGlobal off. 

parameter rVal is 0.

clearScreen.
runOncePath("0:/lib/lib_init.ks").
runOncePath("0:/lib/lib_core.ks").
runOncePath("0:/lib/lib_display.ks").
runOncePath("0:/lib/lib_dmag_sci.ks").
runOncePath("0:/lib/lib_launch.ks").
runOncePath("0:/lib/lib_sci.ks").
runOncePath("0:/lib/lib_warp.ks").
runOncePath("0:/lib/data/engine/lib_engine.ks").
runOncePath("0:/lib/data/engine/lib_isp.ks").
runOncePath("0:/lib/data/engine/lib_thrust.ks").
runOncePath("0:/lib/data/engine/lib_twr.ks").
runOncePath("0:/lib/data/ship/lib_mass.ks").
runOncePath("0:/lib/part/lib_heatshield.ks").


//
//** Main

//Vars
//local stateObj to init_state_obj().
local runmode to stateObj["runmode"].

local sVal to ship:prograde.
local tPe to 35000.
local tStamp is 0.
local tVal to 0.

if runmode = 99 set runmode to 0. 
lock steering to sVal.
lock throttle to tVal.

clearscreen.

until runmode = 99 {

    if runmode = 0 {
        set sVal to ship:prograde + r(0, 0, rval). 
        wait 2.
        bays on.
        set runmode to 2.
    }

    else if runmode = 2 {
        set sVal to ship:prograde + r(0, 0, rval). 
        local sciMod is get_sci_mod().
        deploy_sci_list(sciMod).
        wait 1.
        log_sci_list(sciMod).
        wait 1.
        recover_sci_list(sciMod).
        set runmode to 4.
    }

    else if runmode = 4 {
        set sVal to ship:prograde + r(0, 0, rval). 
        local dmagMod is get_dmag_mod().
        log_dmag_list(dmagMod).
        wait 1.
        recover_sci_list(dmagMod).
        set tStamp to time:seconds + 600.
        set runmode to 10.
    }

    else if runmode = 10 {
        set sVal to ship:prograde + r(0, 0, rval). 
        if warp = 0 {
            if steeringManager:angleerror < 0.1 and steeringManager:angleerror > -0.1 {
                if kuniverse:timewarp:mode <> "RAILS" set kuniverse:timewarp:mode to "RAILS".
                warpTo(tStamp - 15).
            }
        }

        if time:seconds >= tStamp {
            kuniverse:timewarp:cancelwarp().
            set runmode to 20.
        }
    }

    else if runmode = 20 {
        set sVal to ship:retrograde + r(0, 0, rval). 
        if ship:longitude >= 135 and ship:longitude <= 145 {
            kuniverse:timewarp:cancelwarp().
            wait until kuniverse:timewarp:issettled.
            set runmode to 40.
        }

        else set warp to 3.
    }

    else if runmode = 30 {
        set sVal to ship:retrograde + r(0, 0, rval). 
        if steeringManager:angleerror < 0.1 and steeringManager:angleerror > -0.1 {
            wait 3.
            set runmode to 40.
        }
    }

    else if runmode = 40 {
        set sVal to ship:retrograde + r(0, 0, rval). 
        if ship:periapsis > tPe {
            set tVal to 1.
        } else {
            set tVal to 0.
            set runmode to 50.
        }
    }

    else if runmode = 50 {
        set sVal to ship:retrograde + r(0, 0, rval). 
        local chuteList to ship:partsTaggedPattern("chute"). 
        arm_chutes(chuteList).
        set runmode to 52.
    }

    else if runmode = 52 {
        set sVal to ship:retrograde + r(0, 0, rval). 
        wait 5.
        set runmode to 60.
    }

    //warp to atmosphere interface
    else if runmode = 60 {
        set sVal to ship:retrograde + r(0, 0, rval). 
        local warpAlt is body:atm:height + 5000.
        set sVal to "kill". 
        wait 1.

        warp_to_alt(warpAlt).
        if ship:altitude <= warpAlt {
            kuniverse:timewarp:cancelWarp().
            set runmode to 62.
        }
    }
        
    else if runmode = 62 {
        set sVal to ship:retrograde + r(0, 0, rval). 
        wait 1.
        safe_stage().
        set runmode to 70.
    }

    else if runmode = 70 {
        set sVal to ship:retrograde + r(0, 0, rval). 
        if ship:altitude <= 12500 {
            set runmode to 71.
        }
    }

    else if runmode = 71 {
        unlock steering.
        unlock throttle.
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
