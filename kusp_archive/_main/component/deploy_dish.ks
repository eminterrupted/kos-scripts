@lazyGlobal off.

parameter rVal is 0.

clearScreen.

runOncePath("0:/lib/lib_antenna").
runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/lib_display").
runOncePath("0:/lib/lib_launch").
runOncePath("0:/lib/lib_core").
runOncePath("0:/lib/lib_sci").
runOncePath("0:/lib/lib_warp").
runOncePath("0:/lib/lib_misc_parts").
runOncePath("0:/lib/lib_engine").



runOncePath("0:/lib/lib_mass_data").
if ship:partsTaggedPattern("rcs"):length > 0 runOncePath("0:/lib/lib_rcs").

//
//** Main

//Vars
//local stateObj to init_state_obj().
local runmode to stateObj["runmode"].
local pList to ship:partsTaggedPattern("dish").

if runmode = 99 set runmode to 0.

lock steering to ship:prograde + r(0, 0, rval).

until runmode = 99 {
    
    if runmode = 0 {
        if ship:liquidFuel <= 1 safe_stage().
        set runmode to 10.
    }

    if runmode = 10 {
        for p in pList {
            activate_antenna(p).
            wait 1.
            //local range to get_antenna_range(p).
            
            set_dish_target(p, kerbin:name).
        }

        set runmode to 99.
    }

    if stateObj["runmode"] <> runmode {
        set stateObj["runmode"] to runmode.
        log_state(stateObj).
    }

    disp_main().
    disp_tel().
    disp_obt_data().
}

wait 5.