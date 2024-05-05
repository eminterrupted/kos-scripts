@LazyGlobal off.
ClearScreen.

parameter _params to list().

RunOncePath("0:/lib/depLoader.ks").

wait until Ship:Unpacked.
Core:DoEvent("Open Terminal").

if Ship:Status = "PRELAUNCH"
{
    InitStateCache(True).
    local mpConfirm to false.
    until mpConfirm
    {
        set g_MissionPlans to ListMissionPlans().
        local mpId to SelectMissionPlanID().
        if mpId > -1
        {
            SetMissionPlanId(mpId, True).
            set g_MissionPlan to GetMissionPlan(g_MissionPlanId).
            set g_StageLimit to g_MissionPlan:S[g_State[1]]:ToNumber(0).

            set mpConfirm to ConfirmOrModifyMissionPlan(g_MissionPlanId, g_MissionPlan).
        }
        else
        {
            ClearScreen.
        }
            
    }
    CacheState().
}
else
{
    InitStateCache().
    // set g_MissionPlans to ListMissionPlans().
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

set Core:BootFileName to "".

// TODO ConfirmMissionPlan
local function ConfirmOrModifyMissionPlan
{
    parameter _missionPlanID,
              _missionPlan.

    
    OutStr("Selected plan details:", cr()).
    cr().
    from { local i to 0.} until i = _missionPlan:M:Length step { set i to i + 1.} do
    {
        OutStr("MissionPhase: {0}":Format(i), cr()).
        DispPlan(list(_missionPlan:M[i], _missionPlan:P[i], _missionPlan:S[i]), cr()).
        cr().
    }
    cr().
    OutStr("[ENTER]    : Confirm", cr()).
    OutStr("[BACKSPACE]: Cancel", cr()).
    OutStr("[DELETE]   : Modify", cr()).

    until false
    {
        GetTermChar().

        if g_TermChar <> ""
        {
            if g_TermChar = Terminal:Input:Enter
            {
                set g_TermChar to "".
                return true.
            }
            else if g_TermChar = char(8)
            {   
                set g_TermChar to "".
                return false.
            }
            else if g_TermChar = Terminal:Input:DeleteRight
            {
                set g_TermChar to "".
                ModifyMissionPlan(_missionPlanId).
                return true.
            }
            else
            {
                set g_TermChar to "".
                return false.
            }
        }
    }
}