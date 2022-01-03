@lazyGlobal off. 
wait until ship:loaded.
local ts to time:seconds + 5.
print "Starting up..." at (0, 0).
wait until Addons:RT:HasKscConnection(ship) or Time:Seconds >= ts.

if exists("1:/vessel.json") set ship:name to readJson("1:/vessel.json")[0].

global mp to list().
global planTags to parseMissionTags(core).
global plan to planTags[0].
global branch to choose planTags[1] if planTags:length > 1 else "".
global missionName to ship:name:replace(" ", "_").

local localPlan to "1:/mp.json".
local archivePlan to "0:/_plan/" + plan + "/mp_" + missionName + ".json".
local runPlan to localPlan.

if ship:status = "PRELAUNCH" 
{
    global lp to list().
    runPath("0:/main/setup/setupPlan").
}

tagCores().

set terminal:width to 60.
set terminal:height to 40.
core:doAction("open terminal", true).

if not exists(localPlan)
{
    if exists(archivePlan)
    {
        copyPath(archivePlan, localPlan).
        if not exists(localPlan) 
        {
            set runPlan to archivePlan.
        }
    }
}
set mp to readJson(runPlan).

until mp:length = 0
{
    local scr to path("0:/main/" + mp[0]).
    local param to mp[1].

    runPath(scr, param).
    mp:remove(1).
    mp:remove(0).
    writeJson(mp, localPlan).
    if addons:rt:hasKscConnection(ship) writeJson(mp, archivePlan).
}

deletePath(archivePlan).

// Local functions
local function tagCores
{
    set core:volume:name to "PLX0".
    
    local idx to 1.
    for c in ship:modulesNamed("kOSProcessor")
    {
        if c:tag = "" 
        {
            set c:tag to "PCX" + idx.
            set c:volume:name to "PLX" + idx.
            set idx to idx + 1.
        }
        else if c:volume:name = ""
        {
            set c:volume:name to "PLX" + idx.
            set idx to idx + 1.
        }
    }
}

local function parseMissionTags
{
    parameter c.

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
    return fragList.
}