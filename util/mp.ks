@lazyGlobal off.
clearScreen.

parameter _plan to "mp.json".

runOncePath("0:/lib/disp").
runOncePath("0:/lib/util").

DispMain(ScriptPath(), false).

if exists(path(_plan))
{
    DispMissionPlan(readJson(_plan)).
}
else
{
    OutMsg("ERROR: No mission plan found!").
}