ClearScreen.
wait until Ship:Unpacked.
print "Ship unpacked".
local scr to "0:/main/launch/soundingLaunch.ks".
print "Executing path: {0}":Format(scr).
runPath(scr).
ClearScreen.
print "terminating missionExec, have a nice day".