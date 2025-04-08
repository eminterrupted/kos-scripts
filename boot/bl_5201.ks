print "boot: {0}":Format(scriptPath()).
print "POST: ok".
wait until ship:unpacked and homeConnection:IsConnected().
runPath("0:/main/mce/mc2").