@LazyGlobal off.
ClearScreen.

parameter params is list().

RunOncePath("0:/lib/libLoader.ks").
RunOncePath("0:/lib/launch.ks").

DispMain().

set g_MissionTag to ParseCoreTag(core:Part:Tag).
set g_MissionTag:Params to g_MissionTag:PARAMS.

local _azData   to g_azData.
local _tgtEcc   to -1.
local _stgAtETA to -1.
local _stpStg   to g_StageLimit.

if params:length > 0
{
    set _stpStg to params[0].
    if params:length > 1 set _stgAtETA to params[1].
    if params:length > 2 set _tgtEcc to params[2].
    if params:length > 3 set _azData to params[3].
}

if _azData:Length = 1
{
    set _azData to l_az_calc_init(g_MissionTag:Params[1], g_MissionTag:Params[0], _azData[0]).
}
else if _azData:Length = 0
{
    set _azData to l_az_calc_init(g_MissionTag:Params[1], g_MissionTag:Params[0], Ship:Latitude).
}

local eccCheckAtAp to True.
if _tgtEcc:IsType("String")
{
    if _tgtEcc:MatchesPattern("^(\+)")
    {
        set eccCheckAtAp to False.
        set _tgtEcc to _tgtEcc:SubString(1,_tgtEcc:Length).
    }
    else
    {
        set _tgtEcc to _tgtEcc:SubString(1,_tgtEcc:Length).
    }
    
    set _tgtEcc to _tgtEcc:ToNumber(0.0075).
}
else
{
    set _tgtEcc to 0.0075.
}
local tgtAp to choose g_MissionTag:Params[1] if eccCheckAtAp else GetApFromPeEcc(g_MissionTag:Params[1], _tgtEcc).
local tgtPe to choose GetPeFromApEcc(g_MissionTag:Params[1], _tgtEcc) if eccCheckAtAp else g_MissionTag:Params[1].

local eccApCheckDelegate to { 
    local result to False. 
    if Ship:Orbit:Eccentricity <= _tgtEcc
    {
        if Ship:Periapsis > tgtPe
        {
            set result to True.
        }
    }
    else
    {
        if Ship:Periapsis >= tgtPe
        {
            set result to True.
        }
    }
    return result.
}.
local eccPeCheckDelegate to {
    local result to False.
    
    if Ship:Orbit:Eccentricity >= _tgtEcc
    {
        if Ship:Apoapsis > tgtAp
        {
            set result to True.
        }
        else if Ship:Periapsis >= tgtPe.
        {
            set result to True.
        }
    }
    return result.
}.

local eccCheckDelegate to choose eccApCheckDelegate@ if eccCheckAtAp else eccPeCheckDelegate@.

// else
// {
//     set _azData to l_az_calc_init(g_MissionTag:Params[1], g_MissionTag:Params[0]).
// }

set g_StageLimit to _stpStg.

local steeringDelegate to GetOrbitalSteeringDelegate("AngErr:Sun", 0.9925).

