@lazyGlobal off. 

parameter tApo to 125000,
          tPe to 125000,
          tInc to 0,
          tGTurnAlt to 60000,
          tGEndPitch to 3,
          rVal to 0.

clearScreen.
runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/lib_log").
runOncePath("0:/lib/display/lib_display").
runOncePath("0:/lib/lib_launch").
runOncePath("0:/lib/lib_core").
runOncePath("0:/lib/lib_sci").
runOncePath("0:/lib/lib_warp").
runOncePath("0:/lib/lib_pid").
runOncePath("0:/lib/lib_misc_parts").
runOncePath("0:/lib/lib_engine_data").



runOncePath("0:/lib/nav/lib_nav").
runOncePath("0:/lib/nav/lib_calc_mnv").
runOncePath("0:/lib/lib_mass_data").
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
local gtStart is 1250.

local azObj to l_az_calc_init(tApo, tInc).
local burnObj is lex().
local dispState to lex().
local acc is ship:maxThrust / ship:mass.
local maxAcc is 35.
local maxQ is 0.10.
local qPid to setup_q_pid(maxQ).
local accPid to setup_acc_pid(maxAcc).

until runmode = 99 {

    //prelaunch activities
    if runmode = 0 {
        set runmode to 2.
        logStr("Preparing for launch").
    }

    //countdown
    else if runmode = 2 {
        if ship:partsTaggedPattern("pl.st.fairing"):length > 0 {
            arm_stock_fairings(75000, ship:partsTaggedPattern("pl.st.fairing")[0]).
        } 
        else if ship:partsTaggedPattern("pl.pf.base"):length > 0 {
            arm_proc_fairings(75000, ship:partsTaggedPattern("pl.pf.base")[0]).
        }

        launch_vessel(30).
        set tVal to 1.
        lock throttle to tVal.
        set runmode to 3.
    }

    else if runmode = 3 {
        set tVal to 1.
        if alt:radar >= 100 {
            logStr("Tower cleared").
            set runmode to 4.
        }
    }

    else if runmode = 4 {
        set tVal to 1.
        if alt:radar >= 250 {
            logStr("Roll program").
            set runmode to 10.
        }
    }

    else if runmode = 10 {
        set tVal to 1.
        set sVal to heading(l_az_calc(azObj), 90, 90).
        set runmode to 12.
    }

    //vertical ascent
    else if runmode = 12 {
        set tVal to 1.
        set sVal to heading(l_az_calc(azObj), 90, rVal).

        if ship:altitude >= 900 or ship:verticalSpeed >= 100 {
            logStr("Pitch program").
            set gtStart to ship:altitude.
            when ship:q >= .125 then logStr("Approaching Max-Q").
            when acc >= 30 then logStr("Throttling back at maximum acceleration").
            set runmode to 14.
        }
    }

    //gravity turn
    else if runmode = 14 {
        set sVal to heading(l_az_calc(azObj), get_la_for_alt(tGEndPitch, tGTurnAlt, gtStart), rVal).
        set acc to ship:maxThrust / ship:mass.

        if ship:q >= maxQ {
            set tVal to max(0, min(1, 1 + qPid:update(time:seconds, ship:q))). 
        }

        else if acc >= maxAcc - 5 {
            set tVal to max(0, min(1, 1 + accPid:update(time:seconds, acc))).
        }

        else {
            set tVal to 1.
        }

        if ship:apoapsis >= tApo * 0.925 {
            logStr("Throttling back near apoapsis. [CurAlt:" + round(ship:altitude) + "][Apo:" + round(ship:apoapsis) + "]").
            set runmode to 16.
        }
    }

    //slow burn to tApo
    else if runmode = 16 {
        set sVal to heading(l_az_calc(azObj), get_la_for_alt(tGEndPitch, tGTurnAlt, gtStart), rVal).

        if ship:apoapsis < tApo {
            set tval to 1 - max(0, min(1, (ship:apoapsis * 0.075 / tApo * 0.075 ))).
        }

        else if ship:apoapsis >= tApo {
            set tVal to 0.
            logStr("MECO").
            set runmode to 18. 
        }
    }

    //coast / correction burns
    else if runmode = 18 {
        set sVal to ship:prograde + r(0, 0, rVal).

        if ship:apoapsis >= tApo {
            set tVal to 0.
        } else {
            set tVal to 0.25.
        }

        if ship:altitude >= body:atm:height {
            logStr("Reached space").
            logStr("Setting up circularization burn object").
            set runmode to 22.
        }
    }


    //circularization burn setup
    else if runmode = 22 {
        set tVal to 0. 
        set sVal to heading(l_az_calc(azObj), get_circ_burn_pitch(), rVal).

        set burnObj to get_coplanar_burn_data(tPe).
        if dispState:hasKey("burn_data") disp_burn_data(burnObj).
        else set dispState["burn_data"] to disp_burn_data(burnObj).

        set runmode to 23.
    }

    else if runmode = 23 {
        set sVal to ship:prograde + r(0, 0, rVal).

        local burnEta to burnObj["burnEta"] - time:seconds.
        if warp = 0 and burnEta > 30 {
            if steeringManager:angleerror < 0.25 and steeringManager:angleerror > -0.25 {
                if kuniverse:timewarp:mode = "RAILS" warpTo(burnObj["burnEta"] - 30).
            }
        }

        if time:seconds >= burnObj["burnEta"] - 5 and ship:periapsis <= tPe and kuniverse:timewarp:issettled {
            logStr("Circularization burn initiated").
            set runmode to 24.
        }
    }

    //execute circ burn
    else if runmode = 24 {
        set sVal to heading(l_az_calc(azObj), get_circ_burn_pitch(), rVal).

        set tVal to 1.
        disp_burn_data(burnObj).

        if ship:periapsis >= tPe * 0.925 {
            logStr("Throttling back at Pe target approach [CurAlt:" + round(ship:altitude) + "][Pe:" + round(ship:periapsis) + "]").
            set runmode to 26. 
        }
    }

    //fine adjust burn to tPe
    else if runmode = 26 {
        set sVal to heading(l_az_calc(azObj), 0, rVal).

        disp_burn_data(burnObj).

        if ship:periapsis < tPe {
            set tVal to 1 - max(0, min(1, (ship:periapsis * 0.075 / tPe * 0.075))).
        } 
        
        else if ship:periapsis >= tPe {
            set tVal to 0. 
            logStr("SECO").
            logStr("Circularized at [Apo: " + round(ship:apoapsis) + "][Pe: " + round(ship:periapsis) + "]").
            set runmode to 28.
        }
    }

    //Clear disp block, get ship ready for orbit
    else if runmode = 28 {
        disp_clear_block("burn_data").
        set tVal to 0.
        set sVal to ship:prograde.
        set runmode to 30.
    }

    //deploy any solar panels
    else if runmode = 30 {
        panels on.
        logStr("Panels on").
        set runmode to 99.
    }

    lock steering to sVal.
    lock throttle to tVal.

    if ship:availableThrust < 0.1 and tVal > 0 {
        safe_stage().
    }

    if not addons:rt:hasKscConnection(ship) activate_omni(ship:partsTaggedPattern("comm.omni")[0]).

    disp_main().
    disp_obt_data().
    disp_tel().
    disp_eng_perf().
    //disp_launch_params(tApo, tPe, tInc, tGTurnAlt, tGEndPitch).
    
    if stateObj["runmode"] <> runmode {
        set stateObj["runmode"] to runmode.
        log_state(stateObj).
    }
}

unlock steering. 
unlock throttle.

from { local n is 10.} until n <= 0 step { set n to n - 1.} do {
    disp_timer(n).
}

disp_clear_block("timer").
logStr("Ship ready for mission script").
clearScreen.
//** End Main
//
