@lazyGlobal off.
clearScreen.

// This script does a hohmann transfer to a given Ap, Pe, and ArgPe
parameter tgtAlt is 25000,
          burnAt is "ap".

// Dependencies
runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_mnv").
runOncePath("0:/lib/lib_nav").

disp_main(scriptPath():name).

// Variables
local burnDur       to 0.
local burnETA       to 0.
local compMode      to choose "pe" if burnAt = "ap" else "ap".
local dvNeeded      to list().
local mnvTime       to choose time:seconds + eta:apoapsis if burnAt = "ap" else time:seconds + eta:periapsis.
local stPe          to ship:periapsis.

// Control locks
local sVal          to lookDirUp(ship:prograde:vector, sun:position).
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
disp_msg("Calculating burn data").

// Get the amount of dv needed to raise from current to desired
set dvNeeded to mnv_dv_bi_elliptic(stPe, ship:apoapsis, tgtAlt, ship:apoapsis, ship:apoapsis, ship:body).
set dvNeeded to choose dvNeeded[1] if burnAt = "ap" else dvNeeded[0].
disp_msg("dvNeeded: " + round(dvNeeded, 2) + "   ").
wait 1.

// Transfer burn
set burnDur     to mnv_staged_burn_dur(dvNeeded).
set burnETA     to mnvTime - mnv_staged_burn_dur(dvNeeded / 2).
local mnvNode   to node(mnvTime, 0, 0, dvNeeded).
mnv_opt_simple_node(mnvNode, tgtAlt, compMode).
add mnvNode.
disp_info("Burn duration: " + round(burnDur, 1)).
mnv_exec_node_burn(mnvNode, burnEta, burnDur).