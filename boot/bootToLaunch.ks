clearScreen.

runOncePath("0:/lib/lib_init.ks").

init_state_obj().

local program is stateObj["program"].
local runmode is stateObj["runmode"].

until program = 256 {
    
    if  program = 0 {
        disp_main().
        disp_vessel_data().

        set program to 3.

    }

    else if program = 3 and ship:status = "PRELAUNCH" {
        ship:rootpart:getModule("kOSProcessor"):doAction("open terminal",true).
        tag_parts_by_title(ship:parts).
        uplink_telemetry().

        local missionScript is "thor/thor_3_launch"
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

        set program to 11.
    }

    else if program = 11 and ship:status = "ORBITING" {
        set program to 256.
    }
}