@lazyGlobal off.

local launchCache  to "local:/launchPlan.json".
local missionCache to "local:/missionPlan.json".

// If the mission hasn't started yet, set up the mission plan
if exists(launchCache)
{
    local launchPlan to readJson(launchCache).
    local launchQueue to launchPlan:queue.
    until launchQueue:length = 0
    {
        if ship:status = "PRELAUNCH"
        {
            runOncePath("0:/lib/lib_launch").
            launch_pad_gen(true).

            print "Activate AG10 to initiate launch sequence".
            print " ".
            print "Launch Plan" .
            print "Apoapsis    : " + launchPlan:tgtAp.
            print "Periapsis   : " + launchPlan:tgtPe.
            print "Inclination : " + launchPlan:tgtInc.
            core:doAction("open terminal", true).
            ag10 off.
            until ag10
            {
                hudtext("Activate AG10 (Press 0) to initiate launch sequence", 1, 2, 20, yellow, false).
                wait 0.01.
            }
            ag10 off.

            runPath("0:/main" + launchQueue:pop(), launchPlan).
            writeJson(launchPlan, launchCache).
        }
        else
        {
            clearScreen.
            local curScript to download(launchQueue:pop()).
            runPath(curScript, launchPlan).
            deletePath(curScript).
            writeJson(launchPlan, launchCache).
        }
    }
    hudtext("Launch plan complete, deleting launchCache", 5, 2, 20, green, false).
    deletePath(launchCache).
}

if exists(missionCache)
{
    local missionPlan to readJson(missionCache).
    until missionPlan:length = 0 
    {
        clearScreen.
        local curScript to download(missionPlan:pop()).
        hudtext("Running next script in mission plan: " + curScript, 10, 2, 20, green, false).
        runPath(curScript).
        hudtext("Mission script complete, removing: " + curScript, 10, 2, 20, green, false).
        deletePath(curScript).
    } 
    deletePath(missionCache).
}


//-- Mission Controller Functions --//
local function download
{
    parameter arcPath.

    set   arcPath   to path("0:/main" + arcPath).
    local locPath   to path("local:/" + path(arcPath):name).

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