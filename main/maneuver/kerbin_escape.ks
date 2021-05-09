@lazyGlobal off.
clearScreen.

runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_util").
runOncePath("0:/lib/lib_vessel").

disp_main(scriptPath():name).
disp_orbit().

local tVal to 0.
lock steering to lookDirUp(ship:prograde:vector, sun:position).
lock throttle to tVal.

// Ensure we have antenna and solar panels activated
ves_activate_antenna().
ves_activate_solar().

// Staging trigger
if stage:number > 0 
{
    when ship:maxThrust <= 0.1 and throttle > 0 then 
    {
        disp_info("Staging").
        ves_safe_stage().
        disp_info().
        if stage:number > 0 preserve.
    }
}

// If we aren't already at the sun or heading towards the sun, burn
until false
{
    if ship:body = body("sun")
    {
        break.
    }
    else if ship:orbit:hasnextpatch
    {
        if ship:orbit:nextpatch:body = body("sun") 
        {
            disp_msg("Current flight path now has " + body("sun"):name + " SOI transition").
            break.
        }
    }
    else 
    {
        disp_msg("Waiting until periapsis for escape burn").
        // Wait until periapsis
        local tsPe to time:seconds + eta:periapsis - 30.
        util_warp_trigger(tsPe).
        until time:seconds >= tsPe 
        {
            disp_info("Time to burn start: " + round(time:seconds - tsPe)).
            disp_orbit().
            wait 0.1.
        }
        disp_info().

        // Burn
        disp_msg("Burning to escape velocity            ").
        set tVal to 1.
        until false
        {
            if ship:orbit:hasNextPatch
            {
                if ship:orbit:nextPatch:body = body("sun") break.
            }
            disp_orbit().
            wait 0.01.
        }
        set tVal to 0.
        disp_msg("Escape velocity reached            ").
    }
}