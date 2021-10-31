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
local cellList      to list().
local panelList     to list().
disp_info("Variables set").

// Control
local rVal          to launchPlan:tgtRoll.
local sVal          to lookDirUp(ship:facing:vector, sun:position) + r(0, 0, rVal).
local tVal          to 0.
lock steering       to sVal.
lock throttle       to tVal.
disp_info("Controls set").

// Main

// If a node exists, make sure it is past apoapsis so as not to confuse anything
if hasNode 
{
    if nextNode:time <= time:seconds + eta:apoapsis 
    {
        local n to node(time:seconds + eta:apoapsis + 60, nextNode:normal, nextNode:radialout, nextNode:prograde).
        remove nextNode.
        add n.
    }
}

// Get dv and duration of burn
local dv        to mnv_dv_bi_elliptic(ship:periapsis, ship:apoapsis, tgtPe, tgtPe, tgtAp, ship:body)[1].
disp_info("DeltaV calculated").

local mnvNode   to node(mnvTime, 0, 0, dv).
disp_info("Maneuver DV Calculated").

set mnvNode to mnv_opt_simple_node(mnvNode, tgtPe, "pe").
add mnvNode.

disp_msg("Getting burn data").
disp_info("dv needed: " + round(dv, 2)).
//disp_info2("Burn duration: " + round(fullDur, 1)).

for m in ship:modulesNamed("ModuleDeployableSolarPanel") 
{
    if m:part:tag = "" panelList:add(m).
}

for m in ship:modulesNamed("ModuleResourceConverter")
{
    if m:part:tag = "" and m:hasEvent("start fuel cell") cellList:add(m).
}

//Check to see if our EC will run out prior to the burn. If yes, activate panels.
disp_msg("Measuring EC Drain rate").
disp_info().
disp_info2().
local ec to ship:electricCharge.
wait 1.
local ecRate to (ec - ship:electricCharge).
if ecRate <= 0 set ecRate to 0.0001.
local ecSecs to ship:electricCharge / ecRate.

if mnvNode:eta >= ecSecs
{
    disp_tee("CAUTION: EC drain rate", 1).
    disp_info("EC Remaining: " + round(ecSecs, 2) + "s | Node ETA: " + round(mnvNode:eta, 2) + "s").
    if cellList:length > 0 
    {
        disp_tee("Starting fuel cell").
        ves_activate_fuel_cell(cellList[0]).
        disp_info2("Fuel cell started").
    }
    else if panelList:length > 0 
    {
        disp_tee("Deploying panels", 1).
        ves_activate_solar(panelList, true).
        disp_info2("Panels deployed").
    }
    else
    {
        disp_tee("MASTER CAUTION: No power source on board!").
        wait 2.5.
    }
}
else
{
    disp_msg("EC Drain rate test passed").
}

when ship:maxThrust <= 0.1 and throttle > 0 then 
{
    disp_info("Staging").
    ves_safe_stage().
    disp_info().
    if stage:number > 0 preserve.
}

mnv_exec_node_burn(mnvNode).

disp_msg("Maneuver complete!").
wait 1.

if hasNode remove nextNode.
clearScreen.
//-- End Main --//