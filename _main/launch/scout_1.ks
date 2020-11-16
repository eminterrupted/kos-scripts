@lazyGlobal off. 

parameter tApo to 125000,
          tPe to 125000,
          tInc to 0,
          tGTurnAlt to 60000,
          tgtPitch to 3.

clearScreen.
runOncePath("0:/lib/lib_init.ks").
runOncePath("0:/lib/lib_display.ks").
runOncePath("0:/lib/lib_launch.ks").
runOncePath("0:/lib/lib_core.ks").
runOncePath("0:/lib/lib_sci.ks").
runOncePath("0:/lib/lib_dmag_sci.ks").
runOncePath("0:/lib/lib_misc_parts.ks").
runOncePath("0:/lib/data/engine/lib_engine.ks").
runOncePath("0:/lib/data/engine/lib_isp.ks").
runOncePath("0:/lib/data/engine/lib_thrust.ks").
runOncePath("0:/lib/data/engine/lib_twr.ks").
runOncePath("0:/lib/data/ship/lib_mass.ks").
runOncePath("0:/kslib/library/lib_l_az_calc.ks").

//
//** Main
local stateObj to init_state_obj().
local runmode to stateObj["runmode"].

//Vars
local azObj to l_az_calc_init(tApo, tInc).
local az to l_az_calc(azObj).
local sVal to heading(90, 90, -90).

//Get a list of science parts

until runmode = 99 {
    
    set runmode to stateObj["runmode"].
    
    //Setup
    local sciList to get_sci_mod().
    for m in get_dmag_mod() sciList:add(m).

    //pad science
    if runmode = 0 {   
        log_sci_list(sciList).
        set runmode to 10.
    }

    //countdown
    else if runmode = 10 {
        launch_vessel().
        set runmode to 20.
    }

    //launch
    else if runmode = 20 {
        when alt:radar >= 250 then {
            log_sci_list(sciList).
            set runmode to 30.
        }
    }

    else if runmode = 30 {
        set sVal to heading(az, get_la_for_alt(tgtPitch, tGTurnAlt), 0).
        when alt:radar >= 18000 then {
            log_sci_list(sciList).
            set runmode to 40.
        }
    }

    else if runmode = 40 {
        set sVal to heading(az, get_la_for_alt(tgtPitch, tGTurnAlt), 0).
        when alt:radar >= 70000 then {
            set sVal to ship:prograde.
            log_sci_list(sciList).
            set runmode to 50.
        }
    }

    else if runmode = 50 {
        when alt:radar >= 250000 then {
            log_sci_list(sciList).
            set runmode to 60.
        }
        
    }
        
    else if runmode = 60 {
        if alt:radar <= 50 set runmode to 99.
    }

    if stage:number > 0 and ship:availableThrust <= 0.1 {
        safe_stage().
    }

    lock steering to sVal.

    disp_launch_main().
    disp_launch_tel().
    disp_obt_data().
    disp_eng_perf_data().
    disp_launch_params(tApo, tPe, tInc, tGTurnAlt, tgtPitch).

    if stateObj["runmode"] <> runmode {
        set stateObj["runmode"] to runmode.
        log_state(stateObj).
    }

    wait 0.001.
}

//** End Main
//
