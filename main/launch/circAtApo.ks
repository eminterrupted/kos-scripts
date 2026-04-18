@LazyGlobal off.
ClearScreen.

parameter params is list().

RunOncePath("0:/lib/libLoader.ks").
RunOncePath("0:/lib/launch.ks").

set g_MainProc to ScriptPath().
DispMain().

set g_TS to Time:Seconds + 3.

until g_TermChar = Terminal:Input:Enter or Time:Seconds >= g_TS
{
    GetTermChar().
    if not g_Debug
    {
        CheckKerbaliKode().
    }
    else
    {
        Break.
    }
    wait 0.01.
}

set g_MissionTag to ParseCoreTag(Core:Part:Tag).

local azData    to g_azData.

local pitchOffset to 0.
local curPitchOffset to 1.125.

local tgtAp     to Ship:Apoapsis.
local tgtPe     to Ship:Apoapsis.
local tgtInc    to g_MissionTag:Params[0].
local transferBurn to False.

if g_MissionTag:Params:Length > 2
{
    if g_MissionTag:Params[2] > tgtAp * 1.1 set transferBurn to True.
    set tgtAp to g_MissionTag:Params[2].
}

if params:length > 0
{
    if params[0] > tgtAp * 1.1 set transferBurn to True.
    set tgtAp to params[0].
    if params:length > 1 set tgtPe to params[1].
    if params:length > 2 set azData to params[2].
}
if tgtAp > Ship:Apoapsis
{
    set tgtAp to Ship:Apoapsis.
}

if azData:Length = 1
{
    set azData to l_az_calc_init(tgtAp, tgtInc, azData[0]).
    set g_azData to azData.
}
else if azData:Length = 0
{
    set azData to l_az_calc_init(tgtAp, tgtInc, Ship:Latitude).
    set g_azData to azData.
}
set g_AngDependency to InitAscentAng_Next(tgtInc, tgtAp, 1, 2.5, 22.5, True, list(0.0125, 0.000925, 0.0005, 1)). // P, I, D, ChangeRate (upper / lower bounds for PID)

//local dvNeeded to CalcDvHoh(Ship:Periapsis, 0, Ship:Apoapsis, Ship:Body)[0].
local dvNeeded to CalcDvBE(Ship:Periapsis, Ship:Apoapsis, tgtPe, tgtAp, Ship:Apoapsis, "PE")[1].
OutInfo("dvNeeded: {0}":Format(Round(dvNeeded, 1)), 1).
local burnDur  to CalcBurnDur(dvNeeded).