// TODO: getting burntime from the burn time remaining of the engines to be burned
if _stgAtETA < 0 
{
    local stgWaitVal to 30. 
    OutMsg("Setting _stgAtETA").
    wait 0.25.
    // set _stgAtETA to 90.
    set g_ShipEngines_Spec to GetShipEnginesSpecs(Ship).
    if g_ShipEngines_Spec:HasKey("TotalBurnTimeEnabled")
    {
        set _stgAtETA to g_ShipEngines_Spec:TotalBurnTime / 2.
        OutMsg("Estimating burn time [{0}s]":Format(Round(_stgAtETA, 2))).
        wait 1.
    }
    else
    {
        // set stgWaitVal to 30.
        local doneFlag to False.

        OutInfo("-{0,-2}|-{1,-2}|-{2,-2}|-{3,-2}|-0+|+{3,-2}|+{2,-2}|+{1,-2}|+{0,-2}":Format("30","15","5","1")).
        OutInfo(" {0} | {1} | {2} | {3} | {4} | {5} | {6} | {7} | {8} ":Format(Char(8606), Char(8609), Char(8592), Char(8595), "0", Char(8593), Char(8594), Char(8607), Char(8608)), 1).

        set g_TermChar to "".
        Terminal:Input:Clear.

        local maxETAFlag to False.
        local maxETAIndicator to "".
        local userInputActive to False.

        set g_TS to Time:Seconds + 15.
        set g_TS to Min(g_TS, Max(Time:Seconds + ETA:Apoapsis - _stgAtETA - 5, g_TS)). // Adjust the user input timeout if we're already close to the burn point
    
        until Time:Seconds >= g_TS or doneFlag
        {
            set g_TermChar to "".
            local charReady to GetTermChar().
            local keyMapActiveStr to " {0} | {1} | {2} | {3} | {4} | {5} | {6} | {7} | {8} ".

            if g_TermChar = Terminal:Input:DownCursorOne
            {
                set stgWaitVal to stgWaitVal - 1.
                set keyMapActiveStr to " {0} | {1} | {2} |[{3}]| {4} | {5} | {6} | {7} | {8} ".
            }
            else if g_TermChar = Terminal:Input:UpCursorOne
            {
                set stgWaitVal to stgWaitVal + 1.
                set keyMapActiveStr to " {0} | {1} | {2} | {3} | {4} |[{5}]| {6} | {7} | {8} ".
            }
            else if g_TermChar = Terminal:Input:LeftCursorOne
            {
                set stgWaitVal to stgWaitVal - 5.
                set keyMapActiveStr to " {0} | {1} |[{2}]| {3} | {4} | {5} | {6} | {7} | {8} ".
            }
            else if g_TermChar = Terminal:Input:RightCursorOne
            {
                set stgWaitVal to stgWaitVal + 5.
                set keyMapActiveStr to " {0} | {1} | {2} | {3} | {4} | {5} |[{6}]| {7} | {8} ".
            }
            else if g_TermChar = Terminal:Input:DeleteRight
            {
                set stgWaitVal to stgWaitVal - 15.
                set keyMapActiveStr to " {0} |[{1}]| {2} | {3} | {4} | {5} | {6} | {7} | {8} ".
            }
            else if g_TermChar = "\"
            {
                set stgWaitVal to stgWaitVal + 15.
                set keyMapActiveStr to " {0} | {1} | {2} | {3} | {4} | {5} | {6} |[{7}]| {8} ".
            }
            else if g_TermChar = Terminal:Input:EndCursor
            {
                set stgWaitVal to stgWaitVal - 30.
                set keyMapActiveStr to "[{0}]| {1} | {2} | {3} | {4} | {5} | {6} | {7} | {8} ".
            }
            else if g_TermChar = Terminal:Input:HomeCursor
            {
                set stgWaitVal to stgWaitVal + 30.
                set keyMapActiveStr to " {0} | {1} | {2} | {3} | {4} | {5} | {6} | {7} |[{8}]".
            }
            else if g_TermChar = "0"
            {
                set stgWaitVal to 0.
                set keyMapActiveStr to " {0} | {1} | {2} | {3} |[{4}]| {5} | {6} | {7} | {8} ".
            }
            else if g_TermChar = Terminal:Input:Enter
            {
                set doneFlag to True.
            }

            if charReady
            {
                set g_TS to Time:Seconds + 15.
                set g_TermChar to "".
                set userInputActive to True.
            }
            
            set stgWaitVal to Max(0, Min(ETA:Apoapsis, stgWaitVal)).

            if doneFlag
            {
                OutMsg("stgWaitValue Set Value: {1}{0,-5}s":Format(Round(stgWaitVal, 2), maxETAIndicator)).
                OutInfo().
                OutInfo("", 1).
                OutInfo("", 2).
            }
            else
            {
                if stgWaitVal >= ETA:Apoapsis * 0.99975
                {
                    set maxETAFlag to True.
                }
                else
                {
                    set maxETAFlag to False.
                }
                set maxETAIndicator to choose "*" if maxETAFlag else "".

                OutMsg("Current stgWaitValue Value: {1}{0}s":Format(stgWaitVal, maxETAIndicator)).
                OutInfo(keyMapActiveStr:Format(Char(8606), Char(8609), Char(8592), Char(8595), "0", Char(8593), Char(8594), Char(8607), Char(8608)), 1).
                OutInfo("Continuing in {0,-5}s":Format(Round(g_TS - Time:Seconds, 2)), 2).
            }
        }
        set _stgAtETA to stgWaitVal.
        OutInfo().
        OutInfo("",1).
        OutInfo("",2).
        OutMsg("Finalized _stgAtETA Set Value: {1}{0,-5}s":Format(Round(_stgAtETA, 2), maxETAIndicator)).
        wait 1.
    }
}
// {
//     OutMsg("Calculating Burn Time").
//     local availableEngines_BT to 0.
//     local stageEngs           to list().
//     local stageEngs_BT        to 0.

