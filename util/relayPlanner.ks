// Script to run on a second core during a relay test launch
// to find the amount of time and phase advancement during 
// launch. Use to find optimal launch windows for constellations
@lazyGlobal off.
clearScreen.

runOncePath("0:/lib/disp").
runOncePath("0:/lib/nav").

local upload to true.
local launchPhase to 87.172.

local shipNameTrimmed to ship:name:replace(" ", "_"):remove(ship:name:length - 2, 2).
local arcLog to "0:/log/relay_planner_" + shipNameTrimmed + ".log".
local logPath to "1:/log/relay_planner_" + shipNameTrimmed + ".log".
if exists(logPath) deletePath(logPath).

log "Relay Type: " + shipNameTrimmed to logPath.
log " " to logPath.

print "Waiting for target vessel selection".
until hasTarget
{
    wait 0.1.
}
print "Target selected: " + target.

print "Waiting for launch".
print " ".

lock tgtPhase to LngToPhaseAng(target).
print "Desired phase angle at launch: " + launchPhase at (0, 8).
until tgtPhase >= mod((launchPhase + 360) - 2.5, 360) and tgtPhase < launchPhase 
{
    print "Target phase angle: " + round(tgtPhase, 3) + "   " at (0, 9).
    print "In the first loop" at (0, 11).
    wait 0.01.
}

if warp > 0 set warp to 0.
print "                          " at (0, 11).
print "Approaching launch phase" at (0, 6).

until false
{
    if tgtPhase >= launchPhase - 0.35 break.
    print "Target phase angle: " + round(tgtPhase, 3) + "   " at (0, 9).
    wait 0.01.
}
ag10 on.
if warp > 0 set warp to 0.
print "Initiating launch sequence" at (0, 6).
until ag8
{
  print "Target phase angle: " + round(tgtPhase, 3) + "   " at (0, 9).
  wait 0.01.
}

local launchTime    to time:seconds.
local myLaunchLng   to LngToDegress(ship:longitude).
local tgtLaunchLng  to LngToDegress(target:longitude).
local phaseAtLiftoff to mod(tgtLaunchLng - myLaunchLng + 360, 360).

clearScreen.

log "Liftoff timestamp: " + launchTime to logPath.
log "Vessel launch longitude: " + myLaunchLng to logPath.
log "Target launch longitude: " + tgtLaunchLng to logPath.
log "Phase angle at liftoff : " + phaseAtLiftoff to logPath.
log " " to logPath.

print "Liftoff at " + time:full.
print "Vessel longitude at liftoff : " + myLaunchLng.
print "Target longitude at liftoff : " + tgtLaunchLng.
print "Phase angle at liftoff      : " + phaseAtLiftoff.
print " ".

until ag9
{
    wait 0.01.
}

local arrivalTime   to time:seconds.
local myArrivalLng  to LngToDegress(ship:longitude).
local tgtArrivalLng to LngToDegress(target:longitude).
local myLngDiff     to myArrivalLng - myLaunchLng.
local tgtLngDiff    to tgtArrivalLng - tgtLaunchLng.
local phaseAtArrival to mod(tgtArrivalLng - myArrivalLng + 360, 360).

print "Arrival on orbit at " + time:full.
print "Vessel longitude at arrival : " + myArrivalLng.
print "Target longitude at arrival : " + tgtArrivalLng.
print " ".
print "Time eclipsed: " + (arrivalTime - launchTime).
print "Vessel longitude covered: " + myLngDiff.
print "Target longitude covered: " + tgtLngDiff.
print "Phase angle at arrival: " + phaseAtArrival.
print " ".
print "Phase angle for launch: " + (90 - (phaseAtArrival - phaseAtLiftoff)).

log "Arrival timestamp: " + arrivalTime to logPath.
log "Vessel arrival longitude: " + myArrivalLng to logPath.
log "Target arrival longitude: " + tgtArrivalLng to logPath.
log " " to logPath.
log "Time eclipsed: " + (arrivalTime - launchTime) to logPath.
log "Vessel longitude covered: " + myLngDiff to logPath.
log "Target longitude covered: " + tgtLngDiff to logPath.
log "Phase angle at arrival  : " + phaseAtArrival to logPath.
log " " to logPath.
log "Phase angle for launch  : " + (90 - (phaseAtArrival - phaseAtLiftoff)) to logPath.
print "Results logged to: " + logPath.

print " ".

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