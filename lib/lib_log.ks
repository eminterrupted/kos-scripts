//Initiates the log files
@lazyGlobal off.

init_log().
local uplinkObj to init_uplink().

//tee - set to 1 to echo log lines to console
local tee is 0.


//-- local functions --//

local function init_log {
    
    set errLvl to 0.
    local diskObj is init_disk().
    local logDisk is choose diskObj["log"]:name if diskObj:hasKey("log") else diskObj["local"]:name.

    local logFile is shipName:replace(" ","_").
    local logFolderLast is logFile:findLast("_").
    local logFolder is logFile:remove(logFolderLast, logFile:length - logFolderLast).

    global localLog is logDisk + ":/" + logFile + ".log".
    global kscLog is "Archive:/logs/" + logFolder + "/" + logFile + ".log".
    
    if not (exists(kscLog)) {
        create(kscLog).
        local kscFile to open(kscLog).
        kscFile:writeLn("[MET:" + round(missionTime,3) + "][INFO] KSCLog initialized").
    } 

    else if ship:status = "PRELAUNCH" {
        deletePath(kscLog).
        create(kscLog).
        local kscFile to open(kscLog).
        kscFile:writeLn("[MET:" + round(missionTime,3) + "][INFO] KSCLog initialized").
    }

    else {
        set errLvl to 1.
        local kscFile to open(kscLog).
        kscFile:writeLn("[MET:" + round(missionTime,3) + "][INFO] KSCLog re-initialized").
    }

    if not (exists(localLog)) {
        create(localLog).
        local localFile to open(localLog).
        localFile:writeLn("[MET:" + round(missionTime,3) + "][INFO] localLog initialized").
    }
    
    else {
        set errLvl to 1.
        local localFile to open(localLog).
        localFile:writeLn("[MET:" + round(missionTime,3) + "][INFO] localLog re-initialized").
    }
}


// Initializes the uplink object.
local function init_uplink {
    local lastUplink is time:seconds.
    local nextUplink is time:seconds + 15.
    
    return lex("lastUplink", lastUplink, "nextUplink", nextUplink).
}


//-- Main function--// 
global function logStr {
    
    parameter str,
              logLvl is 0,
              uplink is false.
    
    if not (defined localLog) init_log().

    local logFile is open(localLog).
    
    local lvlStr is "[INFO] ".
    if logLvl = 1 set lvlStr to "[WARN] ".
    if logLvl = 2 set lvlStr to "[*ERR] ".

    local timestamp is 0.
    if missionTime = 0 and defined cd set timestamp to 0 - cd.
    else set timestamp to missionTime.

    if logLvl >= 0 {       
        set str to "[MET:" + round(timestamp, 3) + "]" + lvlStr + str.

        if tee = 0 {
            logFile:writeLn(str).
        }
    
        else if tee = 1 {
            print str.
            logFile:writeLn(str). 
        }

        else if tee = 2 {
            print str.
        }
    }
    
    if (path(localLog):volume):freeSpace < 1000 {
        uplink_telemetry().
    } else if time:seconds > uplinkObj["nextUplink"] {
        uplink_telemetry().
    } else if uplink {
        uplink_telemetry().
    }
}


//Uploads the log file to KSC if connection is present.
global function uplink_telemetry {

    parameter fromLog is localLog.
    parameter toLog is kscLog.

    local conFlag is false. 
    local fromOpen is open(fromLog).
    local fromContent is "".
    local toOpen is open(toLog).

    if addons:rt:hasKscConnection(ship) set conFlag to true.

    if conFlag { 
        set fromContent to fromOpen:readAll:string.
        toOpen:write(fromContent).
        wait 0.05.
        fromOpen:clear().
    }

    else {
        set errLvl to 2.
        return errLvl.
    }

    set uplinkObj to lex("lastUplink", time:seconds, "nextUplink", time:seconds + 15).

    if path(fromLog):volume:freeSpace < 100 set errLvl to 2.
    else set errLvl to 0.

    return errLvl.
}