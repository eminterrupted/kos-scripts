@lazyGlobal off. 

parameter tApo is 125000,
          tPe is 125000,
          tInc is 0,
          gravTurnAlt is 60000,
          refPitch to 3.

set config:ipu to 250.

clearScreen.
runOncePath("0:/lib/lib_init.ks").
runOncePath("0:/lib/lib_display.ks").
runOncePath("0:/lib/lib_launch.ks").
runOncePath("0:/lib/lib_core.ks").
runOncePath("0:/lib/lib_sci.ks").
runOncePath("0:/lib/lib_warp.ks").
runOncePath("0:/lib/lib_pid.ks").
runOncePath("0:/lib/lib_misc_parts.ks").
runOncePath("0:/lib/data/engine/lib_engine.ks").
runOncePath("0:/lib/data/engine/lib_isp.ks").
runOncePath("0:/lib/data/engine/lib_thrust.ks").
runOncePath("0:/lib/data/engine/lib_twr.ks").
runOncePath("0:/lib/data/vessel/lib_mass.ks").
runOncePath("0:/kslib/library/lib_l_az_calc.ks").


//
//** Main

//Vars
if not (defined runmode) global runmode is 0.
if not (defined program) global program is 0.

local azObj is l_az_calc_init(tApo, tInc).
local az to l_az_calc(azObj).
global sVal is heading(90, 90, 270).
global tVal is 0.
local maxAlt is 0.

setup_tpid(.15).
lock steering to sVal.

until runmode = 99 {

    set runmode to stateObj["runmode"].
    set program to stateObj["program"].

    //Setup
    local sciList is get_sci_modules_for_vessel().

    //prelaunch activities
    if runmode = 0 {
        log_sci_list(sciList).
        transmit_sci_list(sciList).
        arm_fairings_on_launch(80000).

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
        set az to l_az_calc(azObj).
        set sVal to heading (az, 90, 0).
        
        log_sci_list(sciList).
        transmit_sci_list(sciList).
        
        set runmode to 12.
    }

    //vertical ascent
    else if runmode = 12 {
        set az to l_az_calc(azObj).
        set sVal to heading (az, 90, 0).

        if ship:altitude >= 1250 or ship:verticalSpeed >= 120 {
            set runmode to 14.
        }
    }

    //gravity turn
    else if runmode = 14 {
        set az to l_az_calc(azObj).
        set sVal to heading(az, get_pitch_for_altitude(refPitch, gravTurnAlt), 0).
        
        if ship:q >= tPid:setpoint {
            set tVal to max(0, min(1, 1 + tPid:update(time:seconds, ship:q))). 
        } 

        else set tVal to 1.

        if ship:apoapsis >= tApo * 0.90 {
            global cPid is pidLoop(0.05, 0.02, 0.01, 0, 1).
            set cPid:setpoint to tApo.
            set runmode to 16.
        }
    }

    //slow burn to tApo
    else if runmode = 16 {
        set az to l_az_calc(azObj).
        set sVal to heading(az, get_pitch_for_altitude(refPitch, gravTurnAlt), 0).

        if ship:apoapsis < tApo {
            set tVal to max(0.05, 1 + cPid:update(time:seconds, ship:altitude)).
        }

        else if ship:apoapsis >= tApo set runmode to 18. 
    }

    //coast / correction burns
    else if runmode = 18 {
        set az to l_az_calc(azObj).
        lock steering to heading(az, get_pitch_for_altitude(0, gravTurnAlt) , 0).

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
        global burnObj is get_burn_data(tPe).
        disp_burn_data(burnObj).
        set runmode to 22.
    }

    //circularization burn
    else if runmode = 22 {
        disp_burn_data(burnObj).
        
        set tVal to 0. 

        set az to l_az_calc(azObj).
        set sVal to heading(az, get_pitch_for_altitude(0, tPe), 0).
        
        local burnEta is burnObj["burnEta"] - time:seconds.

        if warp = 0 and burnEta > 30 {
            if steeringManager:angleerror < 0.1 and steeringManager:angleerror > -0.1 {
                if kuniverse:timewarp:mode = "RAILS" warpTo(burnObj["burnEta"] - 15).
            }
        }

        if time:seconds >= burnObj["burnEta"] and ship:periapsis <= tPe and kuniverse:timewarp:issettled {
            set runmode to 24.
        }
    }

    else if runmode = 24 {
        disp_burn_data(burnObj).

        set tVal to 1.
        
        set az to l_az_calc(azObj).
        set sVal to heading(az, get_pitch_for_altitude(0, tPe), 0).

        if ship:periapsis >= tPe * 0.90 and ship:periapsis < tPe {
            set tVal to max(0.1, 1 - (ship:apoapsis / tPe)).
        }

        if ship:periapsis >= tPe {
            set tVal to 0. 
            clear_sec_data_fields().
            set runmode to 26.
        }
    }

    else if runmode = 26 {
        set tVal to 0.
        set sVal to ship:prograde.
        //safe_stage().
        set runmode to 30.
    }

    //If we can go into high orbit, do science there. 
    else if runmode = 30 {
        set sVal to ship:prograde.
        if ship:apoapsis > 250000 {
            if ship:altitude >= 250000 {
                log_sci_list(sciList).
                transmit_sci_list(sciList).
            }
            set runmode to 32. 
        }

        else set runmode to 32. 
    }

    else if runmode = 32 {
        clear_sec_data_fields().
        set runmode to 50.
    }

    else if runmode = 50 {
        lock steering to ship:prograde.
        wait 10.
        set runmode to 99.
    }

    lock steering to sVal.
    lock throttle to tVal.

    if stage:number > 0 and ship:availableThrust <= 0.1 and tVal <> 0 {
        safe_stage().
    }

    set maxAlt to max(maxAlt, ship:altitude).

    disp_launch_main().
    disp_launch_telemetry(maxAlt).
    disp_orbital_data().
    disp_engine_perf_data().
    disp_launch_params(tApo, tPe, tInc, gravTurnAlt, refPitch).
    
    if stateObj["runmode"] <> runmode {
        set stateObj["runmode"] to runmode.
        log_state().
    }
}

unlock steering. 
lock throttle to 0.

clear_disp_block("c").
clear_disp_block("d").
clear_disp_block("e").


set runmode to 0.
set stateObj["runmode"] to runmode.
log_state().

//** End Main
//