// Test area 
// #region
    local fullDur is 0.
    local halfDur is 0.
    local burnTS  is 0.
    local burnEngs      is list().
    local burnEngsSpec  is lex().

    local burnUllageTime is 0.
    local ullageLeadSecs to 15.
    local ullageTS       to 0.
    local ullageFlag is false.
    
    set fullDur to burnDur[0].
    set halfDur to burnDur[3].
    
    set burnTS to (Time:Seconds + ETA:Apoapsis) - halfDur.
    
    set g_ActiveEngines to GetActiveEngines().
    set g_ActiveEngines_Specs to GetEnginesSpecs(g_ActiveEngines).

    set g_SteeringDelegate to GetOrbitalSteeringDelegate("Flat:Sun").

    local g_ActiveSpecs to lex("ALLOWRESTART", True, "IGNITIONS", 0, "BURNTIMEREMAINING", 0, "SPOOLTIME", 0, "ULLAGE", False).

    for eng in g_ActiveEngines
    {
        local engSpec to g_ShipEngines_Specs[eng:Stage]:EngSpecs[eng:UID].
        g_ActiveSpecs:Add(eng:UID, engSpec).

        if eng:AllowRestart
        {
            set g_ActiveSpecs:IGNITIONS to eng:Ignitions.
            if not g_ActiveSpecs:ULLAGE
            {
                set g_ActiveSpecs:ULLAGE to eng:Ullage.
            }
            // OutDebug("{0}: {1} | {2} | {3}":Format(eng:name, eng:AllowRestart, eng:Ignitions, eng:Ullage), 5).
        }
        else
        {
            set g_ActiveSpecs:AllowRestart to False.
            // OutDebug("{0}: {1} |":Format(eng:name, eng:AllowRestart), 5).
        }
    }
    set g_ActiveSpecs:BurnTimeRemaining to choose g_ActiveEngines_Specs:BurnTimeRemaining if g_ActiveEngines_Specs:BurnTimeRemaining > 0 else 0.
    
    local useNext to False.
    if g_ActiveSpecs:AllowRestart
    {
        if g_ActiveSpecs:Ignitions = 0
        {
            // OutDebug("UseNext Reason: Ignitions = 0").
            set useNext to True.
        }
        else if g_ActiveSpecs:BurnTimeRemaining <= g_ActiveSpecs:SpoolTime + 0.25 
        {
            // OutDebug("UseNext Reason: ratedBurnTime <= SpoolTime + 0.25").
            set useNext to True.
        }
    }
    else
    {
        // OutDebug("UseNext Reason: NoRestart Capability").
        set useNext to True.
    }

    if useNext 
    {
        set burnEngs to GetNextEngines().
        set burnEngsSpec to GetEnginesSpecs(burnEngs).
    }
    else
    {
        set burnEngs to g_ActiveEngines.
        set burnEngsSpec to g_ActiveSpecs.
    }
    // Initiate the burn with enough time for engine spoolup to occur.
    set burnTS to burnTS - (burnEngsSpec:spooltime * 1.12). // This allows for spool time + adds a bit of buffer

    // If ullage is needed, calcualate that TS here
    if burnEngsSpec:ULLAGE
    {
        set ullageFlag to true.
        set burnUllageTime to Max(3, ullageLeadSecs * (1 - burnEngs[0]:FuelStability)).
        set ullageTS to burnTS - burnUllageTime.
    }
    
    // Setup control
    local rollUpVector to { return -Body:Position.}.


    set s_Val to lookDirUp(Ship:Orbit:Velocity:Orbit, rollUpVector:Call()).
    set t_Val to 0.
    wait 0.01.
    lock steering to s_Val.
    
    // Determine which engines will be used to start the burn
    local ignitionsRemaining to 0.
    local nextBurnEngines to list().
    if g_ActiveEngines:Length > 0
    {
        set nextBurnEngines to g_ActiveEngines.
        for eng in nextBurnEngines
        {
            set ignitionsRemaining to max(ignitionsRemaining, eng:Ignitions).
        }
    }
    if ignitionsRemaining
    {
        set g_NextEngines to GetNextEngines(Stage:Number - 1).
        set nextBurnEngines to g_NextEngines.
    }
    local predictedEngBurnTime to GetPredictedBurnTime2(nextBurnEngines).
    
    // Do we need to initiate spin stabilization prior to the burn?
    local preSpin is 0.
    local spinTS  is 0.
    
    for p in Ship:PartsTaggedPattern("SpinDC\|\d+")
    {
        OutInfo("SpinDC Found").
        local pSplit to p:Tag:Split("|").
        OutInfo(fullDur + " | " + burnEngsSpec:BurnTimeRemaining, 2).
        if p:Stage = Stage:Number - 1 
        {
            if g_ActiveEngines:Length = 0
            {
                OutInfo("Stage Correct").
                set preSpin to choose pSplit[1]:ToNumber(18) if pSplit:Length > 1 else 12.
            }
            else
            {
                local spinDur to choose pSplit[1]:ToNumber(18) if pSplit:Length > 1 else 12.
                if fullDur - spinDur > predictedEngBurnTime
                {
                    set preSpin to spinDur.
                }
            }
        }
        set spinTS to burnTS - preSpin.
        set g_SpinArmed to preSpin > 0.
    }
    
    // Determine the overall lead time required to be ready at burnTS
    local burnLeadTime is 12 + Max(burnUllageTime, preSpin).
    local burnLeadTS is burnTS - burnLeadTime.

    // Do we have any solid kick stages that 
    // require cutoff at a certain dV remaining? 
    local dvStagingArmed is false.
    if Ship:PartsTaggedPattern("dvst(g|age|aging)\|(dv|stg)\|\d*"):Length > 0
    {
        set dvStagingArmed to ArmDVStaging().
        OutInfo("dvStagingArmed: {0}":Format(dvStagingArmed), 2).
    }
    
    // Wait until the burn
    // Contains ullage and spin checks and actions
    local _line is 2.
    local ullageExecTS is 0.
    local settleProgress is 0.
    local warpAble is false.
    local warpFlag is false.
    local warpLeadSecs is 3.
    local warpTS is 0.

    until time:seconds >= burnTS
    {
        set g_line to _line - 1.

        GetTermChar().

        // Recalculate burn ullage time based on current fuel stability
        if ullageFlag
        {
            if Time:Seconds < ullageTS
            {
                set burnUllageTime to Max(1, 15 - (burnEngs[0]:FuelStability * 30)).
                set ullageTS to burnTS - burnUllageTime.
                set burnLeadTime to Max(burnLeadTime, burnUllageTime).
                set burnLeadTS to ullageTS.
            }
            else 
            {
                set Ship:Control:Fore to 1.
                if ullageExecTS = 0
                {
                    set ullageExecTS to Time:Seconds.
                }
                else
                {
                    if Time:Seconds <= burnTS - 1
                    {
                        set Ship:Control:Fore to Min(1, 0.2 + (1 - burnEngs[0]:FuelStability)).
                    }
                    else if Time:Seconds <= burnTS
                    {
                        set Ship:Control:Fore to 1.
                    }
                    else
                    {
                        set Ship:Control:Fore to 0.
                        set ullageExecTS to 0.
                    }
                }
            }
        }
        OutInfo("Burn ETA: Lead: {0}s | Ignition: {1} ":Format(burnLeadTime, TimeSpan(burnTS - Time:Seconds):Full)).

        local hdgPit is compass_and_pitch_for(Ship, Ship:Orbit:Velocity:Orbit).

        if g_SpinArmed
        {
            if Time:Seconds >= spinTS
            {
                set Ship:Control:Roll to 1.
                OutInfo("Spin Started (T{0}) ":Format(Round(spinTS - Time:Seconds, 2)), 2).
                set s_Val to Ship:Facing:Vector.
            }
            else if Time:Seconds >= burnTS
            {
                set Ship:Control:Roll to 0.
                OutInfo("Spin Stopped                       ", 2).
                set g_SpinArmed to false.
                set s_Val to g_SteeringDelegate:Call():Vector.
            }
            else 
            {
                OutInfo("Spin Armed (T-{0}) ":Format(Round(spinTS - Time:Seconds, 2)), 2).
                // set s_Val to lookDirUp(Ship:Orbit:Velocity:Orbit, rollUpVector:Call()).
                set s_Val to g_SteeringDelegate:Call():Vector.
            }
        }
        else
        {
            // set s_Val to lookDirUp(Ship:Orbit:Velocity:Orbit, rollUpVector:Call()).
            set s_Val to g_SteeringDelegate:Call():Vector.
            if settleProgress > 3
            {
                if VAng(Ship:Facing:Vector, Ship:Orbit:Velocity:Orbit) < 0.25
                {
                    set settleProgress to settleProgress + 1.
                    wait 1.
                }
                else
                {
                    set settleProgress to 0.
                }
                OutInfo("Settle Progress: [{0}] (3 needed)":Format(settleProgress), 2).
            }
        }

        local burnFlags to list().
        if ullageFlag burnFlags:Add("UL").
        if g_SpinArmed burnFlags:Add("SP").
        OutInfo("Burn Flags: [{0}] ":Format(burnFlags:Join("|")), 1).

        if warp = 0 
        {
            wait until KUniverse:TimeWarp:IsSettled.
            set warpFlag to False.
        }

        if not warpFlag 
        {
            set warpAble to Time:Seconds < burnLeadTS - 15.
            if warpAble 
            {
                OutMsg("Press Shift+W to warp to warpZone [maneuver - {0}s]":Format(Round(burnLeadTime + warpLeadSecs, 2))).
            }
            else
            {
                OutMsg("Warp Disallowed").
            }
        }
        else
        {
            if warpTS > burnLeadTS
            {
                OutInfo("warpTS > burnLeadTS, cancelling").
                set KUniverse:TimeWarp:Rate to 0.
                wait until KUniverse:TimeWarp:IsSettled.
                set warpFlag to false.
                if Time:Seconds < warpTS
                {
                    set burnLeadTime   to 12 + Max(burnUllageTime, preSpin).
                    set burnLeadTS     to burnTS - burnLeadTime.
                    set warpTS to burnLeadTS - warpLeadSecs.
                    OutInfo("Reinitiating warp based on new burnLeadTS").
                    set warpFlag to true.
                    WarpTo(warpTS).
                }
            }
            set warpAble to Time:Seconds < burnLeadTS - 15.
        }


        if g_TermChar = ""
        {
        }
        else
        {
            if g_TermChar = Char(87) // 'W'
            {
                if warpAble
                {
                    set warpFlag to True. 
                    OutMsg("Warping to maneuver").
                    clr(cr()).
                    if Kuniverse:TimeWarp:Mode = "PHYSICS"
                    {
                        set Warp to 0.
                        wait until KUniverse:TimeWarp:IsSettled.
                        set Kuniverse:Timewarp:Mode to "RAILS".
                    }
                    set warpTS to burnLeadTS - warpLeadSecs.
                    WarpTo(warpTS).
                }
                set g_TermChar to "".
            }
            // else if g_TermChar = Char(82) // 'R'
            // {
            //     OutInfo("Recalculating burn parameters").
            //     clr(cr()).
            //     clr(cr()).
            //     wait 0.1.
            //     set burnDur to CalcBurnDur(_inNode:deltaV:mag).
            //     set fullDur to burnDur[0].
            //     set halfDur to burnDur[3].

            //     set burnTS to _inNode:time - halfDur. 
            //     set g_TermChar to "".
            // }
            else if g_TermChar = Char(101) // 'e'
            {
                set Ship:Control:Roll to Min(1, Max(-1, Ship:Control:Roll + 0.25)).
                OutInfo("Spin Right: " + Ship:Control:Roll).
            }
            else if g_TermChar = Char(69) // 'E'
            {
                set Ship:Control:Roll to 1.
                OutInfo("Spin Right: " + Ship:Control:Roll).
            }
            else if g_TermChar = Char(113) // 'q'
            {
                set Ship:Control:Roll to Min(1, Max(-1, Ship:Control:Roll - 0.25)).
                OutInfo("Spin Left: " + Ship:Control:Roll).
            }
            else if g_TermChar = Char(81) // 'Q'
            {
                set Ship:Control:Roll to -1.
                OutInfo("Spin Left: " + Ship:Control:Roll).
            }
            else if g_TermChar = Char(115) // s
            {
                set SteeringManager:RollTorqueFactor to choose 0 if SteeringManager:RollTorqueFactor > 0 else 1.
            }
            else if g_TermChar = Char(83) // S
            {
                set Ship:Control:Roll to 0.
            }
            else if g_TermChar = "="
            {
                set burnLeadTime to burnLeadTime + 5.
            }
            else if g_TermChar = "-"
            {
                set burnLeadTime to burnLeadTime - 5.
            }
            else if g_TermChar = "+"
            {
                set burnLeadTime to burnLeadTime + 5.
            }
            else if g_TermChar = "_"
            {
                set burnLeadTime to burnLeadTime - 5.
            }
            set g_TermChar to "".
        }
        // OutInfo("Mnv | Eng Time : {0} | {1}":Format(Round(burnDur[0], 2), Round(g_ActiveSpecs:RATEDBURNTIME, 2)), 2).
    }

