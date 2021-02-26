parameter tgtAp, tgtPe, mnvAcc is 0.005, flipphase is false.

if tgtAp <= ship:periapsis set flipPhase to true.

if allNodes:length > 0 
{
    for n in allNodes
    {
        remove n.
    }
}

runPath("0:/a/orbit_change", tgtAp, tgtPe, mnvAcc, flipphase, true).