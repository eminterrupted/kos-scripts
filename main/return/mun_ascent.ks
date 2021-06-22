@lazyGlobal off.
clearScreen.

parameter ascentAlt is 25000, 
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

for s in ship:modulesNamed("ModuleDeployableSolarPanel")
{
    ves_activate_solar(s, false).
}

when alt:radar > 100 then
{
    stage.
}

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

runPath("0:/main/controller/launchController").

for s in ship:modulesNamed("ModuleDeployableSolarPanel")
{
    ves_activate_solar(s, true).
}