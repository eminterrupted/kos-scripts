//#include "0:/boot/bootLoader"

runOncePath("0:/kslib/lib_l_az_calc").
runOncePath("0:/lib/lib_launch").

// Global variables

// Mission Params
local tgtAp     to 325000.
local tgtPe     to 325000.
local tgtInc    to 0.
//local tgtRoll   to choose 180 if ship:crewcapacity > 0 else 0.
local tgtRoll   to 0.
local lazObj    to l_az_calc_init(tgtAp, tgtInc).
local doReturn  to false.

local missionList to list(
    "mission/simple_orbit"
    //,"mission/auto_sci_biome"
    ,"maneuver/match_inclination"
    ,"maneuver/transfer_to_mun"
    ,"maneuver/wait_for_soi_change"
    ,"maneuver/capture_burn"
    //,"maneuver/change_inclination"
    ,"maneuver/change_orbit"
    ,"land/land_on_mun"
    ,"mission/land_sci"
    //,"mission/scansat"
    //,"return/mun_ascent"
    //,"mission/simple_orbit"
    //,"return/return_from_mun"
    //,"mission/relay_orbit"
    //,"maneuver/kerbin_escape"
    //,"mission/sun_science"
    //,"mission/mag_study"
    //,"mission/orbital_science"
    //,"mission/simple_orbit"
    //,"mission/suborbital_hop"
).

// Main
local launchPlanCache       to dataDisk + "launchPlan.json".
local missionPlanCache      to "0:/data/archive/mp/missionPlan_" + ship:name:replace(" ","_") + ".json".
local missionPlanLocal      to dataDisk + "missionPlan.json".
local reachOrbit            to choose true if tgtPe >= body:atm:height else false.

// Launch Planner
local launchQueue to queue().

if ship:status = "PRELAUNCH" or ship:status = "LANDED"
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

if reachOrbit 
{
    if career():canMakeNodes launchQueue:push("circ_burn_node").
    else launchQueue:push("circ_burn_simple").
}

local launchPlan to lex(
    "tgtAp",  tgtAp,
    "tgtPe",  tgtPe,
    "tgtInc", tgtInc,
    "tgtRoll",tgtRoll,
    "lazObj", lazObj,
    "queue",  launchQueue
).
writeJson(launchPlan, launchPlanCache).

// Copy power/comms script to local drive
download("/maneuver/power_comms_enable").

// Mission planner
local missionPlan to queue().

// Mission queue
for script in missionList {
    missionPlan:push(script).
}

if not reachOrbit
{
    missionPlan:push("return/suborbital_reentry").
}
else if doReturn
{
    missionPlan:push("return/ksc_reentry").
}

// Write to cache, and local
writeJson(missionPlan, missionPlanCache).
writeJson(missionPlan, missionPlanLocal).

// Write the ship name to a local file to avoid issues with the Project Management mod
writeJson(list(ship:name), dataDisk + "vessel.json").