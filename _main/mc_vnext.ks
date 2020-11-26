@lazyGlobal off.

set config:ipu to 500.

clearScreen.

runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/lib_log").
runOncePath("0:/lib/lib_display").
init_uplink().

runOncePath("0:/lib/lib_tag").
if ship:partsTaggedPattern("mlp"):length > 0 runOncePath("0:/lib/part/lib_launchpad").

//Set up the state object used to track program progress. Allows for resuming the mission in event of power loss.
local stateObj is init_state_obj().
local program is stateObj["program"].



//Load from cache
local cache is choose readJson("local:/launchSelectCache.json") if exists("local:/launchSelectCache.json") else readJson("0:/data/launchSelectCache.json").

local launchScript to cache["launchS1"].
local missionScript to cache["missionS1"].
local endScript to cache["missionS2"].

local tApo to choose cache["tApo"] if cache["tApo"]:isType("scalar") else cache["tApo"]:toNumber.
local tPe to choose cache["tPe"] if cache["tPe"]:isType("scalar") else cache["tPe"]:toNumber.
local tInc to choose cache["tInc"] if cache["tPe"]:isType("scalar") else cache["tInc"]:toNumber.
local gtAlt to choose cache["gtAlt"] if cache["gtAlt"]:isType("scalar") else cache["gtAlt"]:toNumber.
local gtPitch to choose cache["gtPitch"] if cache["gtPitch"]:istype("scalar") else cache["gtPitch"]:toNumber.
local rVal to choose cache["rVal"] if cache["rVal"]:istype("scalar") else cache["rVal"]:toNumber.

//Paths
local rProc to ship:rootpart:getModule("kOSProcessor").
local kscPath is "0:/_main/".
local locPath is rProc:volume:name + ":/".


//Main
if program = 0 set_program("LAUNCH").

if program = "LAUNCH" {
    exec_launch(launchScript).
    set_program("MISSION_S1").
}

if program = "MISSION_S1" {
    exec_mission(missionScript).
    set_program("MISSION_S2").
}

if program = "MISSION_S2" {
    exec_mission(endScript).
    set_program("COMPLETED").
}


//Functions
local function exec_launch {
    parameter script.

    disp_launch_main().
    wait 1.
    //Activate generator on launch pad in case of hold
    mlp_gen_on().
    logStr("Vehicle on external power").
    wait 1.
    //Activate fueling in case we forgot to fuel
    mlp_fuel_on().
    logStr("Vehicle fuel loading commenced").
    wait 1.

    local kscScrPath to kscPath + "/launch/" + script.
    local locScrPath to locPath + script.
    if not exists(locScrPath) compile(kscScrPath) to locScrPath.

    runPath(locScrPath, tApo, tPe, tInc, gtAlt, gtPitch, rVal).

    return true.
}

local function exec_mission {
    parameter script.

    local kscScrPath to kscPath + "/mission/" + script.
    local locScrPath to locPath + script.
    if not exists(locScrPath) copypath(kscScrPath, locScrPath).

    runPath(locScrPath).

    return true.
}

local function set_program {
    parameter prog.

    set program to prog.
    set stateObj["program"] to prog.
    log_state(stateObj).
}