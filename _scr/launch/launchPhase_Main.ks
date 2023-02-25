@lazyGlobal off.
clearScreen.

parameter params to list().

runOncePath("0:/lib/loadDep").
runOncePath("0:/lib/launch").

DispMain(ScriptPath()).


// Parameter validation
local tgt_ap    to body:Atm:Height * 1.5.
local tgt_ap_key to "tgt_ap".

local tgt_hdg   to 90. // 90 degrees (due east) is most efficient trajectory
local tgt_hdg_key to "tgt_hdg".

local tgt_pit   to 90. // Needs to be 90 degrees as default to make pointy end stay pointed up
local tgt_pit_key to "tgt_pit".

local tgt_rll   to 0.
local tgt_rll_key to "tgt_rll".

if params:Length > 0
{
    set tgt_ap to params[0].
    if params:Length > 1 set tgt_hdg to params[1].
    if params:Length > 2 set tgt_pit to params[2].
    if params:Length > 3 set tgt_rll to params[3].
}


local tgtLex to lexicon(
    tgt_ap_key, tgt_ap,
    tgt_hdg_key, tgt_hdg,
    tgt_pit_key, tgt_pit,
    tgt_rll_key, tgt_rll
).

local tgtKeyList to list(tgt_ap_key, tgt_hdg_key, tgt_pit_key, tgt_rll_key).

local paramUpdatesMade to false.
from { local i to 0. } until i = tgtKeyList:Length step { set i to i + 1. } do 
{
    if tgtLex:HASKEY(tgtKeyList[i])
    {
        if tgtLex[tgtKeyList[i]]:IsType("String")
        {
            if tgtLex[tgtKeyList[i]]:MATCHESPATTERN("[0-9]+(km|k|mm)*")
            {
                local tgtParamVal to tgtLex[tgtKeyList[i]]:TOLOWER().
                if tgtParamVal:ENDSWITH("km") or tgtParamVal:ENDSWITH("k") 
                {
                    set tgtParamVal to (tgtParamVal:REPLACE("km", ""):REPLACE("k",""):TONUMBER()) * 1000.
                }
                else if tgtParamVal:ENDSWITH("mm") 
                {
                    set tgtParamVal to tgtParamVal:TONUMBER() * 1000000.
                }
                else 
                {
                    set tgtParamVal to tgtParamVal:TONUMBER().
                }

                set tgtLex[tgtKeyList[i]] to tgtParamVal.
                set paramUpdatesMade to true.    
            }
        }
    }
}

if paramUpdatesMade 
{
    set tgt_ap to tgtLex[tgt_ap_key].
    set tgt_hdg to tgtLex[tgt_hdg_key].
    set tgt_pit to tgtLex[tgt_pit_key].
    set tgt_rll_key to tgtLex[tgt_rll_key].
}
if tgt_ap:IsType("String") set tgt_ap to tgt_ap:ToNumber().
if tgt_hdg:IsType("String") set tgt_hdg to tgt_hdg:ToNumber().
if tgt_pit:IsType("String") set tgt_pit to tgt_pit:ToNumber().
if tgt_rll:IsType("String") set tgt_rll to tgt_rll:ToNumber().

// Local vars
local gravTurnAlt to body:Atm:Height * 0.875.
local gravAltAvg            to ((gravTurnAlt * 3) + tgt_ap) / 4.

local f_SpinManualEngaged   to false.
local f_HoldFacing          to false.
local f_HoldPro             to false.
local rcsToggleFlag         to false.



// Start
OutMsg("Press Enter to begin launch countdown").
OutInfo("ALT: {0}  |  HDG: {1}":Format(tgt_ap, tgt_hdg), 1).
OutInfo("PIT: {0}  |  RLL: {1}":Format(tgt_pit, tgt_rll), 2).
Print "PARSED TAG DETAILS" at (0, 11).
Print "PCN: " + g_Tag:PCN at (2, 12).
Print "SID: " + g_Tag:SID at (2, 13).
Print "PRM: " + g_Tag:PRM:Join(";") at (2, 14).
Print "ASL: " + g_Tag:ASL at (2, 15).
until false
{
    if Terminal:Input:HasChar
    {
        set g_TermChar to Terminal:Input:Getchar.
    }
    if g_TermChar = Terminal:Input:Enter break.
}
DispClr(7).
set s_val to Ship:Facing.
lock throttle to t_val.
lock steering to s_val.
OutMsg("Commencing launch countdown").
LaunchCountdown().
set t_Val to 1.
DispClr(7).
OutMsg("Liftoff!").

ArmAutoStaging().
if Ship:PartsTaggedPattern("booster"):Length > 0                        { set g_boosterSepArmed to ArmAutoBoosterSeparation().}
if Ship:PartsTaggedPattern("fairing\.(Ascent|ASC|Launch)"):Length > 0   { ArmFairingJettison("ascent").}
if Ship:PartsTaggedPattern("(HotStg|HotStage)"):Length > 0              { ArmHotStaging(). }
if Ship:PartsTaggedPattern("Spin(Stage|Stg|Stab|Stabilize)"):Length > 0 { ArmSpinStabilization(). }
if Ship:PartsTaggedPattern("OnEvent\|(Ascent|ASC|Launch)"):Length > 0   { InitOnEventTrigger(Ship:PartsTaggedPattern("OnEvent|(Ascent|ASC|Launch)")). }

