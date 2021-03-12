@lazyGlobal off.
// Initialize (name) the disks
init_disk().

// Flags
local deploySat  to false.
local returnFlag to true.
local suborbital to false.

local tgtAp to 125000.
local tgtPe to 125000.
local tgtInc to 87.5.

// Script paths
local launchScript to path("0:/main/launch/multistage").
local circScript   to path("0:/main/component/circ_burn").
local returnScript to choose path("0:/main/return/ksc_reentry") if not suborbital else path("0:/main/return/suborbital_reentry").

local missionPlan  to list(
    path("0:/main/mission/auto_sci_biome")
).

if ship:status = "PRELAUNCH"
{
    runOncePath("0:/lib/lib_launch").
    launch_pad_gen(true).
        
    print "Activate AG10 to initiate launch sequence".
    until ag10
    {
        hudtext("Activate AG10 (Press 0) to initiate launch sequence", 1, 2, 20, yellow, false).
        wait 0.1.
    }
    ag10 off.
    core:doAction("open terminal", true).

    // Run the launch script and circ burn scripts. 
    runPath(launchScript, tgtAp, tgtInc).
    if not suborbital 
    {
        local localCircScript to download(circScript).
        runPath(localCircScript, tgtPe, time:seconds + eta:apoapsis).
        deletePath(localCircScript).
    }
    // Action group cue for orbital insertion
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

if ship:status <> "PRELAUNCH" and  ship:status <> "LANDED"
{
    // Download the mission script and run it.
    for script in missionPlan
    {
        print "Downloading: " + script.
        local missionLocal to download(script).
        hudtext("Running next script in mission plan: " + missionLocal, 1, 2, 20, magenta, false).
        runPath(missionLocal).
        deletePath(missionLocal).
        wait 2.5.
    }
}

// If we have a return flag set, return the vessel
if returnFlag 
{
    local returnLocal to download(returnScript).
    runPath(returnLocal).
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