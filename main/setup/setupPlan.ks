// #include "0:/boot/_bl.ks"
// #include "0:/boot/_bl_mini"
// #include "0:/lib/boot"
// #include "0:/lib/globals"

// Location of the archive plan
runOncePath("0:/lib/util").
runOncePath("0:/lib/boot").

writeJson(list(Ship:Name), "vessel.json").

ParseMissionTags().

local planPath to path("0:/_plan/" + plan + "/mp_" + Ship:Name:Replace(" ","_") + ".json").
local setupPath to path("0:/_plan/" + plan + "/setup.ks").
if branch <> "" 
{
     if branch:toNumber(-1) = -1 set setupPath to path("0:/_plan/" + plan + "/setup_" + branch + ".ks").
}
if partC:length > 0
{
     set setupPath to Path(setupPath:replace(".ks", partC + ".ks"):ToString).
}

runPath(setupPath).
writeJson(mp, planPath).