@LazyGlobal off.
ClearScreen.

parameter params to list().

RunOncePath("0:/lib/depLoader.ks").

wait until Ship:Unpacked.

local missionPlanId to GetMissionPlanID().
print missionPlanId.
set g_MissionPlan to GetMissionPlan(missionPlanId).
local currentExecution to 0.

InitStateCache().
set currentExecution to max(currentExecution, g_State[0]).
set g_StageStop to g_State[3].


from { local i to currentExecution.} until i = g_MissionPlan:M:Length step { set i to i + 1.} do
{
    local scr to "0:/main/{0}.ks":Format(g_MissionPlan:M[i]).
    local prm to g_MissionPlan:P[i]:Split(";").
    set g_StageStop to 

    runPath(scr, prm).
}