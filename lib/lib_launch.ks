@lazyGlobal off.

runOncePath("0:/lib/lib_init.ks").

//Correction burn execute
global function exec_correction_burn {
    
    parameter tApo.

    //If in atm and below target
    lock steering to heading(get_nav_heading(), get_pitch_for_altitude(0, tApo) , 0).

    lock throttle to 0.05.
}


// Launch a vessel with a countdown timer
global function launch_vessel {
    
    clearScreen.
    local countdown is 3. 
    lock steering to up - r(0,0,90).
    from { local launchTimer is 0.} until launchTimer = countdown step { set launchTimer to launchTimer + 1.} do {
        set dObj["countdown"] to (countdown - launchTimer).
        disp_main().
        disp_countdown().

        wait 1.
    }

    lock throttle to 1.
    stage.    
    clearScreen.
}


//Set pitch by deviation from a reference pitch to ensure more gradual gravity turns and course corrections
global function get_pitch_for_altitude {

    parameter rPitch.
    parameter tAlt.
    
    declare local tPitch is 0.

    if rPitch < 0 {
        set tPitch to min( rPitch, -(90 * ( 1 - ship:altitude / tAlt))).
    }

    else if rPitch >= 0 {
        set tPitch to max( rPitch, 90 * ( 1 - ship:altitude / tAlt)).
    }
    
    return tPitch.
}.


global function slow_throttle_for_time {
    parameter pEta.

    return 1 - ( missiontime / pEta).
}

global function slow_throttle_for_alt {
    parameter pAlt.

    return 1 - ( ship:altitude / pAlt).
}


global function slow_throttle_for_ap {
    parameter pAlt.

    return 1 - ( ship:apoapsis / pAlt).
}


global function slow_throttle_for_pe {
    parameter pAlt.

    return 1 - ( ship:periapsis / pAlt).
}