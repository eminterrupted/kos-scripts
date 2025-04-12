print "boot: {0}":Format(ScriptPath()).
print "POST: ok".
wait until Ship:Unpacked and HomeConnection:IsConnected().
runPath("0:/_main/mce/mc2").