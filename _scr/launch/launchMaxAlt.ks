@lazyGlobal off.
clearScreen.

parameter params is list().

runOncePath("0:/lib/loadDep").
runOncePath("0:/lib/launch").

DispMain(scriptPath()).

local tgt_ap    to body:soiradius.
local tgt_ap_key to "tgt_ap".

local tgt_hdg   to 90. // 90 degrees (due east) is most efficient trajectory
local tgt_hdg_key to "tgt_hdg".

local tgt_pit   to 90. // Needs to be 90 degrees as default to make pointy end stay pointed up
local tgt_pit_key to "tgt_pit".

local tgt_rll   to 0.
local tgt_rll_key to "tgt_rll".

if params:length > 0
{
    set tgt_ap to params[0].
    if params:length > 1 set tgt_hdg to params[1].
    if params:length > 2 set tgt_pit to params[2].
    if params:length > 3 set tgt_rll to params[3].
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
from { local i to 0. } until i = tgtKeyList:length step { set i to i + 1. } do 
{
    if tgtLex:HASKEY(tgtKeyList[i])
    {
        if tgtLex[tgtKeyList[i]]:isType("String")
        {
            local tgtParamVal to tgtLex[tgtKeyList[i]]:TOLOWER().
            if tgtParamVal:MATCHESPATTERN("^[0-9]+(?:km)*$")
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
    set tgt_ap to choose tgtLex[tgt_ap_key] if tgtLex[tgt_ap_key] > 0 else body:soiradius.
    set tgt_hdg to tgtLex[tgt_hdg_key].
    set tgt_pit to tgtLex[tgt_pit_key].
    set tgt_rll to tgtLex[tgt_rll_key].
}

OutMsg("Press Enter to begin launch countdown").
until false
{
    if Terminal:Input:hasChar
    {
        set g_TermChar to Terminal:Input:getchar.
    }
    if g_TermChar = Terminal:Input:enter break.
}
lock throttle to t_val.
set s_val to ship:facing.
lock steering to s_val.

OutMsg("Commencing launch countdown").
LaunchCountdown().
set t_val to 1.
OutMsg("Liftoff!").

ArmAutoStaging().

until ship:altitude > g_la_turnAltStart
{
    DispLaunchTelemetry(list(tgt_ap)).
    wait 0.01.
}

OutMsg("P16: Launch Angle ({0})":format(tgt_pit)).
set s_val to heading(tgt_hdg, tgt_pit, tgt_rll).

until stage:number = g_stopStage
{
    DispLaunchTelemetry(list(tgt_ap)).
    wait 0.01.
}

OutMsg("P18: Final Burn").
until ship:availablethrust < 0.01
{
    set s_val to heading(tgt_hdg, tgt_pit, tgt_rll).
    DispLaunchTelemetry(list(tgt_ap)).
    wait 0.01.
}

OutMsg("P20: MECO").

OutInfo("     AP ETA: {0}":format(round(eta:apoapsis))).
until eta:apoapsis < 1
{
    set s_val to heading(tgt_hdg, pitch_for(ship, ship:prograde), tgt_rll).
    DispLaunchTelemetry(list(tgt_ap)).
    wait 0.01.
}

OutMsg("P21: DESCENT").
until doneFlag
{
    set s_val to lookDirUp(ship:retrograde:vector, heading(tgt_hdg, 0):vector).
    DispLaunchTelemetry(list(tgt_ap)).
    wait 0.01.
    if alt:radar <= 1 set doneFlag to true.
}

OutMsg("Script complete").
wait 1.