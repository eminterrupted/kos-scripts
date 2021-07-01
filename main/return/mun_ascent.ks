@lazyGlobal off.
clearScreen.

parameter ascentAlt is 50000, 
          ascentInc is 0.

runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_launch").
runOncePath("0:/lib/lib_vessel").
runOncePath("0:/kslib/lib_l_az_calc").

// Variables
local dataDisk to choose "1:/" if not (defined dataDisk) else dataDisk.
local launchPlanCache to dataDisk + "launchPlan.json".
local launchQueue to queue().
local engList to list().

list engines in engList.
for e in engList 
{
    if e:stage = stage:number e:activate.
}

ves_activate_solar(ship:modulesNamed("ModuleDeployableSolarPanel"), false).

// Main
if ship:status = "LANDED"
{
    if stage:number > 1 
    {
        launchQueue:push("multiStage").
    }
    else
    {
        launchQueue:push("singleStage").
    }
}

if career():canMakeNodes 
{
    launchQueue:push("circ_burn_node").
}
else 
{
    launchQueue:push("circ_burn_simple").
}

local launchPlan to lex(
    "tgtAp",  ascentAlt,
    "tgtPe",  ascentAlt,
    "tgtInc", ascentInc,
    "tgtRoll",0,
    "lazObj", l_az_calc_init(ascentAlt, ascentInc),
    "queue",  launchQueue
).
writeJson(launchPlan, launchPlanCache).

ship:deltaV:forcecalc.
disp_hud("Forcing dV recalc for stage: " + stage:number).
wait 2.5.
if stage:number > 2 and stage:deltaV:current > 500
{
    when alt:radar > 50 then
    {
        stage.
    }
}

runPath("0:/main/controller/launchController").
deletePath(launchPlanCache).
ves_activate_solar(ship:modulesNamed("ModuleDeployableSolarPanel"), true).
