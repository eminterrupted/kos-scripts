// Cache the mission plan on a vessel to archive
@lazyGlobal off.

parameter op is "write".

local dataDisk    to "local:/".
for c in ship:modulesNamed("kosProcessor")
{
    if c:volume:name = "data_0" set dataDisk to "data_0:/".
}
local localFile     to dataDisk + "missionPlan.json".
local archiveFile   to "0:/data/mp/missionPlan_" + ship:name:replace(" ", "_") + ".json".

if op = "write" 
{
    copyPath(localFile, archiveFile).
}
else if op = "read"
{
    if exists(archiveFile)
    {
        copyPath(archiveFile, localFile).
    }
}