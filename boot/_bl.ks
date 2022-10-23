@lazyGlobal off. 
ClearScreen.
wait until ship:unpacked.
local ts to time:seconds + 5.
print "Starting up...".
until Time:Seconds >= ts
{
    if homeConnection:isConnected
    {
        runOncePath("0:/lib/loadDep").
        break.
    }
}

if exists("1:/vessel.json") set ship:name to readJson("1:/vessel.json")[0].

global missionName to ship:name:replace(" ", "_").

global mpObj to list().
global planTags to choose ParseMissionTags() if homeConnection:isConnected else getRootTag(core).
global plan to planTags[0].
global branch to "".
if planTags:length > 1 
{
    local t to planTags[1].
    set branch to choose t:substring(0, t:find("[")) if t:matchesPattern(".*\[.*\]") else t.
}
global mpLoc to "1:/mp.json".
global mpArc to "0:/_plan/" + plan + "/mp_" + missionName + ".json".
local runPlan to mpLoc.

sas off.

if ship:status = "PRELAUNCH" or MissionTime = 0
{
    global lp to list().
    runPath("0:/main/setup/setupPlan").
}

if homeConnection:isConnected
{
    runOncePath("0:/lib/boot").
    TagCores().
}

set terminal:width to 65.
set terminal:height to 55.
core:doAction("open terminal", true).

if not exists(mpLoc)
{
    if exists(mpArc)
    {
        copyPath(mpArc, mpLoc).
        if not exists(mpLoc) 
        {
            set runPlan to mpArc.
        }
    }
}
set mpObj to readJson(runPlan).

until mpObj:length = 0
{
    ClearScreen.
    local scr to path("0:/main/" + mpObj[0]).
    local param to mpObj[1].

    if not homeConnection:isConnected
    {
        print "Waiting for connection to KSC...".
        wait until homeConnection:isConnected.
    }
    runPath(scr, param).
    mpObj:remove(1).
    mpObj:remove(0).
    writeJson(mpObj, mpLoc).
    if homeConnection:isConnected writeJson(mpObj, mpArc).
}

ClearScreen.
print "Mission plan complete!".
deletePath(mpArc).
set Core:BootFileName to "".

// Local functions
global function getRootTag
{
    parameter c is core.

    local fragList to list().
    local pipeSplit to c:tag:split("|").
    for word in pipeSplit
    {
        local colonSplit to word:split(":").
        for frag in colonSplit
        {
            fragList:add(frag).
        }
    }
    fragList:add(pipeSplit[1]:ToNumber()).
    return fragList.
}