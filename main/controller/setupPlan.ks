//#include "0:/boot/bootLoader"

runOncePath("0:/kslib/lib_l_az_calc").
runOncePath("0:/lib/lib_launch").
runOncePath("0:/lib/lib_util").

core:doAction("open terminal", true).
// print "Press 0 to begin launch plan setup".
// util_check_keypress(0).

// Global variables

// Mission Params
local tgtPe     to 500000.
local tgtAp     to 500000.
local tgtInc    to 0.
local tgtLAN    to -1.
local tgtRoll   to 0.
local doReturn  to false.
local waitForLAN to false.

if hasTarget 
{
    set tgtInc to target:orbit:inclination.
    set tgtLAN to target:orbit:lan.
    set waitForLAN to true.
}

local missionList to list(
    "mission/simple_orbit"
    //,"maneuver/kerbin_escape"
    //,"mission/simple_orbit"
    //,"maneuver/change_orbit"
    //,"maneuver/match_inclination"
    ,"maneuver/transfer_to_body"
    //,"maneuver/exec_node"
    ,"maneuver/wait_for_soi_change"
    ,"maneuver/capture_burn"
    // ,"mission/simple_orbit"
    // ,"land/land_on_mun"
    // ,"mission/land_sci"
    //,"maneuver/transfer_to_planet"
    //,"mission/clever_sat"
    //,"mission/orbital_science"
    //,"mission/simple_orbit"
    //,"maneuver/wait_for_soi_change"
    // ,"maneuver/capture_burn"
    // ,"launch/mun_ascent"
    ,"mission/simple_orbit"
    ,"maneuver/match_inclination"
    ,"maneuver/transfer_to_target"
    ,"mission/simple_orbit"
    ,"maneuver/kill_relative_velocity"
    ,"maneuver/dock_with_target"
    //,"return/return_from_mun"
    //,"maneuver/change_inclination"
    //,"mission/station_orbit"
    //,"maneuver/exec_node"
    // ,"maneuver/wait_for_soi_change"
    // ,"maneuver/transfer_to_planet"
    // ,"return/reentry"
    //,"maneuver/transfer_to_target"
    //,"maneuver/kill_relative_velocity"
    //,"mission/simple_orbit"
    //,"maneuver/wait_for_soi_change"
    //,"maneuver/capture_burn"
    //,"mission/simple_orbit"
    //,"mission/simple_orbit"
    //,"maneuver/exec_node"
    //,"mission/auto_sci_biome"
    //,"mission/recon"
    //,"mission/impact_target"
    //,"mission/deploy_payload"
    //,"maneuver/match_inclination"
    //,"misc/clear_bootscript"
    //,"maneuver/change_inclination"
    //,"maneuver/wait_for_soi_change"
    //,"maneuver/capture_burn"
    //,"maneuver/change_inclination"
    //,"maneuver/change_orbit"
    //,"mission/simple_orbit"
    //,"maneuver/change_inclination"
    //,"mission/simple_orbit"
    //,"maneuver/match_inclination"
    //,"land/rover_skycrane"
    //,"mission/scansat"
    //,"mission/relay_orbit"
    //,"mission/sun_science"
    //,"mission/mag_study"
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
    "tgtAp",        tgtAp,
    "tgtPe",        tgtPe,
    "tgtInc",       tgtInc,
    "tgtLAN",       tgtLAN,
    "waitForLAN",   waitForLAN,
    "tgtRoll",      tgtRoll,
    "lazObj",       l_az_calc_init(tgtAp, tgtInc),
    "queue",        launchQueue
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
    missionPlan:push("return/reentry").
}

// Write to cache, and local
writeJson(missionPlan, missionPlanCache).
writeJson(missionPlan, missionPlanLocal).

// Write the ship name to a local file to avoid issues with the Project Management mod
writeJson(list(ship:name), dataDisk + "vessel.json").