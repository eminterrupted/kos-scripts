@lazyGlobal off.
// Initialize (name) the disks
init_disk().

// Flags
local deploySat  to true.
local returnFlag to false.
local suborbital to false.

local tgtAlt to 275000.
local tgtInc to 0.

// Script paths
local launchScript  to path("0:/main/launch/multistage").
local circScript    to path("0:/main/component/circ_burn").
local missionScript to path("0:/main/mission/relay_orbit").
local localMission  to path("local:/" + missionScript:name). 
local returnScript  to path("0:/main/return/suborbital_reentry").
local localReturn   to path("local:/" + returnScript:name).


if ship:status = "PRELAUNCH"
{
    runOncePath("0:/lib/lib_launch").
    launch_pad_gen(true).
        
    // Download the circ script to run locally in case we don't have a connection later
    
    print "Press Enter to initiate launch sequence".
    core:doAction("open terminal", true).
    // Wait for the user to press enter to launch
    until false
    {
        hudtext("Press enter in terminal to initiate launch sequence", 1, 2, 20, yellow, false).
        if terminal:input:hasChar 
        {
            if terminal:input:getChar() = terminal:input:return
            {
                break.
            }
        }
        wait 0.1.
    }

    // Run the launch script and circ burn scripts. 
    runPath(launchScript, tgtAlt, tgtInc).
    if not suborbital 
    {
        local localCircScript to download(circScript).
        runPath(localCircScript, ship:apoapsis, time:seconds + eta:apoapsis).
        deletePath(localCircScript).
    }
    ag9 on.
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

if ship:status <> "PRELAUNCH"
{
    // Download the mission script and run it.
    set localMission to download(missionScript).
    runPath(localMission).
    deletePath(localMission).
    wait 5.

    // If we have a return flag set, return the vessel
    if returnFlag 
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

    local locPath to path("local:/" + path(arcPath):name).

    Print "Checking for KSC Connection...".
    until addons:rt:hasKscConnection(ship)
    {
        Print "Waiting for KSC Connection...".
        wait 5.
    }
    Print "KSC Connection established".
    if exists(locPath) {
        Print "Removing existing file at " + locPath.
        wait 1.
        deletePath(locPath).
    }
    Print "Downloading " + arcPath.
    copyPath(arcPath, locPath).
    if exists(locPath) {
        print "Download complete!".
        wait 1.
        return locPath.
    }
    else
    {
        print "Download failed! Check disk size or original path and try again".
        return 1 / 0.
    }
}