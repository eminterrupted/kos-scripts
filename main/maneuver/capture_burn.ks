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

// Setup taging trigger
when ship:maxThrust <= 0.1 and throttle > 0 then 
{
    if ship:deltaV:current > 0 
    {
        ves_safe_stage().
        preserve.
    }
}

disp_msg("Calculating burn data").

// Calculate the starting altitude.
set mnvNode to node(time:seconds + eta:periapsis, 0, 0, 0).
add mnvNode.

until false
{
    if mnvNode:orbit:hasnextpatch
    {
        remove mnvNode.
        set mnvNode to node(mnvNode:time, 0, 0, mnvNode:prograde - 10).
        add mnvNode.
    }
    else
    {
        break.
    }
}
remove mnvNode.
set mnvNode to mnv_opt_simple_node(mnvNode, tgtAlt, "ap").
add mnvNode.

mnv_exec_node_burn(mnvNode).

unlock steering.