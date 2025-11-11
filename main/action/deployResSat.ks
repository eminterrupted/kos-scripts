@lazyGlobal off.
ClearScreen.

parameter params to list().

runOncePath("0:/lib/libLoader.ks").
runOncePath("0:/lib/deploy.ks").

set g_MainProc to ScriptPath().
DispMain(g_MainProc).

local nextDeployStg to Stage:Number.
local minDCStg  to nextDeployStg.
local maxDCStg  to 0.

OutMsg("Setting up resonant sat deployment script").

for dc in Ship:Decouplers 
{
    if dc:Stage >= maxDCStg
    {
        set maxDCStg to dc:Stage.
    }
    if dc:Stage <= minDCStg 
    {
        set minDCStg to dc:Stage.
    }
}
set nextDeployStg to maxDCStg.
wait 0.125.

local waitSecs to 5.
local ts to 0.
OutMsg("Awaiting deployment staging").
until Stage:Number <= nextDeployStg 
{
    if Time:Seconds >= ts
    {
        set ts to Time:Seconds + waitSecs.
    }
    OutInfo("curStg: {0} | nextDeployStg: {1}":Format(Stage:Number, nextDeployStg)).
    OutInfo("Sleeping, checking again in {0}s ":Format(Round(ts - Time:Seconds, 1)), 1).
}
OutInfo("", 1).

local depTagList to list("OnDeploy", "OnPayload").
OutMsg("Running deployment routines").
for depTag in depTagList
{
    OutInfo("Current: {0}   ":Format(depTag)).
    RunDeployRoutine(depTag).
    set ts to Time:Seconds + 3.
    until Time:Seconds > ts
    {
        OutInfo("Time Remaining: {0}s ":Format(Round(ts - Time:Seconds, 1)), 1).
    }
    OutInfo("", 1).
}
OutInfo().

OutMsg("Checking for deployment maneuver").
set ts to Time:Seconds + 60.

until Time:Seconds > ts
{
    OutInfo("Time Remaining: {0}s ":Format(Round(ts - Time:Seconds, 1)), 1).
    
    if hasNode
    {
        OutMsg("Executing deployment maneuver").
        OutInfo().
        wait 0.125.
        sas off.
        ExecNodeBurn_Next(nextNode, g_StageLimit).
    }
}

OutInfo().
OutInfo("", 1).
OutMsg("deployResSat complete").
wait 1.