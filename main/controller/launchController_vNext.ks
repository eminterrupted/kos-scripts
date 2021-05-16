@lazyGlobal off.

//#include "0:/boot/bootLoader.ks"

runOncePath("0:/lib/lib_launch").
local launchCache   to dataDisk + "launchPlan.json".
local launchPlan    to readJson(launchCache).
local launchParam   to launchPlan["param"].
local launchQueue   to launchPlan["queue"].

local tgtPe     to launchParam[0].
local tgtAp     to launchParam[1].
local tgtInc    to launchParam[2].
local tgtRoll   to launchParam[3].

ag9 off.
until launchQueue:length = 0
{
    if ship:status = "PRELAUNCH"
    {
        launch_pad_gen(true).

        print "Launch Plan" .
        print "Periapsis   : " + tgtPe.
        print "Apoapsis    : " + tgtAp.
        print "Inclination : " + tgtInc.
        print "Roll Program: " + tgtRoll.
        core:doAction("open terminal", true).
        ag10 off.
        until ag10
        {
            hudtext("Activate AG10 to initiate launch", 1, 2, 20, yellow, false).
            wait 0.01.
        }
        ag10 off.

        runPath("0:/main/launch/" + launchQueue:pop(), launchPlan).
        writeJson(launchPlan, launchCache).
    }
    else
    {
        local curScript to "0:/main/launch/" + launchQueue:pop().
        runPath(curScript, launchPlan).
        writeJson(launchPlan, launchCache).
    }
}
ag9 off.
ag9 on.
deletePath(launchCache).
ag9 off.