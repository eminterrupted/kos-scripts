// #include "0:/boot/_bl.ks"
// #include "0:/boot/_bl_mini"
// #include "0:/lib/boot"
// #include "0:/lib/globals"

parameter cryoTankOn is true.

// Location of the archive plan
runOncePath("0:/lib/globals").
runOncePath("0:/lib/util").
runOncePath("0:/lib/boot").
runOncePath("0:/lib/launch").

writeJson(list(Ship:Name), "vessel.json").

if not (defined planTags)
{
    local pTags to ParseMissionTags().
    set plan to pTags[0].
    if pTags:length > 1 
    {
        local t to pTags[1].
        set branch to choose t:substring(0, t:find("[")) if t:matchesPattern(".*\[.*\]") else t.
    }

    if pTags:length > 2
    {
        set partC to pTags[2].
    }
}

//local planPath to path("0:/_plan/" + plan + "/mp_" + Ship:Name:Replace(" ","_") + ".json").
local setupPath to path("0:/_plan/" + plan + "/setup.ks").
if branch <> "" 
{
     if branch:toNumber(-1) = -1 set setupPath to path("0:/_plan/" + plan + "/setup_" + branch + ".ks").
}
if partC:length > 0
{
     set setupPath to Path(setupPath:replace(".ks", partC + ".ks"):ToString).
}

if cryoTankOn
{
     CacheTankCooling().
     for m in ship:modulesNamed("ModuleCryoTank") 
     {
          SetTankCooling(m, true).
     }
}

runPath(setupPath).
//writeJson(mp, planPath).