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
runOncePath("0:/lib/data/vessel/lib_mass.ks").


//
//** Main

//Vars
if not (defined runmode) global runmode is 0. 
if not (defined program) global program is 0.

local maxAlt is 0.
local n is 0.
local pList is ship:partsTaggedPattern("dish").

if runmode = 99 set runmode to 0.

lock steering to ship:prograde.

for p in pList {
    
    set runmode to stateObj["runmode"].
    set program to stateObj["program"].

    local dishData is get_antenna_fields(p).
    set runmode to 10.

    if n = 0 {
        set_dish_target(p, "CommSat 4").
        set runmode to 20.
    } else if n = 1 {
        set_dish_target(p, "CommSat 2").
        set runmode to 20.
    }
    
    activate_antenna(p).
    set n to n + 1.
    set runmode to 99.

    disp_main().
    disp_launch_telemetry(maxAlt).
    disp_orbital_data().

    if stateObj["runmode"] <> runmode {
        set stateObj["runmode"] to runmode.
        log_state().
    }
}

wait 5.