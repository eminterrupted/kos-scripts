runOncePath("0:/lib/lib_init.ks").

init_state_obj().

local program is stateObj["program"].
local runmode is stateObj["runmode"].
local missionScript is "thor/thor_3_launch".

until program = 256 {
    
    if  program = 0 {
        set_program(3).
    }

    else if program = 3 and ship:status = "PRELAUNCH" {
        ship:rootpart:getModule("kOSProcessor"):doAction("open terminal",true).
        tag_parts_by_title(ship:parts).
        uplink_telemetry().

        local kscPath is "0:/_mission/" + missionScript + ".ks".
        local shipPath is "1:/_mission/" + missionScript + ".ks".

        if exists(kscPath) copyPath(kscPath,shipPath).
        else print "KscPath not found: " + kscPath.

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
        set_program(256).
    }
}


local function set_program {
    parameter n is 0.

    set program to n.
    set stateObj["program"] to n.
}