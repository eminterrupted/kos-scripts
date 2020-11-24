@lazyGlobal off. 

parameter tApo to 125000,
          tPe to 125000,
          tInc to 0,
          tGTurnAlt to 60000,
          tGEndPitch to 3,
          rVal to 0.

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
runOncePath("0:/lib/part/lib_antenna.ks").
runOncePath("0:/kslib/library/lib_l_az_calc.ks").


//
//** Main

//Vars
local stateObj to init_state_obj().
local runmode to stateObj["runmode"].

local sVal to heading(90, 90, -90).
local tVal to 0.
local gtStart is 1250.

local azObj to l_az_calc_init(tApo, tInc).
local burnObj is lex().
local dispState to lex().
local ascPid to setup_pid(.135).
local maxQ is false.

until runmode = 99 {

    //prelaunch activities
    if runmode = 0 {
        set runmode to 2.
        logStr("[R:" + runmode + "] Preparing for launch").
    }

    //countdown
    else if runmode = 2 {
        if ship:partsTaggedPattern("pl.st.fairing"):length > 0 {
            arm_stock_fairings(75000, ship:partsTaggedPattern("pl.st.fairing")[0]).
        } 
        else if ship:partsTaggedPattern("pl.pf.base"):length > 0 {
            arm_proc_fairings(75000, ship:partsTaggedPattern("pl.pf.base")[0]).
        }

        launch_vessel().
        set tVal to 1.
        lock throttle to tVal.
        set runmode to 3.
    }

    else if runmode = 3 {
        set tVal to 1.
        if alt:radar >= 100 {
            hudtext("Tower cleared", 3, 1, 18, purple, false).
            set runmode to 4.
        }
    }

    else if runmode = 4 {
        set tVal to 1.
        if alt:radar >= 250 {
            hudtext("Roll program", 3, 1, 18, purple, false).
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
            hudtext("Pitch program", 3, 1, 18, purple, false).
            set gtStart to ship:altitude.
            set runmode to 14.
        }
    }

    //gravity turn
    else if runmode = 14 {
        set tVal to 1.
        set sVal to heading(l_az_calc(azObj), get_la_for_alt(tGEndPitch, tGTurnAlt, gtStart), rVal).
        
        if ship:q >= ascPid:setpoint {
            if not maxQ hudtext("Throttle down for Max-Q", 3, 1, 18, purple, false).
            set maxQ to true.
            set tVal to max(0, min(1, 1 + ascPid:update(time:seconds, ship:q))). 
        }

        else {
            if maxQ hudtext("Throttle up to 100%", 3, 1, 18, purple, false).
            set maxQ to false. 
            set tVal to 1.
        }

        if ship:apoapsis >= tApo * 0.875 {
            hudtext("Throttling down to tApo", 3, 1, 18, purple, false).
            set runmode to 16.
        }
    }

    //slow burn to tApo
    else if runmode = 16 {
        set sVal to heading(l_az_calc(azObj), get_la_for_alt(tGEndPitch, tGTurnAlt, gtStart), rVal).

        if ship:apoapsis < tApo {
            set tVal to 1 - max(0, min(1, ((tApo * 0.125)  / (ship:altitude - tApo * 0.875)))).
        }

        else if ship:apoapsis >= tApo or stage:number < 0 or ship:obt:hasnextpatch {
            set tVal to 0.
            set runmode to 18. 
            hudtext("MECO", 3, 1, 18, purple, false).
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
            set runmode to 22.
        }
    }


    //Set ship to prograde for coast to sun orbit
    else if runmode = 22 {
        set tVal to 0. 
        set sVal to ship:prograde + r(0, 0, rVal).

        set runmode to 24.
    }
        
    //deploy any solar panels
    else if runmode = 24 {
        panels on.
        set runmode to 99.
    }

    lock steering to sVal.
    lock throttle to tVal.

    if ship:availableThrust < 0.1 and tVal > 0 {
        hudtext("Staging", 3, 1, 18, purple, false).
        safe_stage().
    }

    if not addons:rt:hasKscConnection(ship) activate_omni(ship:partsTaggedPattern("comm.omni")[0]).

    disp_launch_main().
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
unlock throttle.

wait 1.

clearScreen.
//** End Main
//
