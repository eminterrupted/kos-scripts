@lazyGlobal off.

//#include "0:/boot/bootLoader_vNext"
runOncePath("0:/lib/lib_launch").

local launchCache   to "local:/launchPlan.json".
local launchPlan    to readJson(launchCache).
local launchQueue   to launchPlan:queue.

ag9 off.
until launchQueue:length = 0
{
    if ship:status = "PRELAUNCH"
    {
        launch_pad_gen(true).

        print "Launch Plan" .
        print "Apoapsis    : " + launchPlan:tgtAp.
        print "Periapsis   : " + launchPlan:tgtPe.
        print "Inclination : " + launchPlan:tgtInc.
        core:doAction("open terminal", true).
        ag10 off.
        until ag10
        {
            hudtext("Activate AG10 to initiate launch sequence", 1, 2, 20, yellow, false).
            wait 0.01.
        }
        ag10 off.

        runPath("0:/main" + launchQueue:pop(), launchPlan).
        writeJson(launchPlan, launchCache).
    }
    else
    {
        local curScript to download(launchQueue:pop()).
        runPath(curScript, launchPlan).
        deletePath(curScript).
        writeJson(launchPlan, launchCache).
    }
}
ag9 on.
hudtext("Launch plan complete, deleting launchCache", 5, 2, 20, green, false).
deletePath(launchCache).
ag9 off.