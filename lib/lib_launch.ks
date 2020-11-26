@lazyGlobal off.

runOncePath("0:/lib/lib_init").
if ship:partsTaggedPattern("mlp"):length > 0 runOncePath("0:/lib/part/lib_launchpad").


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
        logStr("Fairings jettison").
    }
}

global function arm_stock_fairings {
    parameter pAlt,
              base.

    logStr("arm_stock_fairings").

    when ship:altitude > pAlt then {
        jet_fairing(base).
        logStr("Fairings jettison").
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

    logStr("Current apoapsis below target, correction burn [" + ship:apoapsis + " / " + tApo +"]").
}


// Launch a vessel with a countdown timer
global function launch_vessel {
    parameter countdown is 5, 
              engStart is 2.2.

    logStr("launch_vessel").

    clearScreen.
    global cd is countdown.

    lock steering to up - r(0,0,90).

    local fallback is false.
    local holddown is false.
    local swingarm is false.
    local umbilical is false.

    for p in ship:partsTaggedPattern("mlp") {
        if p:tag:matchesPattern("fallback") set fallback to true.
        else if p:tag:matchesPattern("holddown") set holddown to true.
        else if p:tag:matchesPattern("swingarm") set swingarm to true.
        else if p:tag:matchesPattern("umbilical") set umbilical to true.
    }

    //Setup the launch triggers.    
    when cd <= 20 then {
        mlp_fuel_off().
        logStr("Fueling complete").
    }
    when cd <= 15 then {
        mlp_gen_off(). 
        logStr("Vehicle on internal power").
        if fallback {
            mlp_fallback_open_clamp().
            logStr("Fallback clamp open").
        }
    }
    when cd <= 12 then {
        if fallback {
            mlp_fallback_partial().
            logStr("Fallback tower partial retract").
        }
    }
    when cd <= engStart then {
        logStr("Engine start sequence").
        engine_start_sequence().
    }
    when cd <= 0.4 then {
        if umbilical {
            mlp_drop_umbilical().
            logStr("Umbilicals detached").
        }
    }
    when cd <= 0.2 then {
        if fallback {
            mlp_fallback_full().
            logStr("Fallback tower full retract").
        }
    }
    when cd <= 0.1 then {
        if holddown {
            mlp_retract_holddown().
            logStr("Holddown retracted").
        }
        if swingarm {
            logStr("Swing arms detached").
        }
    }

    logStr("Beginning launch countdown").
    until cd <= 0 {
        disp_launch_main().
        wait 0.1.
        set cd to cd - 0.1.
    }

    lock throttle to 1.
    stage.
    unset cd.
    clearScreen.
}

local function engine_start_sequence {
    
    local tSpool to 0.
    lock throttle to tSpool.

    stage.
    from { local t to 0.} until t >= 0.15 step { set t to t + 0.01.} do {
        disp_launch_main().
        set tSpool to t.
        set cd to cd - 0.015.
    }

    from { local t to 0.16.} until t >= 1 step { set t to t + 0.02.} do {
        disp_launch_main().
        lock throttle to tSpool.
        set tSpool to min(1, t).
        set cd to cd - 0.015.
    }
    lock throttle to 1.
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
    local effPitch is max(pgPitch - 5, min(tPitch, pgPitch + 5)).
    
    return effPitch.
}.


global function get_circ_burn_pitch {
    local obtPitch is 90 - vang(ship:up:vector, ship:prograde:vector).
    return obtPitch * -1.
}


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