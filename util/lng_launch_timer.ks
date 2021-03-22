// Script to run on a second core during a relay test launch
// to find the amount of time and phase advancement during 
// launch. Use to find optimal launch windows for constellations
@lazyGlobal off.
clearScreen.

runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_nav").

local upload to false.

local shipNameTrimmed to ship:name:replace(" ", "_"):remove(ship:name:length - 2, 2).
local arcLog to "0:/log/relay_planner_" + shipNameTrimmed + ".log".
local logPath to "1:/log/relay_planner_" + shipNameTrimmed + ".log".
if exists(logPath) deletePath(logPath).

log "Relay Type: " + shipNameTrimmed to logPath.
log " " to logPath.

print "Waiting for launch".
print " ".

until ag8
{
    print "Current longitude: " + round(nav_lng_to_degrees(ship:longitude), 3) + "   " at (0, 9).
    wait 0.01.
}

local launchTime    to time:seconds.
local myLaunchLng   to nav_lng_to_degrees(ship:longitude).

clearScreen.

log "Liftoff timestamp: " + launchTime to logPath.
log "Vessel launch longitude: " + myLaunchLng to logPath.
log " " to logPath.

print "Liftoff at " + time:full.
print "Vessel longitude at liftoff : " + myLaunchLng.
print " ".

until ag9
{
    wait 0.01.
}

local arrivalTime   to time:seconds.
local myArrivalLng  to nav_lng_to_degrees(ship:longitude).
local myLngDiff     to myArrivalLng - myLaunchLng.

print "Arrival on orbit at " + time:full.
print "Vessel longitude at arrival : " + myArrivalLng.
print " ".
print "Time eclipsed: " + (arrivalTime - launchTime).
print "Vessel longitude covered: " + myLngDiff.

if upload 
{
    print "Waiting for KSC connection to upload log...".
    wait until addons:rt:hasKscConnection(ship).
    print "Connection established".

    copyPath(logPath, arcLog).
    if exists(arcLog) 
    {
        print "Log upload complete".
    }
    else 
    {
        print "Log upload failed! Please try manually".
    }
}