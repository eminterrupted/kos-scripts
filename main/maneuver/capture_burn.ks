@lazyGlobal off.
clearScreen.

// This script circularizes a launch to the desired Pe
// Accepts either a scalar or a lex with a tgtPe key

parameter tgtAlt is ship:periapsis + 500.

runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_mnv").
runOncePath("0:/lib/lib_vessel").
runOncePath("0:/kslib/lib_navball").

disp_terminal().
disp_main(scriptPath():name).

// Variables
local mnvNode   to node(0, 0, 0, 0).

if hasNode 
{
    if nextNode:eta > 300 and nextNode:orbit:apoapsis >= ship:orbit:periapsis + ship:orbit:periapsis * 1.005 
    {
        remove nextNode.
    }
}

// Setup taging trigger
when ship:maxThrust <= 0.1 and throttle > 0 then 
{
    if ship:deltaV:current > 0 
    {
        ves_safe_stage().
        preserve.
    }
}

lock steering to lookDirUp(ship:facing:vector, sun:position).

disp_msg("Calculating burn data").

// Calculate the starting altitude.
local stAlt to choose ship:body:soiRadius - ship:apoapsis if ship:apoapsis < 0 else ship:apoapsis - ship:body:soiRadius.
local dvNeeded to mnv_dv_hohmann(stAlt, tgtAlt)[1].
set mnvNode to node(time:seconds + eta:periapsis, 0, 0, dvNeeded).
add mnvNode.

until false
{
    if mnvNode:orbit:hasnextpatch
    {
        disp_info("Adjusting maneuver to terminate in current SOI").
        remove mnvNode.
        set mnvNode to node(mnvNode:time, 0, 0, mnvNode:prograde - 10).
        add mnvNode.
    }
    else
    {
        disp_info().
        break.
    }
}
remove mnvNode.
set mnvNode to mnv_opt_simple_node(mnvNode, tgtAlt, "ap", ship:body, 0.005, list(10, 0, 0, 1)).
add mnvNode.

unlock steering.

mnv_exec_node_burn(mnvNode).