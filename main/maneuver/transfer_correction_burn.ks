@lazyGlobal off.

// This script does a hohmann transfer to a given Ap, Pe, and ArgPe
parameter tgtBody,
          tgtPe,
          tgtInc is 0.1.

clearScreen.

// Dependencies
runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_mnv").
runOncePath("0:/lib/lib_nav").

disp_main(scriptPath():name).

// Variables
local dvNeeded      to list().
local mnvTime       to time:seconds + 90.
local mnvNode to node(mnvTime, 0, 0, -1).
add mnvNode.
local mnvPatch to nav_last_patch_for_node(mnvNode).
local stAp to mnvPatch:apoapsis.
local stPe to mnvPatch:periapsis.
remove mnvNode.

// Control locks
local sVal          to lookDirUp(ship:facing:vector, sun:position).
local tVal          to 0.
lock  steering      to sVal.
lock  throttle      to tVal.

// Staging trigger
when ship:maxThrust <= 0.1 and throttle > 0 then 
{
    ves_safe_stage().
    preserve.
}

// Main
set mnvNode to mnv_opt_simple_node(mnvNode, tgtInc, "tliInc", tgtBody, 10).

set dvNeeded to mnv_dv_bi_elliptic(stPe, stAp, tgtPe, tgtPe, stAp, tgtBody).
set dvNeeded to list(dvNeeded[0]).

disp_msg("dv0 Needed: " + round(dvNeeded[0], 2)).
wait 1.
disp_msg().

disp_msg("Correction Burn Calculations").
set mnvNode to mnv_opt_simple_node(mnvNode, tgtPe, "pe", tgtBody).
add mnvNode.

mnv_exec_node_burn(mnvNode).
remove mnvNode.