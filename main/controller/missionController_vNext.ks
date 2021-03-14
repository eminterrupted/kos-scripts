@lazyGlobal off.

//#include "0:/boot/bootLoader_vNext"

local missionCache to "local:/missionPlan.json".

// 
if exists(missionCache)
{
    local missionPlan to readJson(missionCache).
    until missionPlan:length = 0 
    {
        clearScreen.
        local curScript to download(missionPlan:pop()).
        hudtext("Running next script in mission plan: " + curScript, 10, 2, 20, green, false).
        runPath(curScript).
        hudtext("Mission script complete, removing: " + curScript, 10, 2, 20, green, false).
        deletePath(curScript).
    } 
    deletePath(missionCache).
}