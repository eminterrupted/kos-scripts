@LazyGlobal off.
ClearScreen.

parameter params to list().

RunOncePath("0:/lib/depLoader.ks").

wait until Ship:Unpacked.
Core:DoEvent("Open Terminal").

InitStateCache(Ship:Status = "PRELAUNCH").

set g_MissionPlans to ListMissionPlans().
local missionPlanId to GetMissionPlanID().
set g_MissionPlan to GetMissionPlan(missionPlanId).

copypath("0:/test/stateCache.txt", g_StateCachePath).


set g_Context to max(g_Context, g_State[0]).
set g_StageLimit to g_State[3].


from { local i to g_Context.} until i = g_MissionPlan:M:Length step { set i to i + 1.} do
{
    local scr to "0:/main/{0}.ks":Format(g_MissionPlan:M[i]).
    local prm to g_MissionPlan:P[i]:Split(";").
    set g_StageLimit to g_MissionPlan:S[i]:ToNumber(0).

    runPath(scr, prm).

    SetContext(i).
    UpdateState(true).
}