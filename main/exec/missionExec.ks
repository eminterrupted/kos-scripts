@LazyGlobal off.
ClearScreen.

RunOncePath("0:/lib/libLoader.ks").
RunOncePath("0:/kslib/lib_l_az_calc.ks").

DispMain(ScriptPath()).

set g_MissionTag to ParseCoreTag(core:Part:Tag).
local tgtInc       to choose g_MissionTag:Params[0] if g_MissionTag:Params:Length > 0 else 0.
local tgtAlt       to choose g_MissionTag:Params[1] if g_MissionTag:Params:Length > 1 else 100.
local azObj        to choose l_az_calc_init(tgtAlt, tgtInc) if g_GuidedAscentMissions:Contains(g_MissionTag:Mission) else list().

local scr to "0:/main/launch/soundingLaunch.ks".

if Ship:Status = "PRELAUNCH"
{
    print "Executing path: {0}":Format(scr).
    runPath(scr, list(tgtAlt, tgtInc, azObj)).

    if g_StageLimitSet:Length > 1
    {
        SetNextStageLimit().
    }
}

// Circularize if necessary
if Stage:Number > g_StageLimit and Ship:Periapsis < tgtAlt and g_MissionTag:Mission = "Orbit"
{
    local burnTime to 90. // GetEnginesSpecs(GetNextEngines()):ESTBURNTIME.

    OutMsg("Executing circAtApo").
    wait 1.
    runPath("0:/main/launch/circAtApo", list(g_MissionTag:StgStop, burnTime, azObj)).

    if g_StageLimitSet:Length > 1
    {
        SetNextStageLimit().
    }
}


wait until Ship:VerticalSpeed <= 0.

if g_ReturnMissionList:Contains(Core:Tag:Split("|")[0]) and Ship:ModulesNamed("RealChuteModule"):Length > 0
{
    OutMsg("Executing reentry").
    runPath("0:/main/return/reentry").
}

set core:bootfilename to "".
print "terminating missionExec, have a nice day".