// // TODO Experimental
// if false
// {
//     local burnObj to CalcBurnStageData(dvNeeded).
// }


// #endregion

// set g_ActiveEngines to GetActiveEngines().
// set g_ActiveEngines_Spec to GetEnginesSpecs(g_ActiveEngines).



// local warpPadding to 15.
// local spinDCs to Ship:PartsTaggedPattern("SpinDC\|\d*").
// set preSpin to 0.

// // Do we need to initiate spin stabilization prior to the burn?
// for p in spinDCs
// {
//     OutInfo("SpinDC Found").
//     local pSplit to p:Tag:Split("|").
//     // OutInfo(fullDur[1] + " | " + burnEngsSpec:BurnTimeRemaining, 2).
//     if p:Stage = Stage:Number - 1 
//     {
//         if g_ActiveEngines:Length = 0
//         {
//             OutInfo("Stage Correct").
//             set preSpin to choose pSplit[1]:ToNumber(18) if pSplit:Length > 1 else 12.
//         }
//         else
//         {
//             local spinDur to choose pSplit[1]:ToNumber(18) if pSplit:Length > 1 else 12.
//             if burnDur[1] - spinDur > predictedEngBurnTime
//             {
//                 set preSpin to spinDur.
//             }
//         }
//     }
//     set spinTS to burnTS - preSpin.
//     set g_SpinArmed to preSpin > 0.
// }

