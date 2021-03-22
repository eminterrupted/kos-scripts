runOncePath("0:/kslib/lib_l_az_calc").
runOncePath("0:/lib/lib_launch").

// Mission Params
local tgtAp     to 150000.
local tgtPe     to 150000.
local tgtInc    to 0.
local lazObj    to l_az_calc_init(tgtAp, tgtInc).   
local doReturn  to false.

local missionList  to list(
    "/mission/simple_orbit"
    ,"/maneuver/transfer_to_mun"
    ,"/maneuver/capture_burn"
    ,"/maneuver/change_inclination"
    ,"/mission/scansat"
    //,"/mission/auto_sci_biome"
    //,"/mission/mun_transfer"
    //,"/mission/orbital_science"
    //,"/mission/relay_orbit"
    //,"/mission/suborbital_hop"
).

// Main
local launchCache  to "local:/launchPlan.json".
local missionCache to "local:/missionPlan.json".
local reachOrbit   to choose true if tgtPe >= body:atm:height else false.

// Launch Planner
local launchQueue to queue().
launchQueue:push("/launch/multiStage").
if reachOrbit launchQueue:push("/launch/circ_burn").

local launchPlan to lex(
    "tgtAp",  tgtAp,
    "tgtPe",  tgtPe,
    "tgtInc", tgtInc,
    "lazObj", lazObj,
    "queue",  launchQueue
).
writeJson(launchPlan, launchCache).

// Mission planner
local missionQueue to queue().

// Mission queue
for script in missionList {
    missionQueue:push(script).
}

if not reachOrbit
{
    missionQueue:push("/return/suborbital_reentry").
}
else if doReturn
{
    missionQueue:push("/return/ksc_reentry").
}
else 
{
    missionQueue:push("/return/no_return").
}
writeJson(missionQueue, missionCache).