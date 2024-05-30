@LazyGlobal off.
ClearScreen.

local ts to Time:Seconds.

wait 0.01.

until HomeConnection:IsConnected
{
    print "Phase 1" at (1, 1).
    print "Waiting for home connection: {0}    ":Format(TimeSpan(Time:Seconds - ts):Full) at (1, 2).
    wait 1.
}

if HasNode
{
    until not HasNode
    {
        RunPath("0:/main/exec/allNodes.ks").
    }
}
else
{
    print "No nodes present, exiting..." at (1, 3).
}
ClearScreen.

until HomeConnection:IsConnected
{
    print "Phase 2" at (1, 1).
    print "Waiting for home connection: {0}    ":Format(TimeSpan(Time:Seconds - ts):Full) at (1, 2).
    wait 1.
}

CopyPath("0:/boot/bn_bx_TermGlobals.ks", "/boot/bl.ks").
wait 0.025.
reboot.