// // local spinDCs to Ship:PartsTaggedPattern("SpinDC\|\d*").
// // if spinDCs:Length > 0
// // {
// //     OutInfo("Arming SpinDC"). 
// //     wait 1.
// //     set g_SpinArmed to SetupSpinStabilizationEventHandler().
// //     set warpPadding to warpPadding + Ship:PartsTaggedPattern("SpinDC\|\d*")[0]:Tag:Replace("SpinDC|",""):ToNumber(9).
// // }



// local burnTS to choose (Time:Seconds + ETA:Apoapsis - burnDur[3]) if ETA:Apoapsis < ETA:Periapsis else Time:Seconds + 10.
// local mecoTS to burnTS + burnDur[1].
// local burnLeadTime to warpPadding.
// local warpToTS to burnTS - burnLeadTime.

local tgtCheckDelAP to { return (Ship:Apoapsis >= tgtAp and Ship:Periapsis >= Max(Ship:Body:Atm:Height + 5000, tgtPe * 0.9925)). }.
local tgtCheckDelPE to { return Ship:Periapsis >= tgtPe.}.
local tgtCheckDel to choose tgtCheckDelAP@ if transferBurn else tgtCheckDelPE@.

// set g_ActiveEngines to GetActiveEngines().
// set g_ActiveEngines_Data to GetEnginesPerformanceData(g_ActiveEngines).
// set g_ActiveEngines_Spec to GetEnginesSpecs(g_ActiveEngines).

