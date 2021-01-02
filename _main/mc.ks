@lazyGlobal off.

clearScreen.

wait until ship:unpacked.
wait 2.

// Dependencies
runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/lib_tag").
runOncePath("0:/lib/lib_log").
runOncePath("0:/lib/display/lib_display").
runOncePath("0:/lib/lib_core").

// Paths
local kscPath is "0:/_main/".
local locPath is core:volume:name + ":/".

// Initialize the mission cache
local cache is init_mission_cache().

//-- Main --//
local program is stateObj["program"].
if program = 0 set_program("LAUNCH").

if program = "LAUNCH" {
    exec_launch().
    set_program("MISSION_S1").
}

set core:bootfilename to "local:/boot/mc".

if program = "MISSION_S1" {
    exec_mission(cache["missionS1"]).
    set_program("MISSION_S2").
}

if program = "MISSION_S2" {
    exec_mission(cache["missionS2"]).
    set_program("COMPLETED").
}
//-- End Main --//




// Functions
local function exec_launch {
    disp_main().

    // Get the launch script from cache and copy to the local volume
    local kscScrPath to kscPath + "/launch/" + cache["launchS1"].
    local locScrPath to locPath + cache["launchS1"].
    if not exists(locScrPath) compile(kscScrPath) to locScrPath.

    // Load the launch parameters from cache
    local lAp       to choose cache["lAp"]      if cache["lAp"]:isType("scalar")    else cache["lAp"]:toNumber.
    local lPe       to choose cache["lPe"]      if cache["lPe"]:isType("scalar")    else cache["lPe"]:toNumber.
    local lInc      to choose cache["lInc"]     if cache["lPe"]:isType("scalar")    else cache["lInc"]:toNumber.
    local lTAlt     to choose cache["lTAlt"]    if cache["lTAlt"]:isType("scalar")  else cache["lTAlt"]:toNumber.
    local rVal      to choose cache["rVal"]     if cache["rVal"]:istype("scalar")   else cache["rVal"]:toNumber.

    // Check if we are on a modular launch pad.
    if ship:partsTaggedPattern("mlp"):length > 0 {
        
        // Load the MLP lib
        runOncePath("0:/lib/part/lib_launchpad").
    
        // Activate generator on launch pad in case of hold
        mlp_gen_on().
        logStr("Vehicle on external power").

        // Activate fueling in case we forgot to fuel
        mlp_fuel_on().
        logStr("Vehicle fuel loading commenced").
        wait 1.
    }

    // Run the script
    runPath(locScrPath, lAp, lPe, lInc, lTAlt, rVal).

    // Delete the local copy of the launch script since it is no longer needed
    deletePath(locScrPath).

    return true.
}

local function exec_mission {
    parameter script.

    local kscScrPath to kscPath + "/mission/" + script.
    local locScrPath to locPath + script.
    if not exists(locScrPath) copyPath(kscScrPath, locScrPath).

    runPath(locScrPath).
    deletePath(locScrPath).
    return true.
}

local function set_program {
    parameter prog.

    set program to prog.
    set stateObj["program"] to prog.
    log_state(stateObj).
}