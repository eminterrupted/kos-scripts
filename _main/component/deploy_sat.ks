@lazyGlobal off. 

clearScreen.
runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/display/lib_display").
runOncePath("0:/lib/lib_core").
runOncePath("0:/lib/lib_warp").


//
//** Main
//local stateObj to init_state_obj().
local runmode to stateObj["runmode"].

//Vars
local sVal is ship:prograde.
lock steering to sVal.

local tStamp is 0.

if runmode = 99 set runmode to set_rm(0). 

clearscreen.

until runmode = 99 {
    
    if runmode = 0 {
        set sVal to ship:prograde. 
        set runmode to set_rm(10).
    }

    else if runmode = 10 {
        set sVal to ship:prograde. 
        if warp = 0 {
            set runmode to set_rm(20). 
            warpTo(tStamp).
        }
    }

    else if runmode = 20 {
        set sVal to ship:prograde. 
        if time:seconds >= tStamp set runmode to set_rm(30).
        else disp_timer(tStamp).
    }

    else if runmode = 30 {
        set sVal to ship:prograde. 
        unset tStamp.
        deploy_payload().

        set runmode to set_rm(99).
    }

    else if runmode < 99 {
        unlock steering.
        unlock throttle.
    }
    
    update_display().
}

//** End Main
//
