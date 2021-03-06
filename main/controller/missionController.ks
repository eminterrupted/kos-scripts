// Initialize (name) the disks
init_disk().

// Flags
local deploySat to false.
local return    to true.

// Script paths
local launchScript to path("0:/main/launch/multistage").
local mnvScript    to path("0:/main/component/circ_burn").
local missionScript to path("0:/main/mission/simple_orbit").
local localMission to path("local:/" + missionScript:name). 
local returnScript to path("0:/main/return/simple_reentry").
local localReturn  to path("local:/" + returnScript:name).


if ship:status = "PRELAUNCH"
{
    runOncePath("0:/lib/lib_launch").
    launch_pad_gen(true).
        
    // Download the circ script to run locally in case we don't have a connection later
    local localMnvScript to download(mnvScript).
    set localMission to download(missionScript).

    // Wait for the user to press '0' to launch
    until ag10
    {
        hudtext("Press 0 to initiate launch sequence", 1, 2, 20, yellow, false).
    }

    // Run the launch script and circ burn scripts. 
    runPath(launchScript).
    runPath(localMnvScript, ship:apoapsis, time:seconds + eta:apoapsis).
    ag9 on.
    // Remove the downloaded scripts when finished
    deletePath(localMnvScript).
}

wait 5.
if deploySat
{
    until stage:number = 0 
    {
        stage. 
        wait 1.
    }
}

if ship:status = "ORBITING"
{
    // Download the mission script and run it.
    runPath(localMission).

    wait 5.

    // If we have a return flag set, return the vessel
    if return 
    {
        set localReturn to download(returnScript).
        runPath(localReturn).
    }
}


// Init functions
local function init_disk
{
    local cores     to ship:modulesNamed("kOSProcessor").
    local idx       to 0.
    
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

local function download
{
    parameter arcPath.

    set locPath to path("local:/" + path(arcPath):name).

    Print "Checking for KSC Connection...".
    until addons:rt:hasKscConnection(ship)
    {
        Print "Waiting for KSC Connection...".
        wait 5.
    }
    Print "KSC Connection established".
    if exists(locPath) {
        Print "Removing existing file at " + locPath.
        deletePath(locPath).
    }
    Print "Downloading " + arcPath.
    copyPath(arcPath, locPath).
    if exists(locPath) {
        print "Download complete!".
        return locPath.
    }
    else
    {
        print "Download failed! Check disk size or original path and try again".
        return 1 / 0.
    }
}