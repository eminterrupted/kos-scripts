@lazyGlobal off.

parameter rVal is 0.

clearScreen.

runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/display/lib_display").
runOncePath("0:/lib/lib_core").
runOncePath("0:/lib/lib_warp").
runOncePath("0:/lib/part/lib_antenna").
runOncePath("0:/lib/data/engine/lib_engine").
runOncePath("0:/lib/data/engine/lib_isp").
runOncePath("0:/lib/data/engine/lib_thrust").
runOncePath("0:/lib/data/engine/lib_twr").
runOncePath("0:/lib/data/ship/lib_mass").
if ship:partsTaggedPattern("rcs"):length > 0 runOncePath("0:/lib/part/lib_rcs").

//
//** Main

//Vars
local runmode to stateObj["runmode"].
local pList to ship:partsTaggedPattern("dish").

if runmode = 99 set runmode to 0.

lock steering to lookDirUp(ship:facing:forevector, sun:position) + r(0, 0, rVal).

until runmode = 99 {
    
    if runmode = 0 {
        safe_stage().
        set runmode to 10.
    }

    if runmode = 10 {
        for p in pList {
            activate_dish(p).
            wait 1.
            local antObj to get_antenna_fields(p).
            if antObj["target"] = "" set_dish_target(p, "Kerbin").
        }

        set runmode to 20.
    }

    if stateObj["runmode"] <> runmode {
        set stateObj["runmode"] to runmode.
        log_state(stateObj).
    }

    update_display().

    wait 0.1.
}

wait 5.