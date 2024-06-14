@LazyGlobal off.
ClearScreen.

RunOncePath("0:/lib/libLoader.ks").
RunOncePath("0:/kslib/lib_l_az_calc.ks").

set g_MainProcess to ScriptPath().
DispMain().

set g_MissionTag to ParseCoreTag(core:Part:Tag).
local tgtInc       to choose g_MissionTag:Params[0] if g_MissionTag:Params:Length > 0 else 0.
local tgtAp       to choose g_MissionTag:Params[1] if g_MissionTag:Params:Length > 1 else 175000.
local tgtPe        to choose g_MissionTag:Params[2] if g_MissionTag:Params:Length > 2 and g_MissionTag:Params[2] >  1 else -1.
local tgtEcc       to choose g_MissionTag:Params[2] if g_MissionTag:Params:Length > 2 and g_MissionTag:Params[2] <= 1 else -1. 
local azObj        to choose l_az_calc_init(tgtAp, tgtInc) if g_GuidedAscentMissions:Contains(g_MissionTag:Mission) else list().

SetupOnDeployHandler(Ship:PartsTaggedPattern("OnDeploy\|\d")).
local scr to "0:/main/launch/launchAscent.ks".

if Ship:Status = "PRELAUNCH"
{
    RunOncePath("0:/lib/launch.ks").
    set g_LaunchParams to GetLaunchParameters().

    if HasTarget
    {
        local doneFlag to false.
        set g_TS to Time:Seconds + 5.
        until Time:Seconds > g_TS or doneFlag
        {
            OutMsg("Wait for rendezvous launch window for {0}? (ENTER / Backspace)":Format(Target:Name)).
            OutInfo("(Skipping in {0}s)":Format(Round(g_TS - Time:Seconds, 2))).
            GetTermChar().
            if g_TermChar <> ""
            {
                if g_TermChar = Terminal:Input:Enter
                {
                    RunPath("0:/main/launch/holdForLaunchWindow.ks").
                    set doneFlag to True.
                }
                else if g_TermChar = Terminal:Input:Backspace
                {
                    OutMsg().
                    set doneFlag to True.
                }
                else if g_TermChar = "i"
                {
                    RunPath("0:/main/launch/measureLaunchStats", list(tgtInc, tgtAp, tgtPe, tgtEcc)).
                }
                else
                {
                    set g_TS to Time:Seconds + 5.
                }
                set g_TermChar to "".
            }
        }
    }


    OutMsg("Executing path: {0}":Format(scr)).
    wait 1.
    runPath(scr, list(g_LaunchParams:TGTINC, g_LaunchParams:TGTAP, g_LaunchParams:TGTPE, g_LaunchParams:AZ)).

    if g_StageLimitSet:Length > 1
    {
        OutMsg("[L24] SetNextStageLimit hit").
        SetNextStageLimit().
    }
}
OutMsg("Exited launchAscent").
wait 1.

ClearScreen.
set g_MainProcess to ScriptPath().
DispMain().

// Circularize if necessary
if Stage:Number >= g_StageLimit and Ship:Periapsis < tgtPe and g_MissionTag:Mission:MatchesPattern("^((PID)?Orbit|Circularize)") 
{
    ExecCircBurn().
}
else if Stage:Number >= g_StageLimit and g_MissionTag:Mission:MatchesPattern("SubOrbit|PIDSubOrbital")
{
    local doApoBurn to False.

    for eng in Ship:Engines
    {
        if eng:Stage >= g_StageLimit
        {
            if eng:Ignitions > 0
            {
                if not eng:Flameout
                {
                    set doApoBurn to True.
                }
            }
        }
    }

    if doApoBurn
    {
        ExecCircBurn().
    }
    else
    {
        OutMsg("CircAtApo bypassed").
        OutInfo("Stage: {0} (Lim: {1}) | Pe: {2} (Tgt: {3}) | {4}":Format(Stage:Number, g_StageLimit, Round(Ship:Periapsis), Round(tgtAp), g_MissionTag:Mission)).
        wait 2.
    }
}
else
{
    OutMsg("CircAtApo bypassed").
    OutInfo("Stage: {0} (Lim: {1}) | Pe: {2} (Tgt: {3}) | {4}":Format(Stage:Number, g_StageLimit, Round(Ship:Periapsis), Round(tgtAp), g_MissionTag:Mission)).
    wait 2.
}
set g_OnDeployActive to True.
ClearScreen.
DispMain(ScriptPath()).

set g_InOrbit to True.

local doneFlag to False.
OutMsg("Checking for g_LoopDelegates").
until doneFlag
{
    OutInfo("delegate count: " + g_LoopDelegates:Events:Keys:Length).
    if g_LoopDelegates:Events:Keys:Length = 0
    {
        OutInfo().
        OutInfo("", 1).
        set doneFlag to True.
    }
    else
    {
        OutInfo("Delegate: {0}":Format(g_LoopDelegates:Events:Keys[0]), 1).
        ExecGLoopEvents().
    }

    GetTermChar().
    if g_TermChar = Terminal:Input:DeleteRight
    {
        OutInfo("Skipping post-circularization delegate check").
        OutInfo("", 1).
        wait 1.

        OutInfo().
        OutInfo("", 1).
        set doneFlag to True.
    }
}
OutInfo().
// Run on-deploy routine
if g_LoopDelegates:Events:HasKey("OnDeploy")
{
    if g_LoopDelegates:Events:OnDeploy:Check:Call(g_LoopDelegates:Events:OnDeploy:Params)
    {
        g_LoopDelegates:Events:OnDeploy:Check:Action:Call(g_LoopDelegates:Events:OnDeploy:Params).
    }
}
set g_OnDeployActive to False.

if g_ReturnMissionList:Contains(Core:Tag:Split("|")[0]) and Ship:ModulesNamed("RealChuteModule"):Length > 0
{
    OutMsg("Executing reentry").
    runPath("0:/main/return/reentry", list(125000)).
}

set core:bootfilename to "".

if g_StageLimit > 0 SetNextStageLimit(0).

OutInfo().
OutMsg("Exiting missionExec").


// *- Local Functions
local function ExecCircBurn
{
    local burnTime to -1. // This will result in a leadtime of half of all burntime in the currently available stages (i.e., not limited by g_StageLimit)
    OutMsg("Executing circAtApo").
    wait 0.25.
    if tgtEcc > -1
    {
        // Set tgtAp to current Apoapsis; no sense in basing calculations of ideal vs reality
        local tgtApTagStr to ParseScalarShortString(tgtAp).
        set tgtAp to Round(Ship:Apoapsis).

        if tgtEcc < 0
        {
            set tgtPe to GetPeFromApEcc(tgtAp, abs(tgtEcc), Ship:Body).
        }
        else
        {
            set tgtPe to tgtAp.
            set tgtAp to GetApFromPeEcc(Ship:Apoapsis, tgtEcc, Ship:Body).
        }

        local curApTagStr to ParseScalarShortString(tgtAp).
        local curPeTagStr to ParseScalarShortString(tgtPe).
        set Core:Tag to Core:Tag:Replace(tgtApTagStr, curApTagStr):Replace("{0}|":Format(tgtEcc:ToString), "{0}|":Format(curPeTagStr)).

        // Make the changes to g_missionTag:Params
        set g_MissionTag:Params to list(g_MissionTag:Params[0], tgtAp, tgtPe).
    }
    else
    {
        if tgtPe > Ship:Apoapsis
        {
            set tgtAp to tgtPe.
            set tgtPe to Round(Ship:Apoapsis).
        }
        else if tgtPe < Ship:Body:Atm:Height
        {
            set tgtAp to Round(Ship:Apoapsis).
            set tgtPe to Ship:Body:Atm:Height + 25000.
        }
    }
    set g_MissionTag to ParseCoreTag(Core:Tag).

    if Career():CanMakeNodes 
    {
        runPath("0:/main/launch/circMnvAtApo", list(tgtAp, tgtPe, azObj)).
        // runPath("0:/main/launch/insertOrbitMnv", list(tgtPe, g_StageLimit)).
    }
    else
    {
        runPath("0:/main/launch/circAtApo", list(tgtAp, tgtPe, azObj)).
    }

    SendCoreMessage("P63_ORBIT", list(Core:Part:UID)).

    if g_StageLimitSet:Length > 1
    {
        OutMsg("[L42] SetNextStageLimit hit").
        SetNextStageLimit().
        OutMsg("SetNextStageLimit exit").
    }
    OutMsg("circAtApo complete").
}