// #include "0:/boot/_bl.ks"
runOncePath("0:/lib/util").

writeJson(list(ship:name), "vessel.json").
local planPath to path("0:/_plan/" + plan + "/mp_" + missionName + ".json").
local setupPath to path("0:/_plan/" + plan + "/setup.ks").
if branch <> "" 
{
     if branch:toNumber(-1) = -1 set setupPath to path("0:/_plan/" + plan + "/setup_" + branch + ".ks").
}

runPath(setupPath).
writeJson(mp, planPath).