//     from { local i to Stage:Number.} until i < g_StageLimit step { set i to i - 1.} do
//     {
//         set stageEngs to GetEnginesForStage(i).
//         local infoStr to "N/A".
//         if stageEngs:Length > 0
//         {
//             set stageEngs_BT to GetEnginesBurnTimeRemaining(stageEngs).
//             set availableEngines_BT to availableEngines_BT + stageEngs_BT.
//             set infoStr to Round(stageEngs_BT, 2) + "s".
//         }
//         OutInfo("Total    : {0}s ":Format(availableEngines_BT)).
//         OutInfo("Stage [{0}]: {1}  ":Format(i, infoStr), 1).
//     }
//     set _stgAtETA to max(12, max(0.001, availableEngines_BT) / 1.5).
// }
OutMsg("_stgAtETA: {0}":Format(Round(_stgAtETA, 2))).
wait 2.

OutMsg("Waiting until timestamp").
SAS Off.
set s_Val to steeringDelegate:Call().
lock steering to s_Val.

until ETA:Apoapsis <= _stgAtETA + 5
{
    // set s_Val to heading(compass_for(Ship, Ship:Prograde), 0, 0).
    set s_Val to steeringDelegate:Call().

    GetTermChar().
    if g_TermChar = Terminal:Input:HomeCursor
    {
        OutMsg("Warping to timestamp - 30s").
        wait 0.01.
        set warp to 1.
        wait until KUniverse:TimeWarp:IsSettled.
        WarpTo(_stgAtETA - 30).
    }
    else if g_TermChar = Terminal:Input:EndCursor
    {
        set warp to 0.
        OutMsg("Warp Cancelled").
        wait until KUniverse:TimeWarp:IsSettled.
    }
    else if g_TermChar = Terminal:Input:RightCursorOne
    {
        set _stgAtETA to _stgAtETA + 5.
    }
    else if g_TermChar = Terminal:Input:UpCursorOne
    {
        set _stgAtETA to _stgAtETA + 1.
    }
    else if g_TermChar = Terminal:Input:LeftCursorOne
    {
        set _stgAtETA to _stgAtETA - 5.
    }
    else if g_TermChar = Terminal:Input:DownCursorOne
    {
        set _stgAtETA to _stgAtETA - 1.
    }
    set g_TermChar to "".

    OutInfo("Time Remaining: {0}s  ":Format(round(ETA:Apoapsis - _stgAtETA, 2))).
    DispLaunchTelemetry().
}

// local nextEngs to GetNextEngines().
// local nextStageIsSep to false.
// if nextEngs:Length > 0
// {
//     for eng in nextEngs
//     {
//         if eng:tag = "" and g_PartInfo:Engines:SepRef:Contains(eng:name)
//         {
//             set nextStageIsSep to true.
//         }
//     }
// }

// if not nextStageIsSep
// {
    RCS on.
    OutMsg("Performing ullage manuever").
    set Ship:Control:Fore to 1.
// }
// else
// {
//     OutMsg("Sep motors detected, awaiting ignition").
//     wait 1.
// }

until ETA:Apoapsis <= _stgAtETA
{
    set s_Val to steeringDelegate:Call().
    OutInfo("Time Remaining: {0}s  ":Format(round(ETA:Apoapsis - _stgAtETA, 2))).
    DispLaunchTelemetry().
    wait 0.01.
}

