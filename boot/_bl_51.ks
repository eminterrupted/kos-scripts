print "Starting".
core:doEvent("Open Terminal").
wait until ship:unpacked and kuniverse:timewarp:issettled.

print "Checking home uplink".
wait until homeConnection:IsConnected.

runOncePath("0:/lib/loadDep").

for id in g_tag:keys
{
    local sPath to Path("0:/_plan/{0}/setup.ks":format(g_tag[id]:SCR)).
    runOncePath(sPath, g_tag[id]:PRM).
}