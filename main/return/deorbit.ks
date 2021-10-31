@lazyGlobal off.
clearScreen.

parameter pe is -(ship:body:radius / 4).

runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_vessel").
runOncePath("0:/lib/lib_util").

disp_main(scriptPath():name).

local warpAlt to ship:body:atm:height.

lock steering to lookDirUp(ship:retrograde:vector, sun:position).

if ship:periapsis > ship:body:atm:height 
{
    disp_msg("Waiting for apoapsis").
    disp_info("Press 9 to deorbit immediately").
    ag9 off.
    on ag9 
    {
        disp_msg("Immediate deorbit mode").
        disp_info().
    
        set warp to 0.
        wait 1.
    }

    local ts to time:seconds + eta:apoapsis.
    util_warp_trigger(ts).

    until time:seconds >= ts
    {   
        disp_orbit().
        if ag9 break.
        
    }

    lock throttle to 1.
    until ship:periapsis < pe or ship:availablethrust <= 0.1
    {
        disp_orbit().
    }
    lock throttle to 0.
    unlock steering.
    disp_msg("Deorbit burn completed").
}

disp_msg("Waiting for reentry interface").
disp_info("Current Pe: " + round(ship:periapsis)).

ag10 off.
disp_hud("Activate AG10 to warp to " + warpAlt + "m").
if ag10
{
    until ship:altitude <= warpAlt
    {
        util_warp_down_to_alt(warpAlt).
        disp_orbit().
    }
}

until false
{
    disp_telemetry().
}