if ship:status = "PRELAUNCH"
{
    runOncePath("0:/lib/lib_launch").
    launch_pad_gen(true).
    until ag10
    {
        hudtext("Press 0 to initiate launch sequence", 1, 2, 20, yellow, false).
    }
    runPath("0:/main/launch/orion").
}
else
{
    hudText("[bootlauncher.ks]: Vessel already launched!", 1, 2, 20, red, false).
}