// set g_SteeringDelegate to GetOrbitalSteeringDelegate("Flat:Sun", 0.9925).

// OutMsg("Waiting until timestamp").
// SAS Off.

// set s_Val to g_SteeringDelegate:Call().
// lock steering to s_Val.

// local warpFlag to False.

// until Time:Seconds >= burnTS - g_UllageDefault
// {
//     // set s_Val to heading(compass_for(Ship, Ship:Prograde), 0, 0).
//     GetTermChar().

//     set s_Val to g_SteeringDelegate:Call().
    
//     local burnETA to Round(burnTS - Time:Seconds, 2).

//     if Kuniverse:TimeWarp = 0 set warpFlag to False.
//     // if g_TermChar = Terminal:Input:HomeCursor
//     // {
//     //     OutMsg("Warping to timestamp - 30s").
//     //     wait 0.01.
//     //     set warp to 1.
//     //     wait until KUniverse:TimeWarp:IsSettled.
//     //     WarpTo(burnTS - 30).
//     // }
//     // else if g_TermChar = Terminal:Input:EndCursor
//     // {
//     //     set warp to 0.
//     //     OutMsg("Warp Cancelled").
//     //     wait until KUniverse:TimeWarp:IsSettled.
//     // }
//     if not warpFlag OutMsg("Press Shift+W to warp to [maneuver - {0}s]":Format(burnLeadTime)).
    
//     // if g_termChar = ""
//     // {
//     // }
//     // else if g_termChar = Char(87)
//     // {
//     //     if burnETA > burnLeadTime 
//     //     {
//     //         set warpFlag to True. 
//     //         OutMsg("Warping to maneuver").
//     //         OutInfo().
//     //         OutInfo("", 1).
//     //         OutInfo("", 2).
//     //         WarpTo(warpToTS).
//     //     }
//     //     else
//     //     {
//     //         OutMsg("Maneuver <= {0}s, skipping warp":Format(burnLeadTime)).
//     //     }
//     //     set g_termChar to "".
//     // }
    
//     local warpAble to burnETA > 15.

//     if g_TermChar = ""
//     {
//     }
//     else
//     {
//         if g_TermChar = Char(87) // 'W'
//         {

