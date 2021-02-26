@lazyGlobal off. 

runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/lib_display").
runOncePath("0:/lib/lib_warp").
runOncePath("0:/lib/lib_core").
runOncePath("0:/lib/lib_heatshield").
runOncePath("0:/lib/lib_chute").


global function do_kerbin_reentry_burn 
{
    parameter reentryAlt is 35000.

    lock steering to lookDirUp(ship:retrograde:vector, sun:position) + r(0, 0, 180).
    local subroutine to 0.
    
    until subroutine = "" 
    {
        if subroutine = 0 
        {
            out_info("Beginning reentry burn subroutine"). 
            set subroutine to sr(2).
            update_display().
        } 
        else if subroutine = 2 
        {
            out_info("Waiting until KSC Reentry window").
            if ship:periapsis > 70000 
            {
                warp_to_ksc_reentry_window().
            }
            set subroutine to sr(4).
            update_display().
        }
        else if subroutine = 4 
        {
            out_info("Perform reentry burn").
            reentry_burn(reentryAlt).
            set subroutine to sr("").
            update_display().
        }
        update_display().
    }
    out_info().
}



global function do_kerbin_reentry 
{

    lock steering to lookDirUp(ship:retrograde:vector, sun:position) + r(0, 0, 180).
    
    local subroutine to init_subroutine().

    until false 
    {
    
        if subroutine = 0 
        {
            out_info("Arming parachutes").
            local chuteList to ship:partsTaggedPattern("chute"). 
            arm_chutes(chuteList).    
            set subroutine to sr(2).
        }

        else if subroutine = 2 
        {
            out_info("Warping to 50000m above atmosphere").
            local warpAlt is body:atm:height + 50000.
            warp_to_alt(warpAlt).
            set subroutine to sr(4).
        }

        else if subroutine = 4 
        {
            out_info("Staging CSM").
            if warp = 0 and kuniverse:timewarp:issettled 
            {
                lock steering to ship:retrograde + r(0, 90, 180).
                wait 3. 
                until stage:number = 1 
                {
                    safe_stage().
                }
                lock steering to ship:retrograde + r(0, 0, 180).
                set subroutine to sr(6).
            }
        }
            
        else if subroutine = 6 
        {
            out_info("Controlled descent").
            until ship:altitude <= 12500 
            {
                update_display().    
                wait 5.
            }
            set subroutine to sr(8).
        }

        else if subroutine = 8 
        {
            out_info("Free fall").
            unlock steering.
            until alt:radar <= 500 and ship:verticalSpeed <= 75 
            {
                update_display().
                disp_timer(time:seconds + utils:timeToGround(), "Time to ground").
                wait 0.01.
            }
            set subroutine to sr(10).
        }

        else if subroutine = 10 
        {
            out_info("Heatshield jettison").
            jettison_heatshield(ship:partsTaggedPattern("heatshield")[0]).
            set subroutine to sr(12).
        }

        else if subroutine = 12 
        {
            out_info("Awaiting touchdown").
            until alt:radar < 25 
            {
                update_display().
                disp_timer(time:seconds + utils:timeToGround()).
                wait 0.01.
            }
            
            break.
        }

        update_display().
    }

    sr("").
    out_info().
}



//local functions
local function reentry_burn 
{
    parameter reentryAlt.

    lock steering to lookDirUp(ship:retrograde:vector, sun:position) + r(0, 0, 180).

    out_info("Waiting until ship is settled").    
    until shipSettled() 
    {
        update_display().
        wait 0.01.
    }

    out_info("Burning at 100% throttle").
    lock throttle to 1.

    until ship:periapsis <= reentryAlt 
    {
        update_display().
        wait 0.01.
    }

    out_info("Shutdown").
    lock throttle to 0.
    update_display().

    out_info().
}