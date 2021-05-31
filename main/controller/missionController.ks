@lazyGlobal off.

//#include "0:/boot/bootLoader.ks"
local missionPlan   to "".
local planPath      to path(dataDisk + "missionPlan.json").

// 
if exists(planPath)
{
    set missionPlan to readJson(planPath).
}
else
{
    set missionPlan to queue("mission/simple_orbit").
    writeJson(missionPlan, planPath).
}

until missionPlan:length = 0 
{
    clearScreen.
    local curScript to "".
    
    if addons:rt:hasKscConnection(ship)
    {
        set curScript to download(missionPlan:pop()).
        if missionPlan:length > 1 download(missionPlan:peek()).
    }
    else if exists("local:/" + missionPlan:peek():split("/")[1])
    {
        set curScript to path("local:/" + missionPlan:pop():split("/")[1]).
    }
    else 
    {
        set curScript to download(missionPlan:pop()).
        download(missionPlan:peek()).
    }
    hudtext("Running next script in mission plan: " + curScript, 10, 2, 20, green, false).
    runPath(curScript).
    hudtext("Mission script complete, removing: " + curScript, 10, 2, 20, green, false).
    if curScript:root = "local:/" deletePath(curScript).
    if missionPlan:length > 0 writeJson(missionPlan, planPath).
}
if exists(planPath) deletePath(planPath).