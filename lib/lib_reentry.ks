@lazyGlobal off. 

runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/lib_display").
runOncePath("0:/lib/lib_warp").
runOncePath("0:/lib/lib_core").
runOncePath("0:/lib/part/lib_heatshield").
runOncePath("0:/lib/part/lib_chute").


global function do_kerbin_reentry_burn {
    parameter reentryAlt is 35000.

    lock steering to lookDirUp(ship:retrograde:vector, sun:position) + r(0, 0, 180).
    local subroutine to 0.
    
    until subroutine = "" {
        if subroutine = 0 {
            out_msg("Beginning reentry burn subroutine"). 
            set subroutine to set_sr(2).
            update_display().
        } 
        
        else if subroutine = 2 {
            out_msg("Waiting until KSC Reentry window").
            if ship:periapsis > 70000 {
                warp_to_ksc_reentry_window().
            }

            set subroutine to set_sr(4).
            update_display().
        }

        else if subroutine = 4 {
            out_msg("Perform reentry burn").
            reentry_burn(reentryAlt).
            set subroutine to set_sr("").
            update_display().
        }

        update_display().
    }
}



global function do_kerbin_reentry {

    lock steering to lookDirUp(ship:retrograde:vector, sun:position) + r(0, 0, 180).
    
    local subroutine to init_subroutine().

    until false {
    
        if subroutine = 0 {
            out_msg("Arming parachutes").
            local chuteList to ship:partsTaggedPattern("chute"). 
            arm_chutes(chuteList).    
            set subroutine to set_sr(2).
        }

        else if subroutine = 2 {
            out_msg("Warping to 15000m above atmosphere").
            local warpAlt is body:atm:height + 15000.
            warp_to_alt(warpAlt).
            set subroutine to set_sr(4).
        }

        else if subroutine = 4 {
            out_msg("Staging CSM").
            if warp = 0 and kuniverse:timewarp:issettled {
                lock steering to ship:retrograde + r(45, 0, 180).
                wait 5. 
                until stage:number = 1 {
                    safe_stage().
                }
                lock steering to ship:retrograde + r(0, 0, 180).
                wait 5.
                set subroutine to set_sr(6).
            }
        }
            
        else if subroutine = 6 {
            out_msg("Controlled descent").
            until ship:altitude <= 12500 {
                update_display().    
                wait 0.01.
            }
            unlock steering.
            set subroutine to set_sr(8).
        }

        else if subroutine = 8 {
            out_msg("Free fall").
            until alt:radar <= 500 and ship:verticalSpeed <= 75 {
                update_display().
                disp_timer(time:seconds + utils:timeToGround()).
                wait 0.01.
            }
            jettison_heatshield(ship:partsTaggedPattern("heatshield")[0]).
            set subroutine to set_sr(10).
        }

        else if subroutine = 10 {
            out_msg("Heatshield jettison").
            until alt:radar < 25 {
                update_display().
                disp_timer(time:seconds + utils:timeToGround()).
                wait 0.01.
            }
            
            break.
        }

        update_display().
    }

    set_sr("").
}



//local functions
local function reentry_burn {
    parameter reentryAlt.

    lock steering to lookDirUp(ship:retrograde:vector, sun:position) + r(0, 0, 180).
    
    until steeringManager:angleerror < 0.25 and steeringManager:angleerror > -0.25 {
        update_display().
        wait 0.01.
    }

    lock throttle to 1.

    until ship:periapsis <= reentryAlt {
        update_display().
        wait 0.01.
    }

    lock throttle to 0.
    update_display().
}