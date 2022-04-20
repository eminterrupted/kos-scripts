// Script to run on a second core during a relay test launch
// to find the amount of time and phase advancement during 
// launch. Use to find optimal launch windows for constellations
@lazyGlobal off.
clearScreen.

parameter tgtOrbitPhase is 60.

runOncePath("0:/lib/nav").
runOncePath("0:/lib/util").
runOncePath("0:/lib/disp").

DispMain(scriptPath(), false).

local shipNameTrimmed to ship:name:replace(" ", "_"):remove(ship:name:length - 1, 1).
local vLn to 10.

local arcLog to "0:/log/relay_planner_" + shipNameTrimmed + ".log".
local logPath to "1:/log/relay_planner_" + shipNameTrimmed + ".log".
local phasePath to "0:/data/relayPlanner/launchPhase_" + shipNameTrimmed + ".json".

local phaseObj to lex("TTO", 0, "Iterations", 0).
if exists(phasePath) set phaseObj to readJson(phasePath).

local launchPhase to "unk".

if phaseObj:hasKey("Phase")
{
    if phaseObj["Phase"]:hasKey(tgtOrbitPhase) 
    {
        set launchPhase to phaseObj["Phase"][tgtOrbitPhase]["LaunchWindow"].
    }
    else 
    {
        set phaseObj["Phase"][tgtOrbitPhase] to lex("Iterations", 0).
    }
}
else 
{
    set phaseObj["Phase"] to lex(tgtOrbitPhase, lex("Iterations", 0)).
}

if launchPhase = "unk" set launchPhase to tgtOrbitPhase.
local lastIteration to phaseObj["Iterations"].
local lastPhaseIteration to phaseObj["Phase"][tgtOrbitPhase]["Iterations"].
local thisIteration to lastIteration + 1.
local thisPhaseIteration to lastPhaseIteration + 1.

if exists(logPath) deletePath(logPath).

OutMsg("Waiting for target vessel selection").
until hasTarget
{
    wait 0.1.
}
OutMsg("Target selected: " + target).

wait 1.

OutMsg("Waiting for launch. Press Enter in terminal to warp").
lock tgtPhase to LngToPhaseAng(target).
print "Desired phase to target in orbit: " + tgtOrbitPhase at (0, cr()).
print "Desired phase to target at launch: " + launchPhase at (0, cr()).
set vLn to cr().

until mod((launchPhase + 360) + 20, 360) >= tgtPhase or launchPhase >= tgtPhase and ship:status <> "PRELAUNCH"
{
    if CheckInputChar(Terminal:Input:Enter) set warp to 5.
    print "Phase angle: " + round(tgtPhase, 2) at (0, vLn).
    wait 0.01.
}
if warp > 0 set warp to 3.

until mod((launchPhase + 360) + 10, 360) >= tgtPhase or launchPhase >= tgtPhase and ship:status <> "PRELAUNCH"
{
    if CheckInputChar(Terminal:Input:Enter) set warp to 3.
    print "Phase angle: " + round(tgtPhase, 2) at (0, vLn).
    wait 0.01.
}
if warp > 0 set warp to 2.

until mod((launchPhase + 360) + 5, 360) >= tgtPhase or launchPhase >= tgtPhase and ship:status <> "PRELAUNCH"
{
    if CheckInputChar(Terminal:Input:Enter) set warp to 2.
    print "Phase angle: " + round(tgtPhase, 2) at (0, vLn).
    wait 0.01.
}
if warp > 0 set warp to 1.

until mod((launchPhase + 360) + 2.5, 360) >= tgtPhase or launchPhase >= tgtPhase and ship:status <> "PRELAUNCH"
{
    if CheckInputChar(Terminal:Input:Enter) set warp to 1.
    print "Phase angle: " + round(tgtPhase, 2) at (0, vLn).
    wait 0.01.
}
if warp > 0 set warp to 0.

if ship:status = "PRELAUNCH" and tgtPhase <= tgtOrbitPhase 
{
    OutMsg("Initiating launch countdown").
    SendMsg(ship:rootpart:tag, "launchCommit").
}

until CheckMsgQueue():length > 0
{
  print "Phase angle to target: " + round(tgtPhase, 3) + "   " at (0, vLn).
  wait 0.01.
}

local launchTime    to time:seconds.
local myLaunchLng   to LngToDegress(ship:longitude).
local tgtLaunchLng  to LngToDegress(target:longitude).
local phaseAtLiftoff to mod(tgtLaunchLng - myLaunchLng + 360, 360).
local launchErr     to mod(phaseAtLiftoff - launchPhase + 360, 360).

print "                                                           " at (0, vLn).
set vLn to cr().

teeLog("Iteration count        : " + thisIteration).
teeLog("Phase interation count : " + thisPhaseIteration).
teeLog("Liftoff timestamp      : " + launchTime).
teeLog("Vessel launch longitude: " + myLaunchLng).
teeLog("Target launch longitude: " + tgtLaunchLng).
teeLog("Phase angle at liftoff : " + phaseAtLiftoff).
teeLog("Liftoff error          : " + launchErr).
teeLog(" ").
wait 1.

OutInfo("Awaiting Orbital Insertion").
until CheckMsgQueue():length > 0 or ag9
{
    OutMsg("MET: " + round(missionTime, 1)).
    OutInfo("Target phase angle: " + round(tgtPhase, 3)).
    wait 0.01.
}

local arrivalTime   to time:seconds.
local myArrivalLng  to LngToDegress(ship:longitude).
local tgtArrivalLng to LngToDegress(target:longitude).
local myLngDiff     to myArrivalLng - myLaunchLng.
local tgtLngDiff    to tgtArrivalLng - tgtLaunchLng.
local phaseAtArrival to mod(tgtArrivalLng - myArrivalLng + 360, 360).

local tgtLaunchPhase to (tgtOrbitPhase - (phaseAtArrival - phaseAtLiftoff)) - launchErr.
local launchDur to round((arrivalTime - launchTime), 5).

// Average and write the launch phase window and duration values against the existing ones
set phaseObj["TTO"] to round(((phaseObj["TTO"] * lastIteration) + (arrivalTime - launchTime) / (thisIteration)), 3).
set phaseObj["Iterations"] to thisIteration.
set phaseObj["Phase"][tgtOrbitPhase]["LaunchWindow"] to choose round(((phaseObj["Phase"][tgtOrbitPhase]["LaunchWindow"] * lastPhaseIteration) + tgtLaunchPhase) / (thisPhaseIteration), 5) if phaseObj["Phase"][tgtOrbitPhase]:hasKey("LaunchWindow") else round(tgtLaunchPhase, 5).
set phaseObj["Phase"][tgtOrbitPhase]["Iterations"] to thisPhaseIteration.

local launchSpanStr to timespan(launchDur):hour + "h " + timespan(launchDur):minute + "m " + round(timespan(launchDur):second, 3) + "s".

teeLog("Arrival on orbit at MET:" + launchSpanStr).
teeLog(" ").
teeLog("Time to orbit: " + round(launchDur, 3)).
teeLog("Vessel longitude covered: " + myLngDiff).
teeLog("Target longitude covered: " + tgtLngDiff).
teeLog(" ").
teeLog("Vessel longitude at arrival : " + myArrivalLng).
teeLog("Target longitude at arrival : " + tgtArrivalLng).
teeLog("Phase angle at arrival: " + phaseAtArrival).
teeLog(" ").
teeLog("Calculated phase angle at launch: " + tgtLaunchPhase).
teeLog(" ").
teeLog("New weighted averages for Phase Window [" + tgtOrbitPhase + "]:").
teeLog("Time to orbit: " + phaseObj["TTO"]).
teeLog("Phase angle at launch: " + phaseObj["Phase"][tgtOrbitPhase]["LaunchWindow"]).

outMsg("Results logged to " + logPath).
wait 2.

OutMsg("Uploading log to archive").
OutInfo("Waiting for KSC connection to upload log").
wait until addons:rt:hasKscConnection(ship).
OutInfo("Connection established").

OutMsg("Uploading log to " + arcLog).
copyPath(logPath, arcLog).
wait 1.

OutInfo("Writing PhaseObj to '" + phasePath + "'").
writeJson(phaseObj, phasePath).

OutInfo().
OutMsg("RelayPlanner complete!").

// ag9 off.
// OutMsg("Press enter to deploy payload").
// terminal:input:clear.
// until false
// {
//     if CheckInputChar(terminal:input:enter) break.
//     wait 0.05.
// }
// ag9 on.

local function teeLog 
{
    parameter str, lvl is 0.

    local lvlStr to "LOG".
    if lvl = 1 set lvlStr to "WRN".
    else if lvl = 2 set lvlStr to "ERR".

    log "[" + missionTime + "][" + lvlStr + "] " + str to logPath.
    print str at (0, cr()).
}