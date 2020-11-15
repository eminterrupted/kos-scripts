@lazyGlobal off.

runOncePath("0:/lib/lib_init.ks").


//Fairings
global function arm_fairings_on_launch {
    parameter pAlt,
              base.

    local cList is base:children:tagged("pyld.fairing").
    
    when ship:altitude > pAlt and ship:altitude < pAlt + 2500 then {
        for f in cList {
            jet_fairing(f).
        }
    }
}

//Payload
global function deploy_payload {
    wait 1. 
    until stage:number < 1 safe_stage().
}


//Correction burn execute
global function exec_correction_burn {
    
    parameter tApo.

    //If in atm and below target
    lock steering to heading(get_nav_heading(), get_la_for_alt(0, tApo) , 0).

    lock throttle to 0.05.
}


// Launch a vessel with a countdown timer
global function launch_vessel {
    
    clearScreen.
    global cd is 5. 
    lock steering to up - r(0,0,90).

    until cd = 0 {
        disp_launch_main().
        wait 1.
        set cd to cd - 1.
    }
  
    lock throttle to 1.
    stage.    
    unset cd.
    clearScreen.
}


//Set pitch by deviation from a reference pitch to ensure more gradual gravity turns and course corrections
global function get_la_for_alt {

    parameter rPitch.
    parameter tAlt.
    
    declare local tPitch is 0.

    if rPitch < 0 {
        set tPitch to min( rPitch, -(90 * ( 1 - ship:altitude / (tAlt * 1.125)))).
    }

    else if rPitch >= 0 {
        set tPitch to max( rPitch, 90 * ( 1 - ship:altitude / (tAlt * 1.125))).
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