
@LazyGlobal off.

set Config:Stat to True.

// Load Dependencies
RunOncePath("0:/lib/globals").
RunOncePath("0:/lib/loadDep").

InitDisp().

// Tag parsing
set g_Tag to ParseCoreTag().
set g_stopStage to g_Tag:ASL.

set g_missionPlan to path("0:/_mission/{0}/{1}.ks":format(g_Tag["PCN"], ship:name:replace(" ","_"))).
set g_MP_Json to path("0:/_mission/{0}/{1}.json":Format(g_Tag["PCN"], ship:name:replace(" ","_"))).

local _logProfileResult to True.

// Detect if we are pre-launch, and if so, set up the mission plan. 
if ship:status = "PRELAUNCH"
{
    runPath(Path("0:/_plan/{0}/setup.ks":format(g_Tag["PCN"]))).
    WriteJson(g_MP_List, g_MP_Json).
}
else if exists(Path(g_MP_Json))
{
    set g_MP_List to ReadJson(g_MP_Json).
}
else if g_MP_List:Length > 0
{
    WriteJson(g_MP_List, g_MP_Json).
}
else
{
    OutMsg("[31]RunCtrl: idk").
    wait 1.
}

local mpDoneFlag to false.
until mpDoneFlag
{
    if g_MP_List:Length = 0
    {
        DeletePath(g_MP_Json).
        DeletePath(g_missionPlan).
        set mpDoneFlag to true.
    }
    else
    {
        OutMsg("Running: {0}":Format(g_MP_List[0])).
        runPath(Path("0:/_scr/{0}":Format(g_MP_List[0])), g_MP_List[1]).
        g_MP_List:Remove(1).
        g_MP_List:Remove(0).
        WriteJson(g_MP_List, g_MP_Json).
    }
}
OutMsg("runCtrl complete").
if _logProfileResult
{
    local profilePath to "0:/data/prof/{0}_{1}.log":Format(Ship:Name:Replace(" ","_"), Round(Time:Seconds)).
    OutInfo("Logging profile result to {0}":Format(profilePath)).
    log ProfileResult() to profilePath.
}
OutMsg("Exiting...").
OutInfo().


local function InitMissionPlan
{
    parameter _reset is false.

    local setupPlan to Path("0:/_plan/{0}/setup.ks":format(g_Tag["PCN"])).

    if _reset
    {
        if exists(g_MissionPlan) { DeletePath(g_MissionPlan). }
        runPath(setupPlan).
    }
    
    WriteJson(g_MP_List, g_MP_Json).
    copyPath(setupPlan, g_missionPlan).
}