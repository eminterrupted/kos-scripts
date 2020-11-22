//Initiates the log files
@lazyGlobal off.

runOncePath("0:/lib/lib_init.ks").

//uplink trigger
global lastUplink is time:seconds.
global nextUplink is time:seconds + 60.

//tee - set to 1 to echo log lines to console
local tee is 0.

//Log initialization
initialize_log().


//-- local functions --//

local function initialize_log {
    
    set errLvl to 0.
    local diskObj is init_disk().
    local logDisk is choose diskObj["log"]:name if diskObj:hasKey("log") else diskObj["local"]:name.

    local logFile is shipName:replace(" ","_").
    local logFolderLast is logFile:findLast("_").
    local logFolder is logFile:remove(logFolderLast, logFile:length - logFolderLast).

    global localLog is logDisk + ":/logs/" + logFile + ".log".
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

    when (path(localLog):volume):freeSpace < 1000 then uplink_telemetry().
}


//Uploads the log file to KSC if connection is present.
global function uplink_telemetry {

    parameter fromLog is localLog.
    parameter toLog is kscLog.
    
    local conFlag is false. 
    local fromOpen is open(fromLog).
    local fromContent is "".
    local toOpen is open(toLog).
    local uplinkLog is path(kscLog):parent + "/uplink.log".
    local uplinkObj is lexicon().

    if addons:rt:available {
        if addons:rt:hasKscConnection(ship) set conFlag to true.
    }

    if conFlag = true { 
        //logStr(time + " Telemetry uplink").
        set fromContent to fromOpen:readAll:string.
        toOpen:write(fromContent).
        wait 0.05.
        fromOpen:clear().
    }

    else {
        set errLvl to 2.
        //logStr("No connection to KSC, unable to uplink",errLvl).
        return errLvl.
    }

    set lastUplink to time:seconds.
    set nextUplink to time:seconds + 15.

    uplinkObj:add("lastUplink",lastUplink).
    uplinkObj:add("nextUplink",nextUplink).

    writeJson(uplinkObj,uplinkLog).

    if path(fromLog):volume:freeSpace < 250 set errLvl to 2.
    else set errLvl to 0.

    return errLvl.
}



//-- Main function--// 
global function logStr {
    
    parameter str,
              logLvl is 0.
    
    if not (defined localLog) initialize_log().

    local logFile is open(localLog).
    
    local lvlStr is "[INFO] ".
    if logLvl = 1 set lvlStr to "[WARN] ".
    if logLvl = 2 set lvlStr to "[*ERR] ".

    if logLvl >= 0 {            
        set str to "[MET:" + round(missionTime,3) + "]" + lvlStr + str.

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
    
    //if (path(localLog):volume):freeSpace < 1000 uplink_telemetry().
}