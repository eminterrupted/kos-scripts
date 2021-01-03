@lazyGlobal off. 

parameter tApo to 125000,
          tPe to 125000,
          tInc to 0,
          tGTurnAlt to 60000,
          rVal to 180.

clearScreen.
runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/display/lib_display").
runOncePath("0:/lib/lib_launch").
runOncePath("0:/lib/lib_core").
runOncePath("0:/lib/lib_sci").
runOncePath("0:/lib/lib_warp").
runOncePath("0:/lib/lib_pid").
runOncePath("0:/lib/lib_misc_parts").
runOncePath("0:/lib/data/engine/lib_engine").
runOncePath("0:/lib/data/engine/lib_isp").
runOncePath("0:/lib/data/engine/lib_thrust").

runOncePath("0:/lib/data/ship/lib_mass").
runOncePath("0:/lib/nav/lib_nav").
runOncePath("0:/lib/nav/lib_calc_mnv").
runOncePath("0:/lib/part/lib_fairing").
runOncePath("0:/lib/part/lib_antenna").
runOncePath("0:/kslib/library/lib_l_az_calc").


//
//** Main

//Vars
//local stateObj to init_state_obj().
local runmode to stateObj["runmode"].

local sVal to heading(90, 90, -90).
local tVal to 0.

local azObj to l_az_calc_init(tApo, tInc).
local az to l_az_calc(azObj).
local burnObj is lex().
local dispState to lex().
local maxQPid to setup_q_pid(.135).

local tGEndPitch to 0.

until runmode = 99 {

    //prelaunch activities
    if runmode = 0 {
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
        set sVal to heading(az, 90, 90).
        set runmode to 12.
    }

    //vertical ascent
    else if runmode = 12 {
        set az to l_az_calc(azObj).
        set sVal to heading(az, 90, rval).

        if ship:altitude >= 1250 or ship:verticalSpeed >= 120 {
            set runmode to 14.
        }
    }

    //gravity turn
    else if runmode = 14 {
        set az to l_az_calc(azObj).
        set sVal to heading(az, get_la_for_alt(tGEndPitch, tGTurnAlt), rval).
        
        if ship:q >= maxQPid:setpoint {
            set tVal to max(0, min(1, 1 + maxQPid:update(time:seconds, ship:q))). 
        }

        else set tVal to 1.

        if ship:apoapsis >= tApo * 0.95 {
            set runmode to 16.
        }
    }

    //slow burn to tApo
    else if runmode = 16 {
        set az to l_az_calc(azObj).
        set sVal to heading(az, get_la_for_alt(tGEndPitch, tGTurnAlt), rVal).

        if ship:apoapsis < tApo {
            set tVal to 1 - max(0, min(1, ((tApo * 0.05)  / (ship:altitude - tApo * 0.95)))).
        }

        else if ship:apoapsis >= tApo set runmode to 18. 
    }

    //coast / correction burns
    else if runmode = 18 {
        set sVal to ship:prograde + r(0,0,180).

        if ship:apoapsis >= tApo {
            set tVal to 0.
        } else {
            set tVal to 0.25.
        }

        if ship:altitude >= 70000 {
            set runmode to 22.
        }
    }

    //circularization burn setup
    else if runmode = 22 {
        set burnObj to get_coplanar_burn_data(tPe).
        if dispState:hasKey("burn_data") disp_burn_data(burnObj).
        else set dispState["burn_data"] to disp_burn_data(burnObj).
        
        set tVal to 0. 

        set az to l_az_calc(azObj).
        set sVal to heading(az, 0, 180).
        
        local burnEta to burnObj["burnEta"] - time:seconds.
        
        if warp = 0 and burnEta > 30 {
            if steeringManager:angleerror < 0.25 and steeringManager:angleerror > -0.25 {
                if kuniverse:timewarp:mode = "RAILS" warpTo(burnObj["burnEta"] - 15).
            }
        }

        if time:seconds >= burnObj["burnEta"] - 3 and ship:periapsis <= tPe {
            kuniverse:timewarp:cancelwarp().
            wait until kuniverse:timewarp:issettled.
            set runmode to 24.
        }
    }

    //execute circ burn
    else if runmode = 24 {
        set az to l_az_calc(azObj).
        set sVal to heading(az, 0, rVal).

        set tVal to 1.
        disp_burn_data(burnObj).

        if ship:periapsis >= tPe * 0.925 {    
            set runmode to 26. 
        }
    }

    //fine adjust burn to tPe
    else if runmode = 26 {
        
        set az to l_az_calc(azObj).
        set sVal to heading(az, 0, rVal).

        disp_burn_data(burnObj).

        if ship:periapsis < tPe {
            set tVal to 1 - max(0, min(1, ((tPe * 0.075)  / (ship:altitude - tPe * 0.925)))).
        } 
        
        else if ship:periapsis >= tPe {
            set tVal to 0. 
            set runmode to 28.
        }
    }

    else if runmode = 28 {
        disp_clear_block("burn_data").
        set tVal to 0.
        set sVal to ship:prograde.
        set runmode to 99.
    }


    lock steering to sVal.
    lock throttle to tVal.

    if stage:number > 0 and ship:availableThrust <= 0.1 and tVal <> 0 {
        safe_stage().
    }

    if not addons:rt:hasKscConnection(ship) activate_omni(ship:partsTaggedPattern("comm.omni")[0]).

    disp_main().
    disp_obt_data().
    disp_tel().
    disp_eng_perf_data().
    //disp_launch_params(tApo, tPe, tInc, tGTurnAlt, tGEndPitch).
    
    if stateObj["runmode"] <> runmode {
        set stateObj["runmode"] to runmode.
        log_state(stateObj).
    }
}

unlock steering. 
lock throttle to 0.

clearScreen.
//** End Main
//
