@LazyGlobal off.
ClearScreen.

parameter _params to list().

RunOncePath("0:/lib/depLoader.ks").

wait until Ship:Unpacked.
Core:DoEvent("Open Terminal").

if Ship:Status = "PRELAUNCH"
{
    InitStateCache(True).
    set g_MissionPlans to ListMissionPlans().
    SetMissionPlanId(GetMissionPlanID(), True).
    set g_MissionPlan to GetMissionPlan(g_MissionPlanId).
    set g_StageLimit to g_MissionPlan:S[g_State[1]]:ToNumber(0).
    CacheState().
}
else
{
    InitStateCache().
    set g_MissionPlans to ListMissionPlans().
    set g_MissionPlan to GetMissionPlan(g_MissionPlanID).
    // print g_MissionPlan at (2, 20). 
    // Breakpoint().
    set g_Context to g_State[1].
    set g_Program to g_State[2].
    set g_Runmode to g_State[3].
    set g_StageLimit to g_State[4].
}


from { local i to g_Context.} until i = g_MissionPlan:M:Length step { set i to i + 1.} do
{
    local scr to "0:/main/{0}.ks":Format(g_MissionPlan:M[i]).
    local prm to g_MissionPlan:P[i]:Split(";").
    set g_StageLimit to g_MissionPlan:S[i]:ToNumber(0).
    SetContext(i, true).
    CacheState().

    wait until HomeConnection:IsConnected().
    runPath(scr, prm).
}