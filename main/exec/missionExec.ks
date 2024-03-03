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
if Stage:Number >= g_StageLimit and Ship:Periapsis < tgtPe and g_MissionTag:Mission:MatchesPattern("^((PID)?Orbit|Circularize|SubOrbita|PIDSubOrbital)")
{
    local burnTime to -1. // This will result in a leadtime of half of all burntime in the currently available stages (i.e., not limited by g_StageLimit)

    OutMsg("Executing circAtApo").
    wait 0.25.
    // set Core:Part:Tag to Core:Part:Tag:Replace("Orbit|", "Circularize|").
    // set Core:Part:Tag to Core:Part:Tag:Replace("Orbit|{0}":Format(), "Circularize|{0}":Format(Round(Ship:Apoapsis)):Replace("km", "")).
    
    // local tgtAp to Ship:Apoapsis. // Ship:Body:ATM:Height + 25000.
    // local tgtPe to choose g_MissionTag:Params[2] if g_MissionTag:Params:Length > 2 else tgtAp.
    
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

        // Adjust make the changes to g_missionTag:Params
        set g_MissionTag:Params to list(g_MissionTag:Params[0], tgtAp, tgtPe).
    }
    else
    {
        // local tgtApTagStr to ParseScalarShortString(tgtAp).
        // local tgtPeTagStr to choose "-09876" if tgtPe < 0 else ParseScalarShortString(tgtPe).
        
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

        // local curApTagStr to ParseScalarShortString(tgtAp).
        // local curPeTagStr to ParseScalarShortString(tgtPe).
        // set Core:Tag to Core:Tag:Replace(tgtApTagStr, curApTagStr):Replace(tgtPeTagStr, curPeTagStr).
    }
    set g_MissionTag to ParseCoreTag(Core:Tag).

    // local tagSplit to Core:Part:Tag:Split("|").
    // if tagSplit:Length > 2
    // {
    //     local tagParam to tagSplit[1]:Split(";").
    //     if tagParam:Length > 2
    //     {
    //         local p2 to ParseStringScalar(tagParam[2]).
    //         if p2 <= 1
    //         {
    //             set tgtEcc to p2.
    //             if tgtEcc < 0
    //             {
    //                 set tgtPe to GetPeFromApEcc(tgtAp, abs(p2), Ship:Body).
    //             }
    //             else
    //             {
    //                 set tgtPe to Ship:Apoapsis.
    //                 set tgtAp to GetApFromPeEcc(Ship:Apoapsis, tgtEcc, Ship:Body).
    //             }
    //         }
    //         else if p2 > Ship:Apoapsis
    //         {
    //             set tgtAp to p2.
    //             set tgtPe to Ship:Apoapsis.
    //         }
    //         else
    //         {
    //             set tgtAp to Ship:Apoapsis.
    //             set tgtPe to p2.
    //         }
    //     }
    //     else
    //     {
    //         set tgtAp to ParseStringScalar(tagParam[1]).
    //         set tgtPe to tgtAp.
    //         if tgtAp <= Ship:Apoapsis
    //         {
    //             set Core:Part:Tag to Core:Part:Tag:Replace("{0}":Format(tagParam[1]), Round(Ship:Apoapsis):ToString).
    //         }
    //     }
    // }

    if Career():CanMakeNodes 
    {
        runPath("0:/main/launch/circMnvAtApo", list(tgtAp, tgtPe, azObj)).
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
// TODO: Extend Antenna Function

wait 0.25.
// Extend any solar panels
// ExtendSolarPanels().
set g_OnDeployActive to False.

if g_ReturnMissionList:Contains(Core:Tag:Split("|")[0]) and Ship:ModulesNamed("RealChuteModule"):Length > 0
{
    OutMsg("Executing reentry").
    runPath("0:/main/return/reentry").
}

set core:bootfilename to "".

if g_StageLimit > 0 SetNextStageLimit(0).

OutInfo().
OutMsg("Exiting missionExec").