//             if warpAble
//             {
//                 set warpFlag to True. 
//                 OutMsg("Warping to maneuver").
//                 clr(cr()).
//                 if Kuniverse:TimeWarp:Mode = "PHYSICS"
//                 {
//                     set Warp to 0.
//                     wait until KUniverse:TimeWarp:IsSettled.
//                     set Kuniverse:Timewarp:Mode to "RAILS".
//                 }
//                 set warpToTS to burnTS - burnLeadTime - 1.5.
//                 WarpTo(warpToTS).
//             }
//             set g_TermChar to "".
//         }
//         else if g_TermChar = Char(101) // 'e'
//         {
//             set Ship:Control:Roll to Min(1, Max(-1, Ship:Control:Roll + 0.25)).
//             OutInfo("Spin Right: " + Ship:Control:Roll).
//         }
//         else if g_TermChar = Char(69) // 'E'
//         {
//             set Ship:Control:Roll to 1.
//             OutInfo("Spin Right: " + Ship:Control:Roll).
//         }
//         else if g_TermChar = Char(113) // 'q'
//         {
//             set Ship:Control:Roll to Min(1, Max(-1, Ship:Control:Roll - 0.25)).
//             OutInfo("Spin Left: " + Ship:Control:Roll).
//         }
//         else if g_TermChar = Char(81) // 'Q'
//         {
//             set Ship:Control:Roll to -1.
//             OutInfo("Spin Left: " + Ship:Control:Roll).
//         }
//         else if g_TermChar = Char(115) // s
//         {
//             set SteeringManager:RollTorqueFactor to choose 0 if SteeringManager:RollTorqueFactor > 0 else 1.
//         }
//         else if g_TermChar = Char(83) // S
//         {
//             set Ship:Control:Roll to 0.
//         }
//         else if g_TermChar = "="
//         {
//             set burnLeadTime to burnLeadTime + 5.
//         }
//         else if g_TermChar = "-"
//         {
//             set burnLeadTime to burnLeadTime - 5.
//         }
//         else if g_TermChar = "+"
//         {
//             set burnLeadTime to burnLeadTime + 5.
//         }
//         else if g_TermChar = "_"
//         {
//             set burnLeadTime to burnLeadTime - 5.
//         }
//         set g_TermChar to "".
//     }

//     if not warpFlag 
//     {
//         set burnLeadTime to UpdateTermScalar(burnLeadTime, list(1, 5, 15, 30)).
//         set warpToTS to (burnTS - burnLeadTime).
//     }
//     set g_TermChar to "".

//     OutInfo("Time Remaining: {0}s  ":Format(burnETA), 2).
//     DispLaunchTelemetry().
// }
// OutInfo("",-1).
// RCS on.
// OutMsg("Performing ullage manuever").
// set Ship:Control:Fore to 1.

// until Time:Seconds >= burnTS
// {
//     set s_Val to g_SteeringDelegate:Call().
//     OutInfo("Time Remaining: {0}s  ":Format(round(burnTS - Time:Seconds, 2))).
//     DispLaunchTelemetry().
    
//     GetTermChar().

//     if g_TermChar = ""
//     {
//     }
//     else
//     {
//         if g_TermChar = Char(82) // 
//         {
//             OutInfo("Recalculating burn parameters").
//             clr(cr()).
//             clr(cr()).
//             wait 0.1.
//             set burnDur to CalcBurnDur(_inNode:deltaV:mag).
//             set fullDur to burnDur[0].
//             set halfDur to burnDur[3].

//             set burnTS to _inNode:time - halfDur. 
//             set g_TermChar to "".
//         }
//         else if g_TermChar = Char(101) // 'e'
//         {
//             set Ship:Control:Roll to Min(1, Max(-1, Ship:Control:Roll + 0.25)).
//             OutInfo("Spin Right: " + Ship:Control:Roll).
//         }
//         else if g_TermChar = Char(69) // 'E'
//         {
//             set Ship:Control:Roll to 1.
//             OutInfo("Spin Right: " + Ship:Control:Roll).
//         }
//         else if g_TermChar = Char(113) // 'q'
//         {
//             set Ship:Control:Roll to Min(1, Max(-1, Ship:Control:Roll - 0.25)).
//             OutInfo("Spin Left: " + Ship:Control:Roll).
//         }
//         else if g_TermChar = Char(81) // 'Q'
//         {
//             set Ship:Control:Roll to -1.
//             OutInfo("Spin Left: " + Ship:Control:Roll).
//         }
//         else if g_TermChar = Char(115) // s
//         {
//             set SteeringManager:RollTorqueFactor to choose 0 if SteeringManager:RollTorqueFactor > 0 else 1.
//         }
//         else if g_TermChar = Char(83) // S
//         {
//             set Ship:Control:Roll to 0.
//         }
//         else if g_TermChar = "="
//         {
//             set burnLeadTime to burnLeadTime + 5.
//         }
//         else if g_TermChar = "-"
//         {
//             set burnLeadTime to burnLeadTime - 5.
//         }
//         else if g_TermChar = "+"
//         {
//             set burnLeadTime to burnLeadTime + 5.
//         }
//         else if g_TermChar = "_"
//         {
//             set burnLeadTime to burnLeadTime - 5.
//         }
//         set g_TermChar to "".
//     }
//     // OutInfo("Mnv | Eng Time : {0} | {1}":Format(Round(burnDur[0], 2), Round(g_ActiveSpecs:RATEDBURNTIME, 2)), 2).
//     wait 0.01.
// }

