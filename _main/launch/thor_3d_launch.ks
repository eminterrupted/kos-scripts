@lazyGlobal off. 

parameter tApo is 125000,
          tPe is 125000,
          tInc is 0,
          tGTurnAlt is 60000,
          tGEndPitch to 3.

//set config:ipu to 350.

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
runOncePath("0:/lib/data/ship/lib_mass.ks").
runOncePath("0:/lib/part/lib_fairing.ks").
runOncePath("0:/kslib/library/lib_l_az_calc.ks").


//
//** Main

//Vars
local stateObj to init_state_obj().
local runmode to stateObj["runmode"].

local sVal is heading(90, 90, -90).
local tVal is 0.

local azObj is l_az_calc_init(tApo, tInc).
local az to l_az_calc(azObj).

local dispState is lex().

local lPid is setup_pid(.135).
local apoPid is setup_pid(tApo).
local pePid is setup_pid(tPe).



until runmode = 99 {

    set runmode to stateObj["runmode"].

    //prelaunch activities
    if runmode = 0 {
        arm_pl_fairings().
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
        set sVal to heading(az, get_la_for_alt(tGEndPitch, tGTurnAlt), 0).
        
        if ship:q >= lPid:setpoint {
            set tVal to max(0, min(1, 1 + lPid:update(time:seconds, ship:q))). 
        } 

        else set tVal to 1.

        if ship:apoapsis >= tApo * 0.90 {
            set runmode to 16.
        }
    }

    //slow burn to tApo
    else if runmode = 16 {
        set az to l_az_calc(azObj).
        set sVal to heading(az, get_la_for_alt(tGEndPitch, tGTurnAlt), 0).

        if ship:apoapsis < tApo {
            set tVal to max(0.05, min(1 + apoPid:update(time:seconds, ship:altitude), 0.5)).
        }

        else if ship:apoapsis >= tApo set runmode to 18. 
    }

    //coast / correction burns
    else if runmode = 18 {
        set az to l_az_calc(azObj).
        lock steering to heading(az, get_la_for_alt(0, tGTurnAlt) , 0).

        if ship:apoapsis >= tApo {
            set tVal to 0.
        }
        
        else {
            set tVal to 0.25.
        }

        if ship:altitude >= 70000 {
            set runmode to 22.
        }
    }


    //circularization burn setup
    else if runmode = 22 {
        local burnObj is get_burn_data(tPe).
        if dispState:hasKey("burn_data") disp_burn_data(burnObj).
        else set dispState["burn_data"] to disp_burn_data(burnObj).
        
        set tVal to 0. 

        set az to l_az_calc(azObj).
        set sVal to heading(az, get_la_for_alt(0, tPe), 0).
        
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

    //execute circ burn
    else if runmode = 24 {
        local burnObj is get_burn_data(tPe).
        disp_burn_data(burnObj).
        
        set tVal to 1.
        
        set az to l_az_calc(azObj).
        set sVal to heading(az, get_la_for_alt(0, tPe), 0).

        if ship:periapsis >= tPe * 0.9 {
            set runmode to 26.
        }
    }

    //fine adjust burn to tPe
    else if runmode = 26{
        local burnObj is get_burn_data(tPe).
        disp_burn_data(burnObj).
        
        set az to l_az_calc(azObj).
        set sVal to heading(az, get_la_for_alt(tGEndPitch, tGTurnAlt), 0).

        if ship:apoapsis < tApo {
            set tVal to max(0.05, min(1 + pePid:update(time:seconds, ship:altitude, 1))).
        }

        if ship:periapsis >= tPe {
            set tVal to 0. 
            set runmode to 28.
        }
    }

    else if runmode = 28 {
        set tVal to 0.
        set sVal to ship:prograde.
        set runmode to 99.
    }


    lock steering to sVal.
    lock throttle to tVal.

    if stage:number > 0 and ship:availableThrust <= 0.1 and tVal <> 0 {
        safe_stage().
    }

    disp_launch_main().
    disp_obt_data().
    disp_launch_tel().
    disp_eng_perf_data().
    //disp_launch_params(tApo, tPe, tInc, tGTurnAlt, tGEndPitch).
    
    if stateObj["runmode"] <> runmode {
        set stateObj["runmode"] to runmode.
        log_state().
    }
}

unlock steering. 
lock throttle to 0.

set runmode to 0.
set stateObj["runmode"] to runmode.
log_state().

clearScreen.
//** End Main
//
