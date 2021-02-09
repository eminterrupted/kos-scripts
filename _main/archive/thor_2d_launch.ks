@lazyGlobal off. 

parameter tApo,
          tPe,
          tInc,
          gtAlt,
          gtPitch,
          rVal to 0.

set config:ipu to 250.

clearScreen.
runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/display/lib_display").
runOncePath("0:/lib/lib_core").
runOncePath("0:/lib/lib_launch").
runOncePath("0:/lib/lib_sci").
runOncePath("0:/lib/lib_dmag_sci").
runOncePath("0:/lib/lib_warp").
runOncePath("0:/lib/lib_pid").
runOncePath("0:/lib/lib_engine_data").



runOncePath("0:/lib/nav/lib_nav").
runOncePath("0:/lib/nav/lib_calc_mnv").
runOncePath("0:/lib/lib_mass_data").


//
//** Main
//
//local stateObj to init_state_obj().
local runmode to stateObj["runmode"].

//Vars

local sciList to get_sci_mod_for_parts(ship:parts).
local tPid to setup_q_pid(.125).

local sVal is heading(90, 90, -90).
lock steering to sVal.
local tVal is 0.

until runmode = 99 {

    //Setup
    //pad science
    if runmode = 0 {   
        log_sci_list(sciList).
        recover_sci_list(sciList).
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
        recover_sci_list(sciList).
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
        set sVal to heading(90, get_la_for_alt(gtPitch, gtAlt), rVal).
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
        
        lock steering to heading(get_nav_heading(), get_la_for_alt(0, gtAlt) , rVal).

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
        global burnObj is get_coplanar_burn_data(tApo).
        disp_burn_data(burnObj).
        set runmode to 22.
    }

    //circularization burn
    else if runmode = 22 {
        set burnObj to get_coplanar_burn_data(tApo).
        disp_burn_data(burnObj).
        
        set tVal to 0. 
        set sVal to heading(90, get_la_for_alt(0, tApo), rVal).
        
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
        set burnObj to get_coplanar_burn_data(tApo).
        disp_burn_data(burnObj).

        set tVal to 1.
        set sVal to heading(90, get_la_for_alt(0, tApo), rVal).

        if ship:periapsis >= tPe * 0.90 and ship:periapsis < tPe {
            set tVal to max(0.1, 1 - (ship:apoapsis / tApo)).
        }

        if ship:periapsis >= tApo {
            set tVal to 0. 
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
                recover_sci_list(sciList).
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

    disp_main().
    disp_tel().
    disp_obt_data().
    disp_eng_perf().

    if stateObj["runmode"] <> runmode {
        set stateObj["runmode"] to runmode.
        log_state(stateObj).
    }
}

//** End Main
//