OutMsg("Arming AutoStaging to {0}":Format(g_StageLimit)).
OutInfo().

set t_Val to 1.
lock throttle to t_Val.

set g_HotStagingArmed   to ArmHotStaging().
set g_SpinArmed         to SetupSpinStabilizationEventHandler().

local onStageParts to Ship:PartsTaggedPattern("^OnStage").
if onStageParts:Length > 0
{
    set g_OnStageEventArmed to SetupOnStageEventHandler(onStageParts).
}

// #TODO: Implement circ event handlers
// local eventParts to Ship:PartsTaggedPattern("^Circ\|.*").
// local eventPartCount to 0.
// if eventParts:Length > 0 
// {
//     set eventPartCount to ArmAscentEvents(eventParts).
// }

local autoStageResult to ArmAutoStagingNext(g_StageLimit, 1, 1).
set g_AutoStageArmed  to choose True if autoStageResult = 1 else False.

wait 0.01.
set Ship:Control:Fore to 0.

set g_SteeringDelegate to GetOrbitalSteeringDelegate("Flat:Sun").// if transferBurn else GetOrbitalSteeringDelegate("PIDApoErr:Sun"). // GetOrbitalSteeringDelegate("AzPro:Sun").

set pitchOffset to 0.
local maxPitchOffset to 44.

local rollFlag to false.
local doneFlag to false.

