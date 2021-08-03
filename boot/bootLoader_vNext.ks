@lazyGlobal off.

wait until ship:loaded and ship:unpacked.
clearScreen.

init_disk().

if ksc_comm runOncePath("0:/lib/lib_vessel").

global dataDisk to data_disk().
local lc        to "controller/launchController".
local mc        to "controller/missionController".
local mpPath    to path(dataDisk + "missionPlan.json").
local mpCache   to path("0:/data/mp/missionPlan_" + ship:name:replace(" ","_") + ".json").
local pwrComms  to path("local:/power_comms_enable").
local vFile     to path(dataDisk + "vessel.json").

if missionTime = 0 or ship:status = "PRELAUNCH"
{
    runPath("0:/main/controller/setupPlan").
    set mc to download(mc).
    writeJson(list(ship:name), vFile).
}

if exists(vFile) 
{
    set ship:name to readJson(vFile)[0].
}

if exists(dataDisk + "launchPlan.json") 
{
    runPath("0:/main/" + lc).
}

if exists(pwrComms)
{
    runPath(pwrComms).
    deletePath(pwrComms).
}

if not exists(mpPath)
{
    if ksc_comm
    {
        if exists(mpCache)
        {
            copyPath(mpCache, mpPath).
        }
        else writeJson(queue("mission/simple_orbit"), mpPath).
    }
    writeJson(queue("mission/simple_orbit"), mpPath).
}
else if ksc_comm
{
    copyPath(mpPath, mpCache).
}

set mc to download(mc).
runPath(mc).
deletePath(mc).

//-- Functions
global function data_disk
{
    local idx to 0.

    for c in ship:modulesNamed("kosProcessor")
    {
        if c:volume:name:contains("data_" + idx) 
        {
            return c:volume:name + ":/".
        }
        set idx to idx + 1.
    }
    return "local:/".
}

local function init_disk
{
    local idx to 0.

    
    set core:volume:name to "local_".
    for c in ship:modulesNamed("kOSProcessor")
    {
        if c:volume:name = ""
        {
            local vols to list().
            list volumes in vols.
            for v in vols
            {
                if v:name = "data_" + idx {
                    set idx to idx + 1.
                }
            }
            set c:volume:name to "data_" + idx.
            set idx to idx + 1.
        }
    }
}

global function download
{
    parameter aPath.

    set   aPath   to choose aPath if aPath:typeName = "path" else path("0:/main/" + aPath).
    local lPath   to path("local:/" + path(aPath):name).

    until ksc_comm
    {
        print "Waiting for uplink" at (0, 0).
        wait 1.
    }

    copyPath(aPath, lPath).
    
    if exists(lPath) {
        return lPath.
    }
    else
    {
        print "Download failed, using archive path".
        return aPath.
    }
}

global function ksc_comm
{
    return addons:rt:hasKscConnection(ship).
}