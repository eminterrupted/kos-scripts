@lazyGlobal off.

//#include "0:/boot/bootLoader.ks"

runOncePath("0:/lib/lib_launch").
local circPath      to choose path("0:/main/launch/circ_burn_node") if career():canMakeNodes else path("0:/main/launch/circ_burn_simple").
local launchCache   to dataDisk + "launchPlan.json".
local launchPlan    to readJson(launchCache).
local launchQueue   to launchPlan:queue.

ag9 off.
until launchQueue:length = 0
{
    if ship:status = "PRELAUNCH" or ship:status = "LANDED"
    {
        launch_pad_gen(true).

        print "Launch Plan" .
        print "Apoapsis    : " + launchPlan:tgtAp.
        print "Periapsis   : " + launchPlan:tgtPe.
        print "Inclination : " + launchPlan:tgtInc.
        print "Roll Program: " + launchPlan:tgtRoll.
        core:doAction("open terminal", true).
        ag10 off.
        until ag10
        {
            hudtext("Activate AG10 to initiate launch", 1, 2, 20, yellow, false).
            wait 0.01.
        }
        ag10 off.

        download(circPath).
        runPath("0:/main/launch/" + launchQueue:pop(), launchPlan).
        writeJson(launchPlan, launchCache).
    }
    else 
    {
        local curScript to choose path("local:/" + launchQueue:pop()) if exists(path("local:/" + launchQueue:peek())) else path("0:/main/launch/" + launchQueue:pop()).
        runPath(curScript, launchPlan).
        writeJson(launchPlan, launchCache).
    }
}
ag9 off.
ag9 on.
deletePath(launchCache).
ag9 off.