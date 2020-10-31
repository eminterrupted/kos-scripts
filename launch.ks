@lazyGlobal off.

parameter launchScript,
          obtScript,
          tApo,
          tPe,
          tInc,
          gravTurnAlt,
          refPitch.

runOncePath("0:/lib/lib_init.ks").

init_state_obj().

local program is stateObj["program"].
local runmode is stateObj["runmode"].

local function set_program {
    parameter n is 0.

    set program to n.
    set stateObj["program"] to n.
}

until program = 256 {
    
    local kPath is "0:/_mission/".
    local kscLaunchPath is kPath + "launch/" + launchScript.
    local kscPayloadPath is kPath + "orbit/" + obtScript.
    
    local lPath is "1:/".
    local localLaunchPath is lPath + launchScript.
    local localPayloadPath is lPath + obtScript.

    if exists(kscLaunchPath) copyPath(kscLaunchPath,localLaunchPath).
    else print "KscPath not found: " + kscLaunchPath.

    if exists(kscPayloadPath) copyPath(kscPayloadPath,localPayloadPath).
    else print "KscPath not found: " + kscPayloadPath.


    if  program = 0 {
        set_program(3).
    }

    else if program = 3 and ship:status = "PRELAUNCH" {
        ship:rootpart:getModule("kOSProcessor"):doAction("open terminal",true).
        tag_parts_by_title(ship:parts).
        uplink_telemetry().

        if exists(localLaunchPath) {
            runPath(localLaunchPath, tApo, tPe, tInc, gravTurnAlt, refPitch).
        }

        else {
            print "ShipPath not found: " + localLaunchPath.
            print "Running from KSC".
            runPath(kscLaunchPath, tApo, tPe, tInc, gravTurnAlt, refPitch ).
        }

        set_program(11).
    }

    else if program = 11 and ship:status = "ORBITING" {
        runPath(localPayloadPath).

        set_program(0).
    }

    else if program = 0 and ship:status = "ORBITING" {
        print "SCRIPT COMPLETE" at (0, 55).
    }
}
