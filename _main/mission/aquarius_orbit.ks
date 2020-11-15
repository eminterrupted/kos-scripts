@lazyGlobal off. 

set config:ipu to 150.

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
runOncePath("0:/lib/data/ship/lib_mass.ks").


//
//** Main

//Vars
local stateObj to init_state_obj().
local runmode to stateObj["runmode"].

global sVal to ship:prograde.
lock steering to sVal.

if runmode = 99 set runmode to 0. 

clearscreen.

until runmode = 99 {
    
    set sVal to ship:prograde. 

    disp_launch_main().
    disp_launch_tel().
    disp_obt_data().
    disp_eng_perf_data().

    if stateObj["runmode"] <> runmode {
        set stateObj["runmode"] to runmode.
        log_state().
    }
}

//** End Main
//
