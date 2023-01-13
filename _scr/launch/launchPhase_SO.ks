@lazyGlobal off.
clearScreen.

parameter params to list().

runOncePath("0:/lib/loadDep").
runOncePath("0:/lib/launch").

DispMain(ScriptPath()).

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

local gravTurnAlt to body:Atm:Height * 0.90.

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
            local tgtParamVal to tgtLex[tgtKeyList[i]]:TOLOWER().
            if tgtParamVal:MATCHESPATTERN("^[0-9]+(?:km)*$")
            {
                if tgtParamVal:ENDSWITH("km") 
                {
                    set tgtParamVal to tgtParamVal:REPLACE("km", ""):TONUMBER() * 1000.
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

local gravAltAvg  to ((gravTurnAlt * 3) + tgt_ap) / 4.

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

set g_boosterSepArmed to ArmAutoBoosterSeparation().
ArmAutoStaging().
ArmHotStaging().

until ship:Altitude > g_la_turnAltStart
{
    if g_BoosterSepArmed { set g_BoosterObj to GetBoosters(). }
    set g_ActiveEngines to GetActiveEngines().
    set g_ActiveEnginesLex to ActiveEngines().
    DispLaunchTelemetry(list(tgt_ap)).
    wait 0.01.
}

until stage:Number <= g_stopStage
{
    if g_BoosterSepArmed { set g_BoosterObj to GetBoosters(). }
    set tgt_pit to GetAscentAngle(gravAltAvg, tgt_ap).
    set s_val to heading(tgt_hdg, tgt_pit, tgt_rll).
    DispLaunchTelemetry(list(tgt_ap)).
    wait 0.01.
}

until ship:AvailableThrust < 0.01 // or ship:Apoapsis >= tgt_ap
{
    if g_BoosterSepArmed { set g_BoosterObj to GetBoosters(). }
    set tgt_pit to GetAscentAngle(gravAltAvg, tgt_ap).
    set s_val to heading(tgt_hdg, tgt_pit, tgt_rll).
    DispLaunchTelemetry(list(tgt_ap)).
    wait 0.01.
}
set t_Val to 0.
OutMsg("Engine Cutoff").
wait 1.
// OutInfo().

OutMsg("Waiting until apoapsis").
local ts to Time:Seconds + eta:Apoapsis.
until Time:Seconds >= ts
{
    set ts to Time:Seconds + eta:Apoapsis.
    set s_val to lookDirUp(ship:Prograde:Vector, -body:Position).
    // if ship:Altitude > lastAlt set maxAlt to ship:Altitude.
    DispLaunchTelemetry(list(tgt_ap)).
    OutInfo("Apoapsis in: {0}s":Format(Round(ts - Time:Seconds, 2))).
    wait 0.01.
}
OutMsg("Apoapsis reached").
unlock Steering.
unlock Throttle.
OutMsg("Script complete!").