until Stage:Number <= g_StageLimit or doneFlag// or Time:Seconds >= mecoTS or apoFlag
{
    set g_ActiveEngines to GetActiveEngines().
    set g_ActiveEngines_Data to GetEnginesPerformanceData(GetActiveEngines()).
    
    if g_LoopDelegates:HasKey("Staging")
    {
        if g_HotStagingArmed and g_NextHotStageID = Stage:Number - 1
        { 
            if g_LoopDelegates:Staging:HotStaging:HasKey(g_NextHotStageID)
            {
                if g_LoopDelegates:Staging:HotStaging[g_NextHotStageID]:Check:CALL()
                {
                    g_LoopDelegates:Staging:HotStaging[g_NextHotStageID]:Action:CALL().
                }
            }
        }
        else
        {
            if g_LoopDelegates:Staging:Check:Call() = 1
            {
                g_LoopDelegates:Staging["Action"]:Call().
            }
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
    else if g_TermChar = Char(115)
    {
        set pitchOffset to Min(32.5, pitchOffset + 1.25).
    }
    else if g_TermChar = Char(119)
    {
        set pitchOffset to Max(-22.5, pitchOffset - 1.25).
    }
    else if g_TermChar = Char(83)
    {
        set pitchOffset to Min(32.5, pitchOffset + 5).
    }
    else if g_TermChar = Char(87)
    {
        set pitchOffset to Max(-22.5, pitchOffset - 5).
    }
    else if g_TermChar = Char(79)
    {
        set pitchOffset to 0.
    }
    set g_TermChar to "".

    // if (Ship:Periapsis >= tgtPe - 5000 and Ship:Periapsis <= tgtPe + 5000)
    if tgtCheckDel:Call() // Ship:Periapsis >= tgtPe - 5000
    {
        set doneFlag to true.
    }
    // else 
    // {
    //     OutInfo("TIME TO MECO: {0} ":Format(Round(mecoTS - Time:Seconds))).
    // }

    set s_Val to g_SteeringDelegate:Call():Vector.

    // set s_Val to choose g_SteeringDelegate:Call():Vector if rollFlag else choose Ship:Prograde if doneFlag else Min(maxPitchOffset, Max(-maxPitchOffset,g_SteeringDelegate:Call() + r(0, pitchOffset, 0))).
    // set s_Val to choose g_SteeringDelegate:Call():Vector if rollFlag else choose Ship:Prograde if doneFlag else Min(maxPitchOffset, Max(-maxPitchOffset, Min((progradePitch + curPitchOffset), Max((progradePitch - curPitchOffset), g_SteeringDelegate:Call() + r(0, pitchOffset, 0))))).
    // if rollFlag
    // {
    //     set s_Val to g_SteeringDelegate:Call():Vector.
    // }
    // else if doneFlag
    // {
    //     set s_Val to g_SteeringDelegate:Call():Vector. // set s_Val to Ship:Prograde.
    // }
    // else
    // {
    //     local progradePitch is pitch_for(Ship, Ship:Velocity:Orbit).
    //     // set pitchOffset to Min(maxPitchOffset, Max(-maxPitchOffset, progradePitch - curPitchOffset)).
    //     set s_val to g_SteeringDelegate:Call() + r(0, pitchOffset, 0).
    // }
    
    DispLaunchTelemetry().
    wait 0.01.
}
OutInfo().
wait 0.05.
OutMsg("Final Stage").
set g_ActiveEngines to GetActiveEngines().

local MECOFlag to False.
local mecoTS is 0.
until MECOFlag or doneFlag
{
    set g_ActiveEngines_Data to GetEnginesPerformanceData(GetActiveEngines()).
    set mecoTS to Time:Seconds + g_ActiveEngines_Data:BurnTimeRemaining.

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
    else if g_TermChar = Char(115)
    {
        set pitchOffset to Min(32.5, pitchOffset + 1.25).
    }
    else if g_TermChar = Char(119)
    {
        set pitchOffset to Max(-22.5, pitchOffset - 1.25).
    }
    else if g_TermChar = Char(83)
    {
        set pitchOffset to Min(32.5, pitchOffset + 5).
    }
    else if g_TermChar = Char(87)
    {
        set pitchOffset to Max(-22.5, pitchOffset - 5).
    }
    else if g_TermChar = Char(79)
    {
        set pitchOffset to 0.
    }
    set g_TermChar to "".

    // set s_Val to choose g_SteeringDelegate:Call():Vector if rollFlag else g_SteeringDelegate:Call() + r(0, pitchOffset, 0).
    local progradePitch is pitch_for(Ship, Ship:Velocity:Orbit).
    if rollFlag
    {
        set s_Val to g_SteeringDelegate:Call():Vector.
    }
    else if doneFlag
    {
        set s_Val to Ship:Prograde.
    }
    else
    {
        set pitchOffset to progradePitch - curPitchOffset.
        set s_val to g_SteeringDelegate:Call() + r(0, pitchOffset, 0).
    }
    
    // set s_Val to choose g_SteeringDelegate:Call():Vector if rollFlag else choose Ship:Prograde if doneFlag else Min((progradePitch + curPitchOffset), Max((progradePitch - curPitchOffset), g_SteeringDelegate:Call() + r(0, pitchOffset, 0))).

    set g_ActiveEngines_Data to GetEnginesPerformanceData(GetActiveEngines()).
    if g_ActiveEngines_Data:HasKey("Thrust") 
    {
        if g_ActiveEngines_Data:Thrust = 0 and g_ActiveEngines:Length > 0
        {
            if g_Debug { OutDebug("g_ActiveEngines_Data:Thrust ({0}) < 0.001":Format(g_ActiveEngines_Data:Thrust), 5).}
            set MECOFlag to true.
        }
    }

    if tgtCheckDel:Call()// Ship:Periapsis >= (tgtPe * 0.995)
    {
        if g_Debug 
        { 
            if transferBurn
            {
                OutDebug("ShipApoapsis >= {0} ":Format(tgtAp), 5).
            }
            else
            {
                OutDebug("ShipPeriapsis >= {0} ":Format(tgtPe), 5).
            }
        }
        set MECOFlag to True.
    }
    // else if Time:Seconds >= mecoTS
    // {
    //     if g_Debug { OutDebug("Time:Seconds({0}) >= mecoTS({1})":Format(Time:Seconds, mecoTS), 5). }
    //     // set MECOFlag to True.
    // }
    else 
    {
        OutInfo("TIME TO MECO: {0} ":Format(Round(mecoTS - Time:Seconds))).
    }
    
    DispLaunchTelemetry().
    wait 0.01.
}
set t_Val to 0.
OutInfo().
wait 0.25.

if Ship:AvailableThrust > 0.01
{
    OutMsg("Waiting for engine burnout").
    until g_ActiveEngines_Data:Thrust <= 0.01
    {
        set s_Val to g_SteeringDelegate:Call() + r(0, pitchOffset, 0).
        set g_ActiveEngines_Data to GetEnginesPerformanceData(GetActiveEngines()).
        DispLaunchTelemetry().
        wait 0.01.
    }
}
unlock Throttle.
unlock Steering.

OutInfo().
OutMsg("circAtApo complete").