@lazyGlobal off. 

parameter tApo to 125000,
          tPe to 125000,
          tInc to 0,
          gtAlt to 60000,
          gtPitch to 3,
          rVal to 0.

set config:ipu to 250.

clearScreen.
runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/lib_display").
runOncePath("0:/lib/lib_launch").
runOncePath("0:/lib/lib_core").
runOncePath("0:/lib/lib_sci").
runOncePath("0:/lib/lib_warp").
runOncePath("0:/lib/lib_pid").
runOncePath("0:/lib/lib_misc_parts").
runOncePath("0:/lib/lib_engine").



runOncePath("0:/lib/lib_mass_data").
runOncePath("0:/lib/lib_nav").
runOncePath("0:/lib/lib_calc_mnv").
runOncePath("0:/kslib/library/lib_l_az_calc").


//
//** Main

//Vars
//local stateObj to init_state_obj().
local runmode is stateObj["runmode"].

local sVal to heading(90, 90, 270).
local tVal to 0.

local azObj to l_az_calc_init(tApo, tInc).
local az to l_az_calc(azObj).
local sciList to get_sci_mod_for_parts(ship:parts).
local tPid to setup_q_pid(.15).

until runmode = 99 {

    set runmode to stateObj["runmode"].

    //prelaunch activities
    if runmode = 0 {
        log_sci_list(sciList).
        recover_sci_list(sciList).
        arm_proc_fairings(80000).

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
        recover_sci_list(sciList).
        
        set runmode to 12.
    }

    //vertical ascent
    else if runmode = 12 {
        set az to l_az_calc(azObj).
        set sVal to heading (az, 90, rVal).

        if ship:altitude >= 1250 or ship:verticalSpeed >= 120 {
            set runmode to 14.
        }
    }

    //gravity turn
    else if runmode = 14 {
        set az to l_az_calc(azObj).
        set sVal to heading(az, get_la_for_alt(gtPitch, gtAlt), rVal).
        
        if ship:q >= tPid:setpoint {
            set tVal to max(0, min(1, 1 + tPid:update(time:seconds, ship:q))). 
        } 

        else set tVal to 1.

        if ship:apoapsis >= tApo * 0.90 {
            global cPid to pidLoop(0.05, 0.02, 0.01, 0, 1).
            set cPid:setpoint to tApo.
            set runmode to 16.
        }
    }

    //slow burn to tApo
    else if runmode = 16 {
        set az to l_az_calc(azObj).
        set sVal to heading(az, get_la_for_alt(gtPitch, gtAlt), rVal).

        if ship:apoapsis < tApo {
            set tVal to max(0.05, 1 + cPid:update(time:seconds, ship:altitude)).
        }

        else if ship:apoapsis >= tApo set runmode to 18. 
    }

    //coast / correction burns
    else if runmode = 18 {
        set az to l_az_calc(azObj).
        lock steering to heading(az, get_la_for_alt(0, gtAlt) , rVal).

        if ship:apoapsis >= tApo {
            set tVal to 0.
        }
        
        else {
            set tVal to 0.25.
        }

        if ship:altitude >= 70000 {
            log_sci_list(sciList).
            recover_sci_list(sciList).
            set runmode to 20.
        }
    }

    else if runmode = 20 {
        global burnObj to get_coplanar_burn_data(tPe).
        disp_burn_data(burnObj).
        set runmode to 22.
    }

    //circularization burn
    else if runmode = 22 {
        disp_burn_data(burnObj).
        
        set tVal to 0. 

        set az to l_az_calc(azObj).
        set sVal to heading(az, get_la_for_alt(0, tPe), 0).
        
        local burnEta to burnObj["burnEta"] - time:seconds.

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
        set sVal to heading(az, get_la_for_alt(0, tPe), 0).

        if ship:periapsis >= tPe * 0.90 and ship:periapsis < tPe {
            set tVal to max(0.1, 1 - (ship:apoapsis / tPe)).
        }

        if ship:periapsis >= tPe {
            set tVal to 0. 
            disp_clear_block("burn_data").
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
                recover_sci_list(sciList).
            }
            set runmode to 32. 
        }

        else set runmode to 32. 
    }

    else if runmode = 32 {
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

    disp_main().
    disp_tel().
    disp_obt_data().
    disp_eng_perf().
    
    if stateObj["runmode"] <> runmode {
        set stateObj["runmode"] to runmode.
        log_state(stateObj).
    }
}

unlock steering. 
lock throttle to 0.

disp_clear_block("c").
disp_clear_block("d").
disp_clear_block("e").


set runmode to 0.
set stateObj["runmode"] to runmode.
log_state(stateObj).

//** End Main
//
