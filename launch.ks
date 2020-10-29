runOncePath("0:/lib/lib_init.ks").

init_state_obj().

local program is stateObj["program"].
local runmode is stateObj["runmode"].
local launchScript is "thor/thor_2d_launch.ks".
local payloadScript is "payload/relsat_deploy.ks".

local function set_program {
    parameter n is 0.

    set program to n.
    set stateObj["program"] to n.
}

until program = 256 {
    
    local kPath is "0:/_mission/".
    local kscLaunch is kPath + launchScript.
    local kscPayload is kPath + payloadScript.
    
    local sPath is "1:/_mission/".
    local localLaunch is sPath + launchScript.
    local localPayload is sPath + payloadScript.

    if exists(kscLaunch) copyPath(kscLaunch,localLaunch).
    else print "KscPath not found: " + kscLaunch.

    if exists(kscPayload) copyPath(kscPayload,localPayload).
    else print "KscPath not found: " + kscPayload.


    if  program = 0 {
        set_program(3).
    }

    else if program = 3 and ship:status = "PRELAUNCH" {
        ship:rootpart:getModule("kOSProcessor"):doAction("open terminal",true).
        tag_parts_by_title(ship:parts).
        uplink_telemetry().

        local kscPath is kPath + launchScript.
        local shipPath is sPath + launchScript.


        if exists(shipPath) {
            runPath(shipPath).
        }

        else {
            print "ShipPath not found: " + shipPath.
            print "Running from KSC".
            runPath(kscPath).
        }

        set_program(11).
    }

    else if program = 11 and ship:status = "ORBITING" {
        lock steering to ship:prograde.
        runPath(localPayload).

        set_program(0).
    }

    else if program = 0 and ship:status = "ORBITING" {
        print "SCRIPT COMPLETE" at (0, 55).
    }
}
