@lazyGlobal off. 

set config:ipu to 250.

clearScreen.
runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/lib_display").
runOncePath("0:/lib/lib_core").
runOncePath("0:/lib/lib_launch").
runOncePath("0:/lib/lib_sci").
runOncePath("0:/lib/lib_warp").
runOncePath("0:/lib/data/engine/lib_engine").
runOncePath("0:/lib/data/engine/lib_isp").
runOncePath("0:/lib/data/engine/lib_thrust").
runOncePath("0:/lib/data/engine/lib_twr").
runOncePath("0:/lib/data/ship/lib_mass").
runOncePath("0:/lib/part/lib_chute").

//
//** Main

//Vars
//local stateObj to init_state_obj().
local runmode is stateObj["runmode"].
local sVal is ship:retrograde.
local tVal is 0.

local maxAlt is 0.
local rAlt is 40000.

until runmode = 99 {
    
    if runmode = 0 { 
        set sVal to ship:retrograde.

        if steeringManager:angleerror < 0.1 and steeringmanager:angleerror > - 0.1 set runmode to 4. 
    }

    else if runmode = 4 {
        set sVal to ship:retrograde.
        if ship:periapsis > rAlt {
            if steeringManager:angleError < 0.1 and steeringManager:angleError > - 0.1 {
                set tVal to max(0, min(1, (ship:periapsis / rAlt))).
            }
        }

        else {
            set tVal to 0.
            set runmode to 8.
        }
    }

    else if runmode = 8 {
        if stage:nextDecoupler <> "None" safe_stage().

        set runmode to 15.
    }

    else if runmode = 15 {
        set sVal to ship:retrograde.
        arm_chutes().

        set runmode to 16.
    }

    else if runmode = 16 {
        set sVal to ship:retrograde.
        if ship:altitude > body:atm:height * 1.3 set warp to 2.
        else if ship:altitude < body:atm:height * 1.1 kuniverse:timewarp:cancelWarp().

        if warp = 0 set runmode to 23.
    }

    else if runmode = 23 {
        set sVal to ship:retrograde.
        if alt:radar <= 10000 set runmode to 42. 

    }
        
    else if runmode = 42 and alt:radar <=5000 {
        unlock steering.
        set runmode to 64.
    }

    else if runmode = 64 and ship:status = "LANDED" {
        set runmode to 99.
    }

    if runmode < 99 {
        lock steering to sVal.
        lock throttle to tVal.
    }

    else {
        unlock steering. 
        lock throttle to 0.
    }

    if stage:number > 0 and ship:availableThrust <= 0.1 and tVal <> 0 {
        safe_stage().
    }

    set maxAlt to max(maxAlt, ship:altitude).
    disp_main().
    disp_tel().
}

//** End Main
//
