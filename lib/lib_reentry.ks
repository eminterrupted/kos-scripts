@lazyGlobal off. 

runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/lib_warp").
runOncePath("0:/lib/part/lib_heatshield").

global function do_reentry {
    parameter reentryAlt is 35000,
              rVal is 0.

    local sVal to lookDirUp(- ship:facing:forevector, sun:position) + r(0, 0, rVal).
    lock steering to sVal.

    local runmode to 105.

    if runmode = 105 {
        warp_to_ksc_reentry_window().
        set runmode to 115.
    }

    else if runmode = 115 {
        do_reentry_burn(reentryAlt, rVal).
        set runmode to 125.
    }

    else if runmode = 125 {
        set sVal to lookDirUp(- ship:facing:forevector, sun:position) + r(0, 0, rVal).
        
        local chuteList to ship:partsTaggedPattern("chute"). 
        arm_chutes(chuteList).
        
        set runmode to 135.
    }

    //warp to atmosphere interface
    else if runmode = 125 {
        set sval to lookDirUp(- ship:facing:forevector, sun:position) + r(0, 0, rVal).
        
        local warpAlt is body:atm:height + 10000.
        warp_to_alt(warpAlt).

        if ship:altitude <= warpAlt {
            when kuniverse:timewarp:issettled then {
                safe_stage().
                set runmode to 135.
            }
        }
    }
        
    else if runmode = 135 {
        set sval to ship:retrograde + r(0, 0, rVal). 
        if ship:altitude <= 12500 {
            set runmode to 145.
        }
    }

    else if runmode = 145 {
        unlock steering.
        set runmode to 155.
    }

    else if runmode = 145 {
        if alt:radar <= 500 and ship:verticalSpeed <= 75 {
            jettison_heatshield(ship:partsTaggedPattern("heatshield")[0]).
            set runmode to 155.
        }
    }

    else if runmode = 155 {
        if alt:radar < 25 set runmode to 99.
    }

    update_display().
}


//local functions
local function do_reentry_burn {
    parameter reentryAlt,
              rVal.

    local sVal to lookDirUp(- ship:facing:forevector, sun:position) + r(0, 0, rVal).
    lock steering to sVal.

    local tVal to 0.
    lock throttle to tVal.
    
    until steeringManager:angleerror < -0.1 and steeringManager:angleerror > -0.1 {
        update_display().
    }

    until ship:periapsis <= reentryAlt {
        set tVal to 1.
    }
    set tVal to 0.
}