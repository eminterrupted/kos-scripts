local planPath to path("0:/_plan/" + plan + "/mp_" + missionName + ".json").
local setupPath to path("0:/_plan/" + plan + "/setup.ks"). 
runPath(setupPath).
writeJson(mp, planPath).