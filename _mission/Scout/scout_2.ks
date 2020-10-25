@lazyGlobal off. 

set config:ipu to 200.

clearScreen.
runOncePath("0:/lib/lib_core.ks").
runOncePath("0:/lib/lib_display.ks").
runOncePath("0:/lib/lib_init.ks").
runOncePath("0:/lib/lib_launch.ks").
runOncePath("0:/lib/lib_sci.ks").
runOncePath("0:/lib/lib_warp.ks").
runOncePath("0:/lib/data/engine/lib_engine.ks").
runOncePath("0:/lib/data/engine/lib_isp.ks").
runOncePath("0:/lib/data/engine/lib_thrust.ks").
runOncePath("0:/lib/data/engine/lib_twr.ks").
runOncePath("0:/lib/data/vessel/lib_mass.ks").


//
//** Main

//Vars
global runmode is 0.
global sVal is heading(90, 90, 270).
global tVal is 0.

local gravTurnAlt is 50000.
local maxAlt is 0.
local rAlt is 40000.
local refPitch to 3.
local tApo is 250000.

lock steering to sVal.

until runmode = 99 {

    //Setup
    local sciList is get_sci_modules_for_vessel().

    //pad science
    if runmode = 0 {   
        log_sci_list(sciList).
        transmit_sci_list(sciList).
        set runmode to 2.
    }

    //countdown
    else if runmode = 2 {
        set tVal to 1.
        launch_vessel().
        set runmode to 10.
    }

    //launch
    else if runmode = 10 and alt:radar >= 100 {
        set sVal to heading (90, 90, 0).
        
        log_sci_list(sciList).
        transmit_sci_list(sciList).
        
        set runmode to 12.
    }

    //vertical ascent
    else if runmode = 12 {
        if ship:altitude >= 1250 or ship:verticalSpeed >= 120 {
            set runmode to 14.
        }
    }

    //gravity turn
    else if runmode = 14 {
        set sVal to heading(90, get_pitch_for_altitude(refPitch, gravTurnAlt), 0).
        if ship:apoapsis >= tApo * 0.90 set runmode to 16.
    }

    //slow burn to tApo
    else if runmode = 16 {
        if ship:apoapsis < tApo {
            set tVal to max(0.1, 1 - (ship:apoapsis / tApo)).
        }

        else if ship:apoapsis >= tApo set runmode to 18. 
    }

    //coast / correction burns
    else if runmode = 18 {
        
        lock steering to heading(get_nav_heading(), get_pitch_for_altitude(0, gravTurnAlt) , 0).

        if ship:apoapsis >= tApo {
            set tVal to 0.
        }
        
        else {
            set tVal to 0.25.
        }

        if ship:altitude >= 70000 {
            log_sci_list(sciList).
            transmit_sci_list(sciList).
            set runmode to 20.
        }
    }


    else if runmode = 20 {
        global burnObj is get_burn_data(tApo).
        disp_burn_data(burnObj).
        set runmode to 22.
    }

    //circularization burn
    else if runmode = 22 {
        disp_burn_data(burnObj).
        
        set tVal to 0. 
        set sVal to heading(90, get_pitch_for_altitude(0, tApo), 0).
        
        local burnEta is burnObj["burnEta"] - time:seconds.

        if warp = 0 and burnEta > 30 {
            if steeringManager:angleerror < 0.1 and steeringManager:angleerror > -0.1 warpTo(burnObj["burnEta"] - 15).
        }

        if time:seconds >= burnObj["burnEta"] and ship:periapsis <= tApo and kuniverse:timewarp:issettled {
            set runmode to 24.
        }
    }

    else if runmode = 24 {
        disp_burn_data(burnObj).

        set tVal to 1.
        set sVal to heading(90, get_pitch_for_altitude(0, tApo), 0).

        if ship:periapsis >= tApo * 0.90 and ship:periapsis < tApo {
            set tVal to max(0.1, 1 - (ship:apoapsis / tApo)).
        }

        if ship:periapsis >= tApo {
            set tVal to 0. 
            clear_sec_data_fields().
            set runmode to 26.
        }
    }

    else if runmode = 26 {
        set tVal to 0.
        set sVal to ship:prograde.
        //safe_stage().
        set runmode to 30.
    }


    //Stage the remaining rocket away to leave just the sat. 
    //If we can go into high orbit, do science there. Advance when ship begins falling
    else if runmode = 30 {
        set sVal to ship:prograde.
        if ship:apoapsis > 250000 {
            if ship:altitude >= 250000 {
                log_sci_list(sciList).
                transmit_sci_list(sciList).
            }
            set runmode to 32. 
        }

        else set runmode to 32. 
    }
    

    else if runmode = 32 {
        local dTime is time:seconds + 3600.

        if warp = 0 and steeringManager:angleerror < 0.1 and steeringManager:angleerror > -0.1 warpTo(dTime - 15).

        if kuniverse:timewarp:issettled and warp = 0 set runmode to 34.
    }


    else if runmode = 34 { 
        set sVal to ship:retrograde.

        if steeringManager:angleerror < 0.1 and steeringmanager:angleerror > -0.1 set runmode to 36. 
    }



    else if runmode = 36 {
        set sVal to ship:retrograde.
        if ship:periapsis > rAlt set tVal to max(0, min(1, (ship:periapsis / tApo))).
        else {
            set tVal to 0.
            set runmode to 38.
        }
    }


    else if runmode = 38 {
        if stage:nextDecoupler <> "None" safe_stage().

        set runmode to 40.
    }


    else if runmode = 40 {
        set sVal to ship:retrograde.
        arm_chutes().

        set runmode to 42.
    }


    else if runmode = 42 {
        set sVal to ship:retrograde.
        if ship:altitude > body:atm:height * 1.3 set warp to 2.
        else if ship:altitude < body:atm:height * 1.1 kuniverse:timewarp:cancelWarp().

        if warp = 0 set runmode to 44.
    }

    else if runmode = 44 {
        if alt:radar <= 10000 set runmode to 50. 

    }
        
    else if runmode = 50 and alt:radar <=100 {
        set runmode to 99.
    }

    if runmode < 44 {
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
    disp_launch_telemetry(runmode, maxAlt).
}

//** End Main
//
