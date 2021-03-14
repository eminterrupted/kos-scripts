@lazyGlobal off.
// Initialize (name) the disks
init_disk().

// Mission Params
local deploySat  to true.
local returnFlag to false.
local suborbital to false.

local tgtAp to 12178504.
local tgtPe to 11344986.
local tgtInc to -34.5.

local missionPlan to list(
    path("0:/main/mission/simple_orbit")
).

// Standdard script paths
local launchScript to path("0:/main/launch/multistage").
local circScript   to path("0:/main/maneuver/circ_burn").
local returnScript to choose path("0:/main/return/ksc_reentry") if not suborbital else path("0:/main/return/suborbital_reentry").

if ship:status = "PRELAUNCH"
{
    runOncePath("0:/lib/lib_launch").
    launch_pad_gen(true).
        
    print "Activate AG10 to initiate launch sequence".
    print " ".
    print "Target Apoapsis    : "   + tgtAp.
    print "Target Periapsis   : "   + tgtPe.
    print "Target Inclination : "   + tgtInc.

    core:doAction("open terminal", true).
    ag10 off.
    until ag10
    {
        hudtext("Activate AG10 to initiate launch sequence", 1, 2, 20, yellow, false).
        wait 0.01.
    }
    ag10 off.

    // Run the launch script and circ burn scripts. 
    runPath(launchScript, tgtAp, tgtInc).
    if ship:apoapsis > 5000000 panels on.
    if not suborbital 
    {
        local localCircScript to download(circScript).
        runPath(localCircScript, tgtPe, time:seconds + eta:apoapsis).
        deletePath(localCircScript).
    }
    // Action group cue for orbital insertion
    ag9 on.
}

if deploySat
{
    local tStamp to time:seconds + 15.
    until time:seconds >= tStamp 
    {
        print "Deploying satellite in T" + round(time:seconds - tStamp) + "  " at (0, 2).
    }
    until stage:number = 0 
    {
        stage. 
        wait 1.
    }
}

if ship:status <> "PRELAUNCH" and  ship:status <> "LANDED"
{
    // Download the mission script and run it.
    print missionPlan.
    local missionPlanLength to missionPlan:length.
    print missionPlanLength + " total missions found in plan".
    from { local idx to 0.} until idx >= missionPlanLength step { set idx to idx + 1.} do
    {
        print "Executing mission: " + missionPlan[0].
        local script to missionPlan[0].
        print "Downloading: " + script.
        local missionLocal to download(script).
        hudtext("Running next script in mission plan: " + missionLocal, 10, 2, 20, magenta, false).
        runPath(missionLocal).
        deletePath(missionLocal).
        missionPlan:remove(0).
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