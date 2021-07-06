@lazyGlobal off.

clearscreen.

parameter returnBody is body("Kerbin"),
          returnAlt  is 45000.

runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_mnv").

disp_main(scriptPath()).

// Staging trigger
when ship:maxThrust <= 0.1 and throttle > 0 then 
{
    ves_safe_stage().
    preserve.
}

if hasNode until not hasNode remove nextNode.
if not ship:orbit:hasnextpatch
    {
    // Add node at Pe
    disp_msg("Adding node at Pe").
    local mnvTime to time:seconds + eta:periapsis.
    local mnvNode to node(mnvTime, 0, 0, 10).
    add mnvNode.

    wait 1.

    // Given it dv to escape
    disp_msg("Adding escape dv").
    until false
    {
        if mnvNode:orbit:hasnextpatch
        {
            if mnvNode:orbit:nextPatch:body = returnBody
            {
                break.
            }   
        }
        remove mnvNode.
        set mnvNode to change_node_value(mnvNode, "prograde", 25).
        add mnvNode.
        wait 0.01.
        //disp_info("Patch Body: " + ship:orbit:nextPatch:body).
    }
    disp_info().
    wait 1.

    // Sweep timing to lowest Pe
    disp_msg("Sweeping timing for lowest Pe").
    local lastPe to mnvNode:orbit:nextPatch:periapsis.
    until false
    {
        disp_info("Current Pe: " + mnvNode:orbit:nextPatch:periapsis).
        disp_info2("LastPe    : " + lastPe).
        if lastPe < mnvNode:orbit:nextPatch:periapsis
        {
            break.
        }
        
        set lastPe to mnvNode:orbit:nextPatch:periapsis. 
        remove mnvNode.
        set mnvNode to change_node_value(mnvNode, "time", 10).
        add mnvNode.
    }
    disp_info().
    disp_info2().

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

disp_hud("Press 0 to warp to next SOI").
util_warp_trigger(time:seconds + ship:orbit:nextpatcheta).

until ship:orbit:body:name = "Kerbin"
{
    disp_info("Time to SOI change: " + disp_format_time(round(ship:orbit:nextpatcheta), "ts")).
    disp_orbit().
    wait 0.01.
}

// Functions
local function change_node_value
{
    parameter checkNode,
              valToChange,
              changeAmount.

    if valToChange      = "time"     return node(checkNode:time + changeAmount, checkNode:radialOut, checkNode:normal, checkNode:prograde).
    else if valToChange = "prograde" return node(checkNode:time, checkNode:radialOut, checkNode:normal, checkNode:prograde + changeAmount).
    else if valToChange = "normal"   return node(checkNode:time, checkNode:radialOut, checkNode:normal + changeAmount, checkNode:prograde).
    else if valToChange = "radial"   return node(checkNode:time, checkNode:radialOut + changeAmount, checkNode:normal, checkNode:prograde).
}
