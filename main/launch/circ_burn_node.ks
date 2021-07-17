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
local panelList     to list().
disp_info("Variables set").

// Control
local rVal          to launchPlan:tgtRoll.
local sVal          to lookDirUp(ship:facing:vector, sun:position) + r(0, 0, rVal).
local tVal          to 0.
lock steering       to sVal.
lock throttle       to tVal.
disp_info("Controls set").

// Get dv and duration of burn
local dv            to mnv_dv_bi_elliptic(ship:periapsis, ship:apoapsis, tgtPe, tgtPe, tgtAp, ship:body)[1].
disp_info("DeltaV calculated").
local burnTime      to mnv_burn_times(dv, mnvTime).
disp_info("Burn times calculated").
local burnETA       to burnTime[0].
local burnDur       to burnTime[1].
local mnvNode       to node(mnvTime, 0, 0, dv).
disp_info("Maneuver DV Calculated").

set mnvNode to mnv_opt_simple_node(mnvNode, tgtPe, "pe").
add mnvNode.

disp_msg("Getting burn data").
disp_info("dv needed: " + round(dv, 2)).
disp_info2("Burn duration: " + round(burnDur, 1)).

for m in ship:modulesNamed("ModuleDeployableSolarPanel") 
{
    if m:part = "" panelList:add(m).
}

disp_msg("Measuring EC Drain rate").
disp_info().
disp_info2().
local ec to ship:electricCharge.
wait 1.
local ecRate to (ec - ship:electricCharge).
if ecRate < 0 set ecRate to 0.0001.
local ecSecs to ship:electricCharge / ecRate.
local span to burnETA + 60 - time:seconds.

disp_msg("EC drain rate calculations").
disp_info("ecSecsRemaining : " + round(ecSecs, 2) + "s     ").
disp_info2("timeToManeuver  : " + round(span, 2) + "s     ").
wait 0.25.

if span >= ecSecs
{
    disp_msg("EC drain rate warning! Mode: SolarPanelDeploy").
    ves_activate_solar(panelList, true).
    disp_hud("EC drain rate warning! Not enough EC until circularization", 1).
    disp_hud("Panels deployed").
    disp_info("Panels deployed").
}
wait 0.25.

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