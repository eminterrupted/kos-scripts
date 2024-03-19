@LazyGlobal off.
ClearScreen.

parameter params to list().

RunOncePath("0:/lib/depLoader.ks").

wait until Ship:Unpacked.

local missionPlanId to GetMissionPlanID().
print missionPlanId.
set g_MissionPlan to GetMissionPlan(missionPlanId).

InitStateCache().

set g_Context to max(g_Context, g_State[0]).
set g_StageLimit to g_State[3].

from { local i to g_Context.} until i = g_MissionPlan:M:Length step { set i to i + 1.} do
{
    SetContext(i, True).
    local scr to "0:/main/{0}.ks":Format(g_MissionPlan:M[i]).
    local prm to g_MissionPlan:P[i]:Split(";").
    set g_StageLimit to g_MissionPlan:S[i].

    runPath(scr, prm).
}