// #include "0:/boot/_bl.ks"
runOncePath("0:/lib/util").

local planPath to path("0:/_plan/" + plan + "/mp_" + missionName + ".json").
local setupPath to path("0:/_plan/" + plan + "/setup.ks").
if branch <> "" 
{
     if branch:toNumber(-1) = -1 set setupPath to path("0:/_plan/" + plan + "/" + branch + "_setup.ks").
}

runPath(setupPath).
writeJson(mp, planPath).