@lazyGlobal off.

parameter launchScript is ""
          ,missionScript is ""
          ,reentryScript is ""
          ,tApo is ""
          ,tPe is ""
          ,tInc is ""
          ,gtAlt is 50000
          ,gtPitch is 0
          ,rVal is 180.

set config:ipu to 500.

clearScreen.

runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/lib_log").

local stateObj is init_state_obj().
local program is stateObj["program"].

local cache is choose readJson("local:/launchSelectCache.json") if exists("local:/launchSelectCache.json") else readJson("0:/data/launchSelectCache.json").
if launchScript = "" set launchScript to cache["launchScript"].
if missionScript = "" set missionScript to cache["missionScript"].

if tApo:isType("String") set tApo to choose tApo:tonumber if tApo <> "" else cache["tApo"].
if tPe:isType("String") set tPe to choose tPe:tonumber if tPe <> "" else cache["tPe"].

if tInc:isType("String") set tInc to choose cache["tInc"] if tInc = "" else tInc:tonumber.
if gtAlt:istype("String") set gtAlt to choose cache["gtAlt"] if gtAlt = "" else gtAlt:toNumber.
if gtPitch:istype("String") set gtPitch to choose cache["gtPitch"] if gtPitch = "" else gtPitch:tonumber.

until program = 255 {
    
    local function set_program {
        parameter scr.

        set program to scr.
        set stateObj["program"] to scr.
        log_state(stateObj).
    }
    
    local kPath is "0:/_main/".
    local kscLaunchPath is kPath + "launch/" + launchScript.
    local kscPayloadPath is kPath + "mission/" + missionScript.
    local kscReentryPath is kPath + "reentry/" + reentryScript.
    
    local lPath is "local:/".
    local localLaunchPath is lPath + launchScript.
    local localPayloadPath is lPath + missionScript.
    local localReentryPath is lPath + reentryScript.

    if not exists(localPayloadPath) if exists(kscPayloadPath) copyPath(kscPayloadPath,localPayloadPath).
    if not exists(localReentryPath) if exists(kscReentryPath) copyPath(kscReentryPath,localReentryPath).
    
    if  program = 0 {
        set_program("LAUNCH").
    }

    else if program = "LAUNCH" and (ship:status = "PRELAUNCH" or ship:status = "LANDED" or ship:status = "FLYING" or ship:status = "SUB_ORBITAL") {
        if not exists(localLaunchPath) if exists(kscLaunchPath) compile(kscLaunchPath) to localLaunchPath.
        ship:rootpart:getModule("kOSProcessor"):doAction("open terminal",true).
        
        //uplink_telemetry().

        if exists(localLaunchPath) {
            logStr("Executing launch script: " + localLaunchPath).
            runPath(localLaunchPath, tApo, tPe, tInc, gtAlt, gtPitch, rVal).
        }

        else {
            logStr("ShipPath not found: " + localLaunchPath).
            logStr("Running from KSC").
            runPath(kscLaunchPath, tApo, tPe, tInc, gtAlt, gtPitch, rVal).
        }

        set_program("MISSION").
        if exists(localLaunchPath) deletePath(localLaunchPath).

        if exists(kscReentryPath) copyPath(kscReentryPath,localReentryPath).
        else logStr("KscPath not found: " + kscReentryPath).
    }

    else if program = "LAUNCH" and ship:status = "ORBITING" {
        logStr("Switching to missionscript").
        set_program("MISSION").
        
        if exists(localLaunchPath) deletePath(localLaunchPath).

        if exists(kscReentryPath) copyPath(kscReentryPath,localReentryPath).
        else logStr("KscPath not found: " + kscReentryPath).
    }

    else if program = "MISSION" {
        if exists(localPayloadPath) {
            logStr("Executing mission script: " + localPayloadPath).
            runPath(localPayloadPath, rVal).
        } else {
            logStr("ShipPath not found: " + localPayloadPath).
            logStr("Running from KSC").
            runPath(kscPayloadPath, rVal).
        } 

        set_program("REENTRY").
        
        if exists(localLaunchPath) deletePath(localLaunchPath).

        if exists(kscReentryPath) copyPath(kscReentryPath,localReentryPath).
        else logStr("KscPath not found: " + kscReentryPath).
    }

    else if program = "REENTRY" {
        if exists(localReentryPath) {
            logStr("Executing mission script: " + localReentryPath).
            runPath(localReentryPath, rVal).
        } else {
            logStr("ShipPath not found: " + localReentryPath).
            logStr("Running from KSC").
            runPath(kscReentryPath, rVal).
        }

        set_program(255).
    }

    else if program = 255 {
        logStr("Mission completed").
        print "SCRIPT COMPLETE" at (2, 55).
    }
}
