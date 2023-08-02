clearScreen.
runOncePath("0:/lib/mnv").
set rID to Ship:RootPart:UID.
set sc to { return Ship:RootPart:UID <> rID.}.
print "SR Init".
wait until MissionTime > 0.
until false
{   
    if g_TSi <= Time:Seconds
    {
        if sc:Call() break.
        else set g_TSi to Time:Seconds + 5.
    }
    print "StgChk in [{0}]":Format(Round(g_TSi - Time:Seconds)) at (0, 2).
}
print "StgChk passed [MET:{0}]":Format(Round(MissionTime, 2)).
wait 3.
ExecStagedRetro().