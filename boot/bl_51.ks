ClearScreen.
wait until Ship:Unpacked.
print "Ship unpacked".
print "Executing mission".
runPath("0:/main/mission/commander.ks").
ClearScreen.
print "{0} complete":Format(scriptPath()).