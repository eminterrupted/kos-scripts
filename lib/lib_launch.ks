@lazyGlobal off.

runOncePath("0:/lib/lib_init.ks").


//Fairings
global function arm_proc_fairings {
    parameter pAlt,
              base.

    logStr("arm_proc_fairings").

    local cList is base:children.
    
    when ship:altitude > pAlt then {
        for f in cList {
            if f:tag:contains("pl.pf.fairing") jet_fairing(f).
        }
    }
}

global function arm_stock_fairings {
    parameter pAlt,
              base.

    logStr("arm_stock_fairings").

    when ship:altitude > pAlt then {
        jet_fairing(base).
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
    
    logStr("launch_vessel").

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

    parameter rPitch, 
              tAlt,
              sAlt is 1000.
    
    local tPitch is 0.

    if rPitch < 0 {
        set tPitch to min( rPitch, -(90 * ( 1 - (ship:altitude - sAlt) / (tAlt)))). //* 1.125)))).
    }

    else if rPitch >= 0 {
        set tPitch to max( rPitch, 90 * ( 1 - (ship:altitude - sAlt) / (tAlt))). // * 1.125))).
    }
    
    local pg is choose ship:srfPrograde:vector if ship:altitude < tAlt * 0.65 else ship:prograde:vector.
    local pgPitch is 90 - vang(ship:up:vector, pg).
    local vesPitch is 90 - vang(ship:up:vector, ship:facing:forevector).
    local devPitch is vang(ship:facing:forevector, pg).
    local effPitch is max(pgPitch - 5, min(tPitch, pgPitch + 5)).
    
    logStr("get_la_for_alt [tPitch: " + round(tPitch, 3) + "][effPitch: " + round(effPitch, 3) + "][vesPitch: " + round(vesPitch, 3) + "][deviation:" + round(devPitch, 3) + "]").

    return effPitch.
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