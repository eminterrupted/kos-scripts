@LazyGlobal off.
ClearScreen.

RunOncePath("0:/lib/libLoader.ks").
RunOncePath("0:/kslib/lib_l_az_calc.ks").

DispMain(ScriptPath()).

set g_MissionTag to ParseCoreTag(core:Part:Tag).
local tgtInc       to choose g_MissionTag:Params[0] if g_MissionTag:Params:Length > 0 else 0.
local tgtAlt       to choose g_MissionTag:Params[1] if g_MissionTag:Params:Length > 1 else 100.
local tgtEcc       to choose g_MissionTag:Params[2] if g_MissionTag:Params:Length > 2 else -1. 
local azObj        to choose l_az_calc_init(tgtAlt, tgtInc) if g_GuidedAscentMissions:Contains(g_MissionTag:Mission) else list().

local scr to "0:/main/launch/soundingLaunch.ks".

if Ship:Status = "PRELAUNCH"
{
    OutMsg("Executing path: {0}":Format(scr)).
    wait 1.
    runPath(scr, list(tgtAlt, tgtInc, azObj)).

    if g_StageLimitSet:Length > 1
    {
        OutMsg("[L24] SetNextStageLimit hit").
        SetNextStageLimit().
    }
}
OutMsg("Exited soundingLaunch").
wait 1.

ClearScreen.
DispMain(ScriptPath()).

// Circularize if necessary
if Stage:Number >= g_StageLimit and Ship:Periapsis < tgtAlt and g_MissionTag:Mission:MatchesPattern("(Orbit|Circularize)")
{
    local burnTime to -1. // This will result in a leadtime of half of all burntime in the currently available stages (i.e., not limited by g_StageLimit)

    OutMsg("Executing circAtApo").
    wait 1.
    runPath("0:/main/launch/circAtApo", list(g_StageLimit, burnTime, tgtEcc, azObj)).

    if g_StageLimitSet:Length > 1
    {
        OutMsg("[L42] SetNextStageLimit hit").
        SetNextStageLimit().
        OutMsg("SetNextStageLimit exit").
    }
    OutMsg("circAtApo complete").
}
else
{
    OutMsg("CircAtApo bypassed").
    OutInfo("Stage: {0} (Lim: {1}) | Pe: {2} (Tgt: {3}) | {4}":Format(Stage:Number, g_StageLimit, Round(Ship:Periapsis), Round(tgtAlt), g_MissionTag:Mission)).
    wait 2.
}
ClearScreen.
DispMain(ScriptPath()).

// TODO: Extend Antenna Function

// Extend any solar panels
ExtendSolarPanels().

if g_ReturnMissionList:Contains(Core:Tag:Split("|")[0]) and Ship:ModulesNamed("RealChuteModule"):Length > 0
{
    OutMsg("Executing reentry").
    runPath("0:/main/return/reentry").
}

set core:bootfilename to "".
print "terminating missionExec, have a nice day".