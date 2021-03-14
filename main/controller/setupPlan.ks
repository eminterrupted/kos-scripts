runOncePath("0:/kslib/lib_l_az_calc").
runOncePath("0:/lib/lib_launch").

// Mission Params
local tgtAp        to 125000.
local tgtPe        to 125000.
local tgtInc       to 0.
local returnFlag   to true.

local missionList  to list(
    "/mission/simple_orbit"
    //"/mission/auto_sci_biome"
    //"/mission/mun_transfer"
    //"/mission/orbital_science"
    //"/mission/relay_orbit"
    //"/mission/scansat"
    //"/mission/suborbital_hop"
).

// Main
local launchCache  to "local:/launchPlan.json".
local missionCache to "local:/missionPlan.json".

// Launch Planner
local launchQueue to queue().
launchQueue:push("/launch/multiStage_vNext").
if tgtPe >= body:atm:height launchQueue:push("/maneuver/circ_burn_vNext").

local lazObj to l_az_calc_init(tgtAp, tgtInc).
local launchPlan to lex(
    "tgtAp",  tgtAp,
    "tgtPe",  tgtPe,
    "tgtInc", tgtInc,
    "lazObj", lazObj,
    "queue", launchQueue
).
writeJson(launchPlan, launchCache).

// Mission planner
local missionQueue to queue().

// Mission queue
for script in missionList {
    missionQueue:push(script).
}

if tgtPe < body:atm:height
{
    missionQueue:push("/return/suborbital_reentry").
}
else if returnFlag 
{
    missionQueue:push("/return/ksc_reentry").
}
else 
{
    missionQueue:push("/return/no_return").
}
writeJson(missionQueue, missionCache).