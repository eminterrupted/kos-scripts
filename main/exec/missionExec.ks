RunOncePath("0:/lib/libLoader").
DispMain(ScriptPath()).
local scr to "0:/main/launch/soundingLaunch.ks".
print "Executing path: {0}":Format(scr).
runPath(scr).
ClearScreen.
if g_ReturnMissionList:Contains(Core:Tag:Split("|")[0]) and Ship:ModulesNamed("RealChuteModule"):Length > 0
{
    runPath("0:/main/return/reentry").
}
print "terminating missionExec, have a nice day".