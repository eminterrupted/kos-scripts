runOncePath("0:/kslib/lib_l_az_calc").
runOncePath("0:/lib/lib_launch").

// Mission Params
local tgtAp     to 225000.
local tgtPe     to 225000.
local tgtInc    to 75.
local tgtRoll   to choose 180 if ship:crewcapacity > 0 else 0.
local lazObj    to l_az_calc_init(tgtAp, tgtInc).   
local doReturn  to false.

local missionList  to list(
    "maneuver/power_comms_enable"
    ,"mission/relay_orbit"
    // "mission/simple_orbit"
    // ,"mission/sun_science"
    // ,"mission/auto_sci_biome"
    //,"maneuver/transfer_to_mun"
    //,"maneuver/wait_for_soi_change"
    //,"maneuver/capture_burn"
    //,"maneuver/change_inclination"
    //,"maneuver/change_orbit"
    //,"mission/orbital_science"
    // ,"mission/scansat"
    // ,"mission/suborbital_hop"
).

// Main
local launchPlanCache       to "local:/launchPlan.json".
local missionPlanCache      to "0:/data/archive/mp/missionPlan_" + ship:name:replace(" ","_") + ".json".
local missionPlanLocal      to "local:/missionPlan.json".
local reachOrbit            to choose true if tgtPe >= body:atm:height else false.

// Launch Planner
local launchQueue to queue().

if stage:number > 1 
{
    launchQueue:push("multiStage").
}
else
{
    launchQueue:push("singleStage").
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

// Mission planner
local missionPlan       to queue().
local missionParam      to lex().
local missionParamPath  to "local:/missionParam.json".

// Delegates
local ap to { return ship:apoapsis.}.
local argPe to { return ship:orbit:argumentOfPeriapsis.}.
local lan to { return ship:orbit:lan.}.
local pe to { return ship:periapsis.}.

// Mission queue
for script in missionList {
    missionPlan:push(script).

    if script = "maneuver/transfer_to_mun"
    {
        set missionParam["maneuver/transfer_to_mun"] to list(
            "Mun",
            30000,
            500000
        ).
    }
    else if script = "maneuver/capture_burn"
    {
        set missionParam["maneuver/capture_burn"] to list(
            pe
        ).
    }
    else if script = "maneuver/change_inclination"
    {
        set missionParam["maneuver/change_inclination"] to list(
            60,
            lan
        ).
    }
    else if script = "maneuver/change_orbit"
    {
        set missionParam["maneuver/change_orbit"] to list(
            pe,
            ap,
            argPe
        ).
    }
}
writeJson(missionParam, missionParamPath).

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
writeJson(list(ship:name), "local:/vessel.json").