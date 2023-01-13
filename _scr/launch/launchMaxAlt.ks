@lazyGlobal off.
clearScreen.

parameter params is list().

runOncePath("0:/lib/loadDep").
runOncePath("0:/lib/launch").

DispMain(scriptPath()).

local tgt_ap    to Body:Soiradius.
local tgt_ap_key to "tgt_ap".

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
            if tgtParamVal:MATCHESPATTERN("^[0-9\.]+(?:Km)*$")
            {
                if tgtParamVal:ENDSWITH("km") 
                {
                    set tgtParamVal to tgtParamVal:REPLACE("km", "").
                }

                set tgtLex[tgtKeyList[i]] to tgtParamVal:TONUMBER(0).
                set paramUpdatesMade to true.    
            }
        }
    }
}

if paramUpdatesMade 
{
    set tgt_ap to choose tgtLex[tgt_ap_key] if tgtLex[tgt_ap_key] > 0 else body:Soiradius.
    set tgt_hdg to tgtLex[tgt_hdg_key].
    set tgt_pit to tgtLex[tgt_pit_key].
    set tgt_rll to tgtLex[tgt_rll_key].
}

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

set g_boosterSepArmed to ArmAutoBoosterSeparation().
ArmAutoStaging().
ArmHotStaging().

until ship:Altitude > g_la_turnAltStart
{
    if g_BoosterSepArmed { set g_BoosterObj to GetBoosters(). }
    DispLaunchTelemetry(list(tgt_ap)).
    wait 0.01.
}

OutMsg("P16: Launch Angle ({0})":Format(tgt_pit)).
set s_val to heading(tgt_hdg, tgt_pit, tgt_rll).

until stage:Number = g_stopStage
{
    if g_BoosterSepArmed { set g_BoosterObj to GetBoosters(). }
    DispLaunchTelemetry(list(tgt_ap)).
    wait 0.01.
}

OutMsg("P18: Final Burn").
until ship:Availablethrust < 0.01
{
    if g_BoosterSepArmed { set g_BoosterObj to GetBoosters(). }
    set s_val to heading(tgt_hdg, tgt_pit, tgt_rll).
    DispLaunchTelemetry(list(tgt_ap)).
    wait 0.01.
}

OutMsg("P20: MECO").

OutInfo("     AP ETA: {0}":Format(round(eta:Apoapsis))).
local ts_AP to ETA:Apoapsis + Time:Seconds.

until Time:Seconds >= ts_AP
{
    set s_val to heading(tgt_hdg, pitch_for(ship, ship:Prograde), tgt_rll).
    DispLaunchTelemetry(list(tgt_ap)).
    wait 0.01.
}
local maxAlt to Round(Ship:Altitude, 1).

OutMsg("P21: APOAPSIS").
OutInfo("MAX ALT REACHED: {0}m":Format(maxAlt)).
wait 5.

OutMsg("P23: UNCONTROLLED DESCENT").
unlock steering.
unlock throttle.
until doneFlag
{
    
    DispLaunchTelemetry(list(tgt_ap)).
    wait 0.01.
    if alt:Radar <= 5 
    {
        set doneFlag to true.
    }
    else
    {
        set g_TermChar to GetTermChar().
        if g_TermChar = Terminal:Input:Enter 
        {
            set doneFlag to true.
        }
    }
}

OutMsg("Script complete").
wait 1.
