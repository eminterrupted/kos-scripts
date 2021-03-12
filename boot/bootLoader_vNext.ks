@lazyGlobal off.
clearScreen.

bl_init_disk().

if ship:status = "PRELAUNCH"
{
    local controller to bl_download(path("0:/main/controller/launchController")).
    runPath(controller).
    if exists(controller) deletePath(controller).
}

if ship:status <> "PRELAUNCH" or ship:status <> "LANDED"
{
    local controller to bl_download(path("0:/main/controller/missionController")).
    runPath(controller).
    if exists(controller) deletePath(controller).
}

//-- Functions --//

// Download the controller software
global function bl_download
{
    parameter kscPath.

    local locPath to path("1:/" + kscPath:name).
    if exists(locPath)
    {
        return locPath.
    }
    else if not addons:rt:hasKscConnection(ship)
    {
        bl_wait_for_ksc().
    }
    copyPath(kscPath, locPath).
    return locPath.
}

local function bl_init_disk
{
    local cores to ship:modulesNamed("kOSProcessor").
    local idx   to 0.
    
    for c in cores
    {
        if c:part = ship:rootPart 
        {
            if c:volume:name <> "local" set c:volume:name to "local".
        }
        else
        {
            if c:volume:name = "" set c:volume:name to "data_" + idx.
            set idx to idx + 1.
        }
    }
}

// Waiting for a ksc connection
local function bl_wait_for_ksc
{
    print "[INFO] Waiting for KSC connection...".
        until addons:rt:hasKscConnection(ship)
        {
            wait 30.
        }
    print "[INFO]: Connection to KSC established".
}