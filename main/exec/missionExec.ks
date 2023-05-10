@LazyGlobal off.
ClearScreen.

RunOncePath("0:/lib/libLoader.ks").
RunOncePath("0:/kslib/lib_l_az_calc.ks").

DispMain(ScriptPath()).

local g_MissionTag to ParseCoreTag(core:Part:Tag).
local tgtInc       to choose g_MissionTag:Params[0] if g_MissionTag:Params:Length > 0 else 0.
local tgtAlt       to choose g_MissionTag:Params[1] if g_MissionTag:Params:Length > 1 else 500000.
local azObj        to l_az_calc_init(tgtAlt, tgtInc).

local scr to "0:/main/launch/soundingLaunch.ks".
print "Executing path: {0}":Format(scr).
runPath(scr, list(tgtAlt, tgtInc, azObj)).

if Stage:Number > 0 and Ship:Periapsis < Body:Atm:Height and g_MissionTag:Mission = "Orbit"
{
    OutMsg("Executing circAtApo").
    wait 1.
    runPath("0:/main/launch/circAtApo", list(0, 60, azObj)).
}

wait until ETA:Apoapsis < 15 or Ship:VerticalSpeed <= 0.

if g_ReturnMissionList:Contains(Core:Tag:Split("|")[0]) and Ship:ModulesNamed("RealChuteModule"):Length > 0
{
    OutMsg("Executing reentry").
    runPath("0:/main/return/reentry").
}
set core:bootfilename to "".
print "terminating missionExec, have a nice day".