@lazyGlobal off.
clearScreen.

parameter params is list().

runOncePath("0:/lib/loadDep").
runOncePath("0:/lib/launch").

DispMain(scriptPath()).

local tgt_hdg   to 90. // 90 degrees (due east) is most efficient trajectory
local tgt_hdg_key to "tgt_hdg".

local tgt_pit   to 90. // Needs to be 90 degrees as default to make pointy end stay pointed up
local tgt_pit_key to "tgt_pit".

local tgt_rll   to 0.
local tgt_rll_key to "tgt_rll".

if params:Length > 0
{
    set tgt_hdg to params[0].
    if params:Length > 1 set tgt_pit to params[1].
    if params:Length > 2 set tgt_rll to params[2].
}

local doneFlag to false.

local tgtLex to lexicon(
    tgt_hdg_key, tgt_hdg,
    tgt_pit_key, tgt_pit,
    tgt_rll_key, tgt_rll
).

local tgtKeyList to list(tgt_hdg_key, tgt_pit_key, tgt_rll_key).

local paramUpdatesMade to false.
from { local i to 0. } until i = tgtKeyList:Length step { set i to i + 1. } do 
{
    if tgtLex:HASKEY(tgtKeyList[i])
    {
        if tgtLex[tgtKeyList[i]]:IsType("String")
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

if paramUpdatesMade 
{
    set tgt_hdg to tgtLex[tgt_hdg_key].
    set tgt_pit to tgtLex[tgt_pit_key].
    set tgt_rll_key to tgtLex[tgt_rll_key].
}
if tgt_hdg:IsType("String") set tgt_hdg to tgt_hdg:ToNumber().
if tgt_pit:IsType("String") set tgt_pit to tgt_pit:ToNumber().
if tgt_rll:IsType("String") set tgt_rll to tgt_rll:ToNumber().

local f_SpinManualEngaged to false.

OutMsg("Press Enter to begin launch countdown").
until false
{
    if Terminal:Input:HasChar
    {
        set g_TermChar to Terminal:Input:Getchar.
    }
    if g_TermChar = Terminal:Input:Enter break.
}
lock throttle to t_val.
set s_val to ship:Facing.
lock steering to s_val.

OutMsg("Commencing launch countdown").
LaunchCountdown().
set t_val to 1.
OutMsg("Liftoff!").
wait until ship:verticalSpeed > 0.

OutInfo("Arming triggers").
ArmAutoStaging().
if Ship:PartsTaggedPattern("booster"):Length > 0            { set g_boosterSepArmed to ArmAutoBoosterSeparation().}
if Ship:PartsTaggedPattern("fairing.launch"):Length > 0     { ArmFairingJettison("launch").}
if Ship:PartsTaggedPattern("(HotStg|HotStage)"):Length > 0  { ArmHotStaging(). }
if Ship:PartsTaggedPattern("Spin"):Length > 0               { ArmSpinStabilization(). }
if Ship:PartsTaggedPattern("OnEvent\(ASC"):Length > 0       { InitOnEventTrigger(Ship:PartsTaggedPattern("OnEvent\(ASC")). }

until ship:Altitude > g_la_turnAltStart
{
    if g_BoosterSepArmed { set g_BoosterObj to GetBoosters(). }
    set g_ActiveEngines to GetActiveEngines().
    set g_ActiveEnginesLex to ActiveEngines().
    set g_ConsumedResources to GetResourcesFromEngines(g_ActiveEngines).
    DispLaunchTelemetry().
    wait 0.01.

    GetTermChar().
    set f_SpinManualEngaged to ManualSpinStabilizationCheck().
}

OutMsg("P16: Launch Angle ({0})":Format(tgt_pit)).

until stage:Number = g_stopStage
{
    if g_BoosterSepArmed { set g_BoosterObj to GetBoosters(). }
    set g_ActiveEngines to GetActiveEngines().
    set g_ActiveEnginesLex to ActiveEngines().
    set g_ConsumedResources to GetResourcesFromEngines(g_ActiveEngines).
    
    GetTermChar().
    set f_SpinManualEngaged to ManualSpinStabilizationCheck().
    set s_val to choose heading(tgt_hdg, tgt_pit):Vector if f_SpinManualEngaged else heading(tgt_hdg, tgt_pit, tgt_rll).

    DispLaunchTelemetry().
    wait 0.01.
}

OutMsg("P18: Final Burn").
until ship:Availablethrust < 0.01
{
    if g_BoosterSepArmed { set g_BoosterObj to GetBoosters(). }
    set g_ActiveEngines to GetActiveEngines().
    set g_ActiveEnginesLex to ActiveEngines().
    set g_ConsumedResources to GetResourcesFromEngines(g_ActiveEngines).
    
    GetTermChar().
    set f_SpinManualEngaged to ManualSpinStabilizationCheck().
    set s_val to choose heading(tgt_hdg, tgt_pit):Vector if f_SpinManualEngaged else heading(tgt_hdg, tgt_pit, tgt_rll).

    DispLaunchTelemetry().
    wait 0.01.
}

OutMsg("P20: MECO").

OutInfo("AP ETA: {0}":Format(round(eta:Apoapsis))).
local ts to Time:Seconds + eta:Apoapsis.
set doneFlag to false.
until Time:Seconds >= ts or doneFlag
{
    GetTermChar().
    set f_SpinManualEngaged to ManualSpinStabilizationCheck().
    if g_TermChar = Terminal:Input:HomeCursor
    {
        unlock steering.
        OutInfo("** Steering Unlocked **", 2).
    }
    else if g_TermChar = Terminal:Input:DownCursorOne
    {
        set Ship:Control:Neutralize to True.
    }
    else if g_TermChar = Terminal:Input:EndCursor
    {
        lock steering to s_Val.
    }
    else if g_TermChar = Terminal:Input:Enter
    {
        set doneFlag to true.
    }
    set ts to Time:Seconds + eta:Apoapsis.
    set s_val to lookDirUp(ship:Prograde:Vector, -body:Position).
    // if ship:Altitude > lastAlt set maxAlt to ship:Altitude.
    DispLaunchTelemetry().
    OutInfo("Apoapsis in: {0}s":Format(Round(ts - Time:Seconds, 2))).
    wait 0.01.
}
OutMsg("Apoapsis reached").
unlock Steering.
unlock Throttle.
OutMsg("Script complete!").