parameter tgtAp, tgtPe, mnvAcc is 0.005, flipphase is false.

if tgtAp <= ship:periapsis set flipPhase to true.

runPath("0:/a/orbit_change", tgtAp, tgtPe, mnvAcc, flipphase, true).