@lazyGlobal off.

//#include "0:/boot/bootLoader.ks"

runOncePath("0:/kslib/lib_l_az_calc").
runOncePath("0:/lib/lib_launch").

runPath("0:/main/setup/missionPlan").

// Plans
local missionCache to readJson(path("0:/data/cache/missionCache.json")).

// Mission Plan & Params
local missionPlan   to missionCache:missionPlan.
local launchParam   to missionCache:launchParam.

// Main
local launchPlanLocal       to path(dataDisk + "launchPlan.json").
local missionPlanCache      to path("0:/data/archive/mp/missionPlan_" + ship:name:replace(" ","_") + ".json").
local missionPlanLocal      to path(dataDisk + "missionPlan.json").

// Launch Plan setup
local launchQueue to queue().

if stage:number > 1 
{
    launchQueue:push("multiStage").
}
else
{
    launchQueue:push("singleStage").
}

if ship:body:atm:exists
{
    // launchPe
    if launchParam[0] >= ship:body:atm:height 
    {
        if career():canMakeNodes 
        {
            launchQueue:push("circ_burn_node").
        }
        else
        {
            launchQueue:push("circ_burn_simple").
        }
    }
    else
    {
        launchQueue:push("suborbital_reentry").
    }
}


local launchPlan to lex(
    "queue", launchQueue,
    "param", launchParam
).
writeJson(launchPlan, launchPlanLocal).

// Mission plan setup
local missionQueue to queue().
for mission in missionPlan
{
    missionQueue:push(mission).
}
writeJson(missionQueue, missionPlanCache).
copyPath(missionPlanCache, missionPlanLocal).

// Write the ship name to a local file to avoid issues with the Project Management mod
writeJson(list(ship:name), dataDisk + "vessel.json").