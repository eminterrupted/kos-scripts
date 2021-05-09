@lazyGlobal off.
clearScreen.

parameter launchPlan.

runOncePath("0:/lib/lib_file").
runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_mnv").
runOncePath("0:/lib/lib_vessel").
runOncePath("0:/kslib/lib_navball").
runOncePath("0:/kslib/lib_l_az_calc.ks").

// Circ burn below here
clearScreen.
disp_main(scriptPath()).
disp_msg("Calculating circ burn data").

// Variables
local tgtAp         to launchPlan:tgtAp.
local tgtPe         to launchPlan:tgtPe.
local mnvTime       to time:seconds + eta:apoapsis.

// Control
local rVal          to launchPlan:tgtRoll.
local sVal          to lookDirUp(ship:prograde:vector, sun:position) + r(0, 0, rVal).
local tVal          to 0.
lock steering       to sVal.
lock throttle       to tVal.

// Get dv and duration of burn
local dv            to mnv_dv_bi_elliptic(ship:periapsis, ship:apoapsis, tgtPe, tgtPe, tgtAp, ship:body)[1].
local burnTime      to mnv_burn_times(dv, mnvTime).
local burnETA       to burnTime[0].
local burnDur       to burnTime[1].
local mnvNode       to node(mnvTime, 0, 0, dv).
set mnvNode to mnv_opt_simple_node(mnvNode, tgtPe, "pe").
add mnvNode.
    
disp_msg().
disp_msg("dv needed: " + round(dv, 2)).
disp_info("Burn duration: " + round(burnDur, 1)).

when ship:maxThrust <= 0.1 and throttle > 0 then 
{
    disp_info("Staging").
    ves_safe_stage().
    disp_info().
    if stage:number > 0 preserve.
}

mnv_exec_node_burn(mnvNode, burnETA, burnDur).

disp_msg("Maneuver complete!").
wait 1.
clearScreen.
//-- End Main --//