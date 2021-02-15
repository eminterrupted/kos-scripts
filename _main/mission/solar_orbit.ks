@lazyGlobal off.

parameter _tgtAp is 10000000000, 
          _tgtPe is 10000000000.

runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/lib_core").
runOncePath("0:/lib/lib_util").
runOncePath("0:/lib/lib_warp").
runOncePath("0:/lib/lib_display").
runOncePath("0:/lib/lib_nav").
runOncePath("0:/lib/lib_calc_mnv").
runOncePath("0:/lib/lib_node").

local mnvNode   to node(time:seconds + eta:periapsis, 0, 0, 0).
local mnvObj   to lex().
local nextPatch to ship:orbit.

add mnvNode.

out_info("Adding escape node").
until mnvNode:orbit:transition = "ESCAPE" 
{
    remove mnvNode.
    set mnvNode to node(mnvNode:time, mnvNode:radialout, mnvNode:normal, mnvNode:prograde + 50).
    add mnvNode.
    wait 0.01.
}

set nextPatch to mnvNode:orbit:nextPatch.

out_info().
wait 1.

out_info("Optimizing sun orbit periapsis").

if _tgtAp < ship:body:altitude
{
    until last_patch_for_node(mnvNode):apoapsis <= ship:body:altitude
    {
        remove mnvNode.
        set mnvNode to node(mnvNode:time + 50, mnvNode:radialout, mnvNode:normal, mnvNode:prograde).
        add mnvNode.
        wait 0.01.
    }
    optimize_existing_node(mnvNode, _tgtPe, "pe", nextPatch:body, 0.01).
}
else 
{
    until last_patch_for_node(mnvNode):apoapsis > ship:body:altitude 
    {
        remove mnvNode.
        set mnvNode to node(mnvNode:time + 50, mnvNode:radialout, mnvNode:normal, mnvNode:prograde).
        add mnvNode.
        wait 0.01.
    }
    optimize_existing_node(mnvNode, _tgtAp, "Ap", nextPatch:body, 0.01).
}

// Now we execute the initial node
set mnvObj to get_burn_obj_from_node(nextNode).
warp_to_burn_node(mnvObj).
exec_node(nextNode).

// Add the next node
local tgtPatch to last_patch().
set mnvNode to node(tgtPatch:eta:periapsis, 0, 0, get_dv_for_retrograde(_tgtAp, tgtPatch:apoapsis, tgtPatch:body)).
add mnvNode.

optimize_existing_node(mnvNode, _tgtAp, "ap", tgtPatch:body, 0.005).