OutMsg("Arming AutoStaging to {0}":Format(_stpStg)).
OutInfo().

set t_Val to 1.
lock throttle to t_Val.
ArmAutoStagingNext(_stpStg, 1, 2).
wait 0.01.
set Ship:Control:Fore to 0.

local rollFlag to false.
local apoFlag to false.

until Stage:Number = _stpStg 
{
    set g_ActiveEngines to GetActiveEngines().
    set g_ActiveEngines_Data to GetEnginesPerformanceData(GetActiveEngines()).
    if g_LoopDelegates:HasKey("Staging")
    {
        if g_LoopDelegates:Staging:Check:Call() = 1
        {
            g_LoopDelegates:Staging["Action"]:Call().
        }
    }
    
    if g_LoopDelegates["Events"]:Keys:Length > 0 
    {
        ExecGLoopEvents().
    }

    GetTermChar().
    if g_TermChar = "e"
    {
        if Ship:Control:Roll < 0 
        {
            set Ship:Control:Roll to 0.
            set rollFlag to false.
        }
        else
        {
            set Ship:Control:Roll to 1.
            set rollFlag to true.
        }
    }
    else if g_TermChar = "q"
    {
        if Ship:Control:Roll > 0 
        {
            set Ship:Control:Roll to 0.
            set rollFlag to false.
        }
        else
        {
            set Ship:Control:Roll to -1.
            set rollFlag to true.
        }
    }
    set g_TermChar to "".

    if Ship:Apoapsis >= tgtAp - 10000 and Ship:Apoapsis <= tgtAp + 10000 
    {
        set apoFlag to true.
    }


    set s_Val to choose steeringDelegate:Call():Vector if rollFlag else choose Ship:Prograde if apoFlag else steeringDelegate:Call().
    
    DispLaunchTelemetry().
    wait 0.01.
}
set g_TS to Time:Seconds + 10.

local thrustFlag to false.
until thrustFlag or Time:Seconds >= g_TS
{
    set g_ActiveEngines_Data to GetEnginesPerformanceData(GetActiveEngines()).
    if g_ActiveEngines_Data:HasKey("Thrust") 
    {
        if g_ActiveEngines_Data:Thrust <= 0.01
        {
            set thrustFlag to true.
        }
    }
    wait 0.01.
}

wait 0.25.
local MECOFlag to false.
OutMsg("Final Stage").
until eccCheckDelegate:Call() or MECOFlag
{
    GetTermChar().
    if g_TermChar = "e"
    {
        if Ship:Control:Roll < 0 
        {
            set Ship:Control:Roll to 0.
            set rollFlag to false.
        }
        else
        {
            set Ship:Control:Roll to 1.
            set rollFlag to true.
        }
    }
    else if g_TermChar = "q"
    {
        if Ship:Control:Roll > 0 
        {
            set Ship:Control:Roll to 0.
            set rollFlag to false.
        }
        else
        {
            set Ship:Control:Roll to -1.
            set rollFlag to true.
        }
    }
    set g_TermChar to "".

    set s_Val to choose steeringDelegate:Call():Vector if rollFlag else steeringDelegate:Call().
    set g_ActiveEngines_Data to GetEnginesPerformanceData(GetActiveEngines()).
    if g_ActiveEngines_Data:HasKey("Thrust") 
    {
        if g_ActiveEngines_Data:Thrust <= 0.01
        {
            set MECOFlag to true.
        }
    }

    DispLaunchTelemetry().
    wait 0.01.
}
set t_Val to 0.
wait 0.01.
if Ship:AvailableThrust > 0.01
{
    OutMsg("Waiting for engine burnout").
    until g_ActiveEngines_Data:Thrust <= 0.01
    {
        set s_Val to steeringDelegate:Call().
        set g_ActiveEngines_Data to GetEnginesPerformanceData(GetActiveEngines()).
        DispLaunchTelemetry().
        wait 0.01.
    }
}
unlock Throttle.
unlock Steering.

OutInfo().
OutMsg("circAtApo complete").