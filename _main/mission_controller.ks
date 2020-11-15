@lazyGlobal off.

parameter launchScript is ""
          ,missionScript is ""
          ,tApo is ""
          ,tPe is ""
          ,tInc is ""
          ,gtAlt is ""
          ,gtPitch is "".

set config:ipu to 500.

clearScreen.

runOncePath("0:/lib/lib_init.ks").

local stateObj is init_state_obj().
local runmode is stateObj["runmode"].
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
        parameter n is 0.

        set program to n.
        set stateObj["program"] to n.
    }
    
    local kPath is "0:/_main/".
    local kscLaunchPath is kPath + "launch/" + launchScript.
    local kscPayloadPath is kPath + "mission/" + missionScript.
    
    local lPath is "local:/".
    local localLaunchPath is lPath + launchScript.
    local localPayloadPath is lPath + missionScript.

    if exists(kscLaunchPath) copyPath(kscLaunchPath,localLaunchPath).
    else logStr("KscPath not found: " + kscLaunchPath).

    if exists(kscPayloadPath) copyPath(kscPayloadPath,localPayloadPath).
    else logStr("KscPath not found: " + kscPayloadPath).

    if  program = 0 {
        set_program(3).
    }

    else if program = 3 and (ship:status = "PRELAUNCH" or ship:status = "FLYING" or ship:status = "SUB_ORBITAL") {

        ship:rootpart:getModule("kOSProcessor"):doAction("open terminal",true).
        
        uplink_telemetry().

        if exists(localLaunchPath) {
            logStr("Executing launch script: " + localLaunchPath).
            runPath(localLaunchPath, tApo, tPe, tInc, gtAlt, gtPitch).
        }

        else {
            logStr("ShipPath not found: " + localLaunchPath).
            logStr("Running from KSC").
            runPath(kscLaunchPath, tApo, tPe, tInc, gtAlt, gtPitch ).
        }

        set_program(11).
    }

    else if program = 3 and runmode < 28 and ship:status = "ORBITING" {
        set_program(11).
    }

    else if program = 11 and ship:status = "ORBITING" {
        if exists(localPayloadPath) {
            logStr("Executing mission script: " + localPayloadPath).
            runPath(localPayloadPath).
        } else {
            logStr("ShipPath not found: " + localPayloadPath).
            logStr("Running from KSC").
            runPath(kscPayloadPath).
        }
        

        set_program(255).
    }

    else if program = 255 and ship:status = "ORBITING" {
        print "SCRIPT COMPLETE" at (2, 55).
    }
}
