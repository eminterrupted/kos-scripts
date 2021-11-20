@lazyGlobal off. 
wait 1.

global mp to list().
global plan to choose "misc" if core:tag = "" else core:tag:split("|")[0].
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

// Local functions
local function tagCores
{
    set core:volume:name to "PLX0".
    
    local idx to 1.
    for c in ship:modulesNamed("kOSProcessor")
    {
        if c:part:tag = "" 
        {
            set c:part:tag to "PCX" + idx.
            set c:volume:name to "PLX" + idx.
            set idx to idx + 1.
        }
        else if c:volume:name = ""
        {
            set c:volume:name to c:part:tag.
        }
    }
}