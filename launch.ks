parameter missionScript.

clearScreen.

runOncePath("0:/lib/lib_init.ks").

//set terminal:height to 40.
//set terminal:width to 60.
ship:rootpart:getModule("kOSProcessor"):doAction("open terminal",true).
tag_parts_by_title(ship:parts).
uplink_telemetry().

local kscPath is "0:/_mission/" + missionScript + ".ks".
local shipPath is "1:/_mission/" + missionScript + ".ks".

if exists(kscPath) copyPath(kscPath,shipPath).
else print "KscPath not found: " + kscPath.

if exists(shipPath) runPath(shipPath).
else {
    print "ShipPath not found: " + shipPath.
    print "Running from KSC".
    runPath(kscPath).
}