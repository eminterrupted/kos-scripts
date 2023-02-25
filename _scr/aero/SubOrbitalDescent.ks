@LazyGlobal off.
ClearScreen.

parameter params is list().

// Dependencies
RunOncePath("0:/lib/loadDep").
RunOncePath("0:/lib/aero").

DispMain(ScriptPath():name).

// Declare Variables
local curAoA        to 0.
local doneFlag      to false.
local pitFacing     to 0.
local pitPro        to 0.
local t_PitchDefault to 20.

// Parse Params
if params:length > 0 
{
  set t_PitchDefault to params[0].
}

local t_Pitch       to t_PitchDefault.

set s_Val to Ship:Facing.
lock steering to s_Val.
OutMsg("Entering SrfPrograde tracking mode").

until doneFlag
{
    set pitFacing   to pitch_for(Ship, Ship:Facing).
    set pitPro      to pitch_for(Ship, Ship:SrfPrograde).
    set curAoA      to pitFacing - pitPro.
    
    GetTermChar().
    
    if g_TermChar = Terminal:Input:EndCursor
    {
        set t_Pitch to t_PitchDefault.
    }
    else if g_TermChar = Terminal:Input:HomeCursor
    {
        set t_Pitch to 0.
    }
    else if g_TermChar = "+"
    {
        set t_Pitch to t_Pitch + 1.
    }
    else if g_TermChar = "-"
    {
        set t_Pitch to t_Pitch - 1.
    }
    set s_val to LookDirUp(Ship:SrfPrograde, -Body:Position) + t_Pitch.
    
    OutInfo("TgtPitch: {0} | Pitch: {1} | AoA: {2} ":Format(t_Pitch, Round(pitFacing,2), Round(curAoA, 2))).
    
    wait 0.01.
}