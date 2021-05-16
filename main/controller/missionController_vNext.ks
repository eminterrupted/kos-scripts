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
    set missionPlan to queue(lex("scr","mission/simple_orbit")).
    writeJson(missionPlan, planPath).
}

until missionPlan:length = 0 
{
    clearScreen.
    local mission   to missionPlan:pop().
    local script    to "".
    
    if addons:rt:hasKscConnection(ship)
    {
        set script to download(mission:scr).
        if missionPlan:length > 1 download(missionPlan:peek():scr).
    }
    else if exists("local:/" + mission:scr:split("/")[1] + ".ks")
    {
        set script to path("local:/" + mission:scr:split("/")[1] + ".ks").
    }
    else 
    {
        set script to download(mission:scr).
        download(missionPlan:peek():scr).
    }
    
    hudtext("Running next script in mission plan: " + script, 10, 2, 20, green, false).
    if mission:hasKey("prm") 
    {
        runPath(script, mission:prm).
    }
    else
    {
        runPath(script).
    }
    hudtext("Mission script complete, removing: " + script, 10, 2, 20, green, false).
    deletePath(script).
    writeJson(missionPlan, planPath).
}
deletePath(planPath).