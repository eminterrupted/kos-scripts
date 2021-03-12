@lazyGlobal off.

// Flags
local subOrbital  to false.


local tgtAp to 125000.
local tgtPe to 125000.
local tgtInc to 87.5.

// Script paths
local launchScript to path("0:/main/launch/multistage").
local circScript   to path("0:/main/component/circ_burn").

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
        runPath(circScript, tgtPe, time:seconds + eta:apoapsis).
    }
    // Action group cue for orbital insertion
    ag9 on.
    wait 1.
    ag9 off.
}