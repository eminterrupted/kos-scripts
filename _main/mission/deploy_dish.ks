@lazyGlobal off.

runOncePath("0:/lib/part/lib_antenna.ks").
runOncePath("0:/lib/part/lib_dish.ks").

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


//
//** Main

//Vars
local stateObj to init_state_obj().
local runmode to stateObj["runmode"].
local n to 0.
local pList to ship:partsTaggedPattern("dish").

if runmode = 99 set runmode to 0.

lock steering to ship:prograde.

for p in pList {
    
    set runmode to stateObj["runmode"].

    set runmode to 10.

    if n = 0 {
        set_dish_target(p, "CommSat 4").
        set runmode to 20.
    } else if n = 1 {
        set_dish_target(p, "CommSat 2").
        set runmode to 20.
    }
    
    activate_dish(p).
    set n to n + 1.
    set runmode to 99.
    disp_launch_main().
    disp_launch_tel().
    disp_obt_data().

    if stateObj["runmode"] <> runmode {
        set stateObj["runmode"] to runmode.
        log_state(stateObj).
    }
}

wait 5.