@lazyGlobal off.
clearScreen.

init_disk().

if addons:rt:hasKscConnection(ship) runOncePath("0:/lib/lib_vessel").

if missionTime = 0
{
    runPath("0:/main/controller/setupPlan").
}

if exists("local:/launchPlan.json") 
{
    local lc to download("/controller/launchController").
    runPath(lc).
    deletePath(lc).
}

panels on.
ves_activate_antenna(ship:modulesNamed("ModuleRTAntenna")).

if exists("local:/missionPlan.json")
{
    local mc to download("/controller/missionController_vNext").
    runPath(mc).
    deletePath(mc).
}

//-- Functions
local function init_disk
{
    local cores to ship:modulesNamed("kOSProcessor").
    local idx   to 0.
    
    set core:volume:name to "local".
    for c in cores
    {
        if c:volume:name = "" 
        {
            set c:volume:name to "data_" + idx.
            set idx to idx + 1.
        }
    }
}

global function download
{
    parameter arcPath.

    set   arcPath   to path("0:/main" + arcPath).
    local locPath   to path("local:/" + path(arcPath):name).

    until addons:rt:hasKscConnection(ship)
    {
        Print "Waiting for KSC Connection...".
        wait 5.
    }

    if exists(locPath) {
        Print "Removing existing file at " + locPath.
        deletePath(locPath).
    }

    Print "Downloading " + arcPath.
    copyPath(arcPath, locPath).
    
    if exists(locPath) {
        return locPath.
    }
    else
    {
        print "Download failed! Check disk size or original path and try again".
        return 1 / 0.
    }
}