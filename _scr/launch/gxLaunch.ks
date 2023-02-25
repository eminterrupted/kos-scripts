@LazyGlobal off.
ClearScreen.

parameter params is list().

// Dependencies
RunOncePath("0:/lib/loadDep").
RunOncePath("0:/lib/launch").

DispMain(ScriptPath():name).

// *~ Param Check
// #region
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
// #endregion

// Local variables
local program to 0.

// global variables - These should probably be in lib/globals.ks

// Launch loop
// Uses program codes to advance through routines
// At the end of each loop, the delegate list is run
// If any delegates have been registered, they will be run each loop iteration
until program = -1
{

    // TODO: PreLoop Delegate Check
    for _del in g_RegisteredLoopDelegates:BEGIN
    {
        _del:Call().
    }

    if program = 0
    {
        // TODO: Prelaunch
        // ExecPreLaunchRoutine().
        // NextProgram().
    }

    else if program = 10
    {
        // TODO: Launch
    }

    else if program = 20
    {
        // TODO: Vertical Ascent
    }

    else if program = 30
    {
        // TODO: Roll Program
    }

    else if program = 40
    {
        // TODO: Pitch Program
    }

    else if program = 50
    {
        // TODO: Burn to MECO
    }

    else if program = 60
    {
        // TODO: MECO
    }

    else if program = 70
    {
        // TODO: Coast to Apoapsis
    }

    else if program = 80
    {
        // TODO: Correction Burn
    }
}