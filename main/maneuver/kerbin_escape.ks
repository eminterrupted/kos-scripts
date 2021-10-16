@lazyGlobal off.
clearScreen.

parameter direction to "retro",
          tgtAlt to kerbin:orbit:periapsis - 5000000000.

runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_mnv").
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
local escNode to node(time:seconds + eta:apoapsis, 0, 0, 250).
add escNode.
until false
{
    if nextNode:orbit:hasnextpatch
    {
        if nextNode:orbit:nextpatch:body = body("sun")
        {
            disp_msg("Current flight path now has " + body("sun"):name + " SOI transition").
            disp_info("Optimizing orbit for target altitude (" + tgtAlt + ")").
            remove escNode.
            set escNode to mnv_opt_return_node(escNode, body("sun"), tgtAlt).
            add escNode.
            // if direction = "pro" 
            // {
            //     set escNode to mnv_optimize_exit_ap(escNode, tgtAlt, body("sun")). 
            //     add escNode.
            // } 
            // else
            // {
            //     set escNode to mnv_optimize_exit_pe(escNode, tgtAlt, body("sun")).
            //     add escNode.
            // }
            break.
        }
        else
        {
            remove escNode.
            set escNode to node(escNode:time, 0, 0, escNode:prograde + 100).
            add escNode.
        }
    }
    else
    {
        disp_msg("Calculating necessary deltaV").
        local dvNeeded to mnv_dv_hohmann(ship:orbit:semimajoraxis - ship:body:radius, ship:body:soiradius + 100000)[0].
        disp_info("DeltaV needed for escape velocity: " + round(dvNeeded, 2)).
        
        remove escNode.
        set escNode to node(escNode:time, 0, 0, dvNeeded).
        add escNode.
    }
}

mnv_exec_node_burn(escNode).