@lazyGlobal off.

// This script does a hohmann transfer to a given Ap, Pe, and ArgPe
parameter tgtBody,
          tgtVal.

clearScreen.

// Dependencies
runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_mnv").
runOncePath("0:/lib/lib_nav").

disp_main(scriptPath():name).

// Variables
local compMode      to "pe".
local dvNeeded      to list().
local mnvTime       to time:seconds + 90.

local mnvNode to node(mnvTime, 0, 0, 0).
add mnvNode.

local mnvPatch to mnv_last_patch_for_node(mnvNode).

local stAp to mnvPatch:apoapsis.
local stPe to mnvPatch:periapsis.

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
set compMode to "pe".
set dvNeeded to mnv_dv_bi_elliptic(stPe, stAp, tgtVal, tgtVal, stAp, tgtBody).
set dvNeeded to list(dvNeeded[0]).

disp_msg("dv0: " + round(dvNeeded[0], 2)).
wait 1.
disp_msg().

disp_msg("Correction Burn").
set mnvNode to mnv_opt_simple_node(mnvNode, tgtVal, compMode, tgtBody).
add mnvNode.

mnv_exec_node_burn(mnvNode).
remove mnvNode.