until ship:Altitude > g_la_turnAltStart
{
    if g_BoosterSepArmed { set g_BoosterObj to GetBoosters(). }
    set g_ActiveEngines to GetActiveEngines().
    set g_ActiveEnginesLex to ActiveEngines().
    set g_ConsumedResources to GetResourcesFromEngines(g_ActiveEngines).
    DispLaunchTelemetry(tgt_ap).
    wait 0.01.

    GetTermChar().
    if g_TermChar = Terminal:Input:Backspace
    {
        OutDebug("MODE[A]: Resetting inputs", 1).
        set f_HoldFacing        to false.
        set f_HoldPro           to false.
        set f_SpinManualEngaged to false.
    }
    else if g_TermChar = Terminal:Input:EndCursor// f_HoldFacing
    {
        OutDebug("MODE[A]: Hold Facing", 1).
        set s_Val               to Ship:Facing.
        set f_HoldFacing        to choose false if f_HoldFacing else true.
        set f_HoldPro           to false.
        set f_SpinManualEngaged to false.
    }
    else if g_TermChar = Terminal:Input:HomeCursor
    {
        OutDebug("MODE[A]: Hold Prograde", 1).
        set s_Val           to Ship:Prograde.
        set f_HoldFacing    to false.
        set f_HoldPro       to choose false if f_HoldPro else true.
        set f_SpinManualEngaged to false.
    }
    else
    {
        set f_SpinManualEngaged to ManualSpinStabilizationCheck().
        if f_SpinManualEngaged
        {
            OutDebug("MODE[A]: Manual Spin", 1).
            set s_Val to Ship:Facing:Vector. // Heading(tgt_hdg, tgt_pit):Vector.
            set f_HoldFacing        to false.
            set f_HoldPro           to false.
            //set f_SpinManualEngaged to choose false if f_SpinManualEngaged else true.
        }
        else 
        {
            OutDebug("MODE[A]: Normal / Guided", 1).
            set s_Val to Heading(tgt_hdg, tgt_pit, tgt_rll).
        }
    }
}

until stage:Number <= g_stopStage
{
    if g_BoosterSepArmed { set g_BoosterObj to GetBoosters(). }
    set g_ActiveEngines to GetActiveEngines().
    set g_ActiveEnginesLex to ActiveEngines().
    set g_ConsumedResources to GetResourcesFromEngines(g_ActiveEngines).
    
    GetTermChar().
    if g_TermChar = Terminal:Input:Backspace
    {
        OutDebug("MODE[B]: Resetting inputs", 1).
        set f_HoldFacing        to false.
        set f_HoldPro           to false.
        set f_SpinManualEngaged to false.
    }
    else if g_TermChar = Terminal:Input:EndCursor// f_HoldFacing
    {
        OutDebug("MODE[B]: Hold Facing", 1).
        set s_Val               to Ship:Facing.
        set f_HoldFacing        to choose false if f_HoldFacing else true.
        set f_HoldPro           to false.
        set f_SpinManualEngaged to false.
    }
    else if g_TermChar = Terminal:Input:HomeCursor
    {
        OutDebug("MODE[B]: Hold Prograde", 1).
        set s_Val           to Ship:Prograde.
        set f_HoldFacing    to false.
        set f_HoldPro       to choose false if f_HoldPro else true.
        set f_SpinManualEngaged to false.
    }
    else
    {
        set f_SpinManualEngaged to ManualSpinStabilizationCheck().
        if f_SpinManualEngaged
        {
            OutDebug("MODE[B]: Manual Spin", 1).
            set s_Val to Ship:Facing:Vector. // Heading(tgt_hdg, tgt_pit):Vector.
            set f_HoldFacing        to false.
            set f_HoldPro           to false.
            //set f_SpinManualEngaged to choose false if f_SpinManualEngaged else true.
        }
        else 
        {
            OutDebug("MODE[B]: Normal / Guided", 1).
            set tgt_pit to GetAscentAngle(gravAltAvg, tgt_ap).
            set s_Val to Heading(tgt_hdg, tgt_pit, tgt_rll).
        }
    }

    // GetTermChar().
    // set f_SpinManualEngaged to ManualSpinStabilizationCheck().
    // if f_SpinManualEngaged
    // {
    //     set tgt_pit to pitch_for(Ship, Ship:Prograde).
    //     set s_Val to Heading(tgt_hdg, tgt_pit):Vector.
    // }
    // else if g_HotStageActive
    // {
    //     set tgt_pit to pitch_for(Ship, Ship:Prograde).
    //     set s_Val to Heading(tgt_hdg, tgt_pit, tgt_rll).
    // }
    // else
    // {
    //      set tgt_pit to GetAscentAngle(gravAltAvg, tgt_ap).
    //      set s_Val to Heading(tgt_hdg, tgt_pit, tgt_rll).
    // }
    
    if not rcsToggleFlag
    {
        if Ship:Altitude > 30000
        {
            RCS on.
            set rcsToggleFlag to true.
        }
    }

    DispLaunchTelemetry(tgt_ap).
    wait 0.01.
}

until ship:AvailableThrust < 0.01 // or ship:Apoapsis >= tgt_ap
{
    if g_BoosterSepArmed { set g_BoosterObj to GetBoosters(). }
    // set tgt_pit to GetAscentAngle(gravAltAvg, tgt_ap).
    // //set s_val to heading(tgt_hdg, tgt_pit, tgt_rll).
    // set s_Val to choose Heading(tgt_hdg, tgt_pit):Vector if f_SpinManualEngaged else Heading(tgt_hdg, tgt_pit, tgt_rll).

    GetTermChar().
    if g_TermChar = Terminal:Input:Backspace
    {
        OutDebug("MODE[C]: Resetting inputs", 1).
        set f_HoldFacing        to false.
        set f_HoldPro           to false.
        set f_SpinManualEngaged to false.
    }
    else if g_TermChar = Terminal:Input:EndCursor// f_HoldFacing
    {
        OutDebug("MODE[C]: Hold Facing", 1).
        set s_Val               to Ship:Facing.
        set f_HoldFacing        to choose false if f_HoldFacing else true.
        set f_HoldPro           to false.
        set f_SpinManualEngaged to false.
    }
    else if g_TermChar = Terminal:Input:HomeCursor
    {
        OutDebug("MODE[C]: Hold Prograde", 1).
        set s_Val           to Ship:Prograde.
        set f_HoldFacing    to false.
        set f_HoldPro       to choose false if f_HoldPro else true.
        set f_SpinManualEngaged to false.
    }
    else
    {
        set f_SpinManualEngaged to ManualSpinStabilizationCheck().
        if f_SpinManualEngaged
        {
            OutDebug("MODE[C]: Manual Spin", 1).
            set s_Val to Ship:Facing:Vector. // Heading(tgt_hdg, tgt_pit):Vector.
            set f_HoldFacing        to false.
            set f_HoldPro           to false.
            //set f_SpinManualEngaged to choose false if f_SpinManualEngaged else true.
        }
        else 
        {
            OutDebug("MODE[C]: Normal / Guided", 1).
            set tgt_pit to GetAscentAngle(gravAltAvg, tgt_ap).
            set s_Val to Heading(tgt_hdg, tgt_pit, tgt_rll).
        }
    }

    // GetTermChar().
    // set f_SpinManualEngaged to ManualSpinStabilizationCheck().
    // if f_SpinManualEngaged
    // {
    //     set tgt_pit to pitch_for(Ship).
    //     set s_Val to Heading(tgt_hdg, tgt_pit):Vector.
    // }
    // else
    // {
    //      set tgt_pit to GetAscentAngle(gravAltAvg, tgt_ap).
    //      set s_Val to Heading(tgt_hdg, tgt_pit, tgt_rll).
    // }
    DispLaunchTelemetry(tgt_ap).
    wait 0.01.
}
//set t_Val to 0.
OutMsg("Engine Cutoff").
wait 1.
// OutInfo().
if Ship:Apoapsis >= Body:ATM:Height
{
    OutMsg("Coasting to space").
    until ship:altitude > Body:ATM:Height
    {
        GetTermChar().
        if g_TermChar = Terminal:Input:UpCursorOne
        {
            unlock steering.
        }
        else if g_TermChar = Terminal:Input:DownCursorOne
        {
            lock steering to s_Val.
        }
        else if g_TermChar = Terminal:Input:EndCursor
        {
            break.
        }

        set s_Val to LookDirUp(Ship:Prograde:Vector, -Body:Position).
        DispLaunchTelemetry().
    }
}

OutMsg("Coasting to Apoapsis").
OutInfo("", 1).
until ETA:Apoapsis <= 0.250
{
    OutInfo("Time to AP: {0}":Format(Round(ETA:Apoapsis, 2))).
    GetTermChar().
    if g_TermChar = Terminal:Input:UpCursorOne
    {
        unlock steering.
    }
    else if g_TermChar = Terminal:Input:DownCursorOne
    {
        lock steering to s_Val.
    }
    else if g_TermChar = Terminal:Input:EndCursor
    {
        break.
    }

    set s_Val to LookDirUp(Ship:Prograde:Vector, -Body:Position).
    DispLaunchTelemetry().
}
OutInfo().
ClearScreen.
DispMain(ScriptPath()).
OutMsg("{0} complete!":Format(ScriptPath())).
OutInfo("Press 'End' to exit now").
local exitTS to Time:Seconds + 14.
until Time:Seconds >= exitTS 
{
    GetTermChar().
    if g_TermChar = Terminal:Input:EndCursor
    {
        OutInfo("",1).
        Break.
    }
    OutInfo("Exiting script in {0,5}s":Format(Round(exitTS - Time:Seconds, 2)), 1).
    wait 0.01.
}
OutInfo("Exiting script now!").
wait 1.