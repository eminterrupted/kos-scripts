@lazyGlobal off.

clearscreen.

parameter returnBody is body("Kerbin"),
          returnAlt  is 42500.

runOncePath("0:/lib/lib_conics").
runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_mnv").
runOncePath("0:/lib/lib_mnv_optimization").

disp_main(scriptPath()).

local mnvNode to node(0, 0, 0, 0).
local exitTS to 0.

// Staging trigger
when ship:maxThrust <= 0.1 and throttle > 0 then 
{
    ves_safe_stage().
    preserve.
}

if hasNode remove nextNode.
if not ship:orbit:hasnextpatch
{
    

    set mnvNode to mnv_exit_node(returnBody).
    set exitTS  to nextNode:orbit:nextpatcheta + time:seconds.
    set mnvNode to mnv_optimize_exit_pe(mnvNode, returnAlt).
    wait 1.

    // Optimize dV for free return
    disp_msg("Optimizing reentry window").
    remove mnvNode.
    set mnvNode to mnv_opt_return_node(mnvNode, returnBody, returnAlt).
    add mnvNode.

    disp_msg("Optimized maneuver created").

    mnv_exec_node_burn(mnvNode).
}

lock steering to lookDirUp(ship:prograde:vector, sun:position).

util_warp_trigger(time:seconds + ship:orbit:nextpatcheta, "next SOI", 5).

until ship:orbit:body:name = "Kerbin"
{
    disp_info("Time to SOI change: " + disp_format_time(ship:orbit:nextpatcheta, "ts")).
    disp_orbit().
    wait 0.01.
}