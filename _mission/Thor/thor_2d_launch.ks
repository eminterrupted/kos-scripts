@lazyGlobal off. 

set config:ipu to 250.

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
runOncePath("0:/lib/data/vessel/lib_mass.ks").


//
//** Main

//Vars
global sVal is heading(90, 90, -90).
global tVal is 0.

local gravTurnAlt is 60000.
local maxAlt is 0.
local refPitch to 3.
local tApo is 500000.

setup_tpid(.15).
lock steering to sVal.

//Picks up the runmode in the state object. This should be 0 if launching from scratch, but this allows resume mid-flight.
set runmode to stateObj["runmode"].

until runmode = 99 {

    //Setup
    local sciList is get_sci_modules_for_vessel().

    //pad science
    if runmode = 0 {   
        log_sci_list(sciList).
        transmit_sci_list(sciList).
        set runmode to 2.
    }

    //countdown
    else if runmode = 2 {
        set tVal to 1.
        launch_vessel().
        set runmode to 10.
    }

    //launch
    else if runmode = 10 and alt:radar >= 100 {
        set sVal to heading (90, 90, 0).
        log_sci_list(sciList).
        transmit_sci_list(sciList).
        set runmode to 12.
    }

    //vertical ascent
    else if runmode = 12 {
        if ship:altitude >= 1250 or ship:verticalSpeed >= 120 {
            set runmode to 14.
        }
    }

    //gravity turn
    else if runmode = 14 {
        set sVal to heading(90, get_pitch_for_altitude(refPitch, gravTurnAlt), 0).
        if ship:q >= tPid:setpoint * 0.9 {
            set tVal to max(0, min(1, 1 + tPid:update(time:seconds, ship:q))). 
        }
        
        if ship:apoapsis >= tApo * 0.90 {
            set runmode to 16.
        }
    }

    //slow burn to tApo
    else if runmode = 16 {
        if ship:apoapsis < tApo {
            set tVal to max(0.1, 1 - (ship:apoapsis / tApo)).
        }

        else if ship:apoapsis >= tApo {
            set runmode to 18. 
        }
    }

    //coast / correction burns
    else if runmode = 18 {
        
        lock steering to heading(get_nav_heading(), get_pitch_for_altitude(0, gravTurnAlt) , 0).

        if ship:apoapsis >= tApo {
            set tVal to 0.
        }
        
        else {
            set tVal to 0.25.
        }

        if ship:altitude >= 70000 {
            log_sci_list(sciList).
            transmit_sci_list(sciList).
            set runmode to 20.
        }
    }


    else if runmode = 20 {
        global burnObj is get_burn_data(tApo).
        disp_burn_data(burnObj).
        set runmode to 22.
    }

    //circularization burn
    else if runmode = 22 {
        set burnObj to get_burn_data(tApo).
        disp_burn_data(burnObj).
        
        set tVal to 0. 
        set sVal to heading(90, get_pitch_for_altitude(0, tApo), 0).
        
        local burnEta is burnObj["burnEta"] - time:seconds.

        if warp = 0 and burnEta > 30 {
            if steeringManager:angleerror < 0.1 and steeringManager:angleerror > -0.1 {
                if kuniverse:timewarp:mode = "RAILS" warpTo(burnObj["burnEta"] - 15).
            }
        }

        if time:seconds >= burnObj["burnEta"] and ship:periapsis <= tApo and kuniverse:timewarp:issettled {
            set runmode to 24.
        }
    }

    else if runmode = 24 {
        set burnObj to get_burn_data(tApo).
        disp_burn_data(burnObj).

        set tVal to 1.
        set sVal to heading(90, get_pitch_for_altitude(0, tApo), 0).

        if ship:periapsis >= tApo * 0.90 and ship:periapsis < tApo {
            set tVal to max(0.1, 1 - (ship:apoapsis / tApo)).
        }

        if ship:periapsis >= tApo {
            set tVal to 0. 
            clear_sec_data_fields().
            unset burnObj.
            set runmode to 26.
        }
    }

    else if runmode = 26 {
        set tVal to 0.
        set sVal to ship:prograde.
        //safe_stage().
        set runmode to 30.
    }

    //If we can go into high orbit, do science there. Advance when ship begins falling
    else if runmode = 30 {
        set sVal to ship:prograde.
       
        if ship:apoapsis > 250000 {
            if ship:altitude >= 250000 {
                log_sci_list(sciList).
                transmit_sci_list(sciList).
            }
            set runmode to 99. 
        }

        else set runmode to 99. 
    }

    if runmode < 99 {
        lock steering to sVal.
        lock throttle to tVal.
    }

    else {
        lock steering to ship:prograde. 
        lock throttle to 0.
    }

    if stage:number > 0 and ship:availableThrust <= 0.1 and throttle <> 0 and stage:resourceslex:liquidfuel:amount <= 0.01 {
        safe_stage().
    }

    set maxAlt to max(maxAlt, ship:altitude).
    
    disp_main().
    disp_launch_telemetry(maxAlt).
    disp_orbital_data().
    disp_engine_perf_data().

    if stateObj["runmode"] <> runmode {
        set stateObj["runmode"] to runmode.
        log_state().
    }
}

//** End Main
//
