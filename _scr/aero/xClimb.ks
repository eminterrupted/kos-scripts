@LazyGlobal off.
ClearScreen.

parameter _tgtAlt is 50000,
          _tgtHdg is 150,
          _climbDur is 120.

RunOncePath("0:/lib/loadDep").
RunOncePath("0:/lib/aero").

DispMain(ScriptPath()).

local pMax to 75.
local r_Val to 0.
local tUpdate to 0.05.
local curDir to FlightDirObject(). 
local initPit to 10.
local tgtPitch to initPit.
local pStep to (pMax - curDir:FCG[1]) / (_climbDur / tUpdate).
local pStepDefault to pStep.
local pStepChangeDelta to pStepDefault / 2.

local dispData to lexicon(
    "CLIMB DATA", "-"
    ,"TIME REMAINING", _climbDur
    ,"ALTITUDE", Round(Ship:Altitude)
    ,"APOAPSIS", Round(Ship:Apoapsis)
    ,"APO DIFF-TO-TGT", Round(_tgtAlt - Ship:Apoapsis)
    ,"CR_0",""
    ,"PITCH TGT", pMax
    ,"PITCH CUR", round(curDir:FCG[1], 3)
    ,"PITCH DEV", Round(Abs(pMax - curDir:FCG[1]), 3)
    ,"AOA", Round(curDir:FCG[1] - curDir:FLT[1], 3)
    ,"DT-PITCH CHANGE", pStep
    ,"CR_1",""
    ,"HDG TGT", _tgtHdg
    ,"HDG CUR", Round(curDir:FCG[0], 2)
    ,"HDG TGT DEV", Round(_tgtHdg - curDir:FCG[0], 2)
    ,"HDG FLT DEV", Round(_tgtHdg - curDir:FLT[0], 2)
    ,"CR_2",""
    ,"ROLL TGT", Round(r_Val, 2)
    ,"ROLL CUR", Round(curDir:FCG[2], 2)
).

set s_Val to heading(_tgtHdg, initPit, r_Val).
lock steering to s_Val.
OutMsg("Press enter to begin climb").
OutInfo("UpArrow/DownArrow: Increase / Decrease pitch deltas per update").

local _goFlag to false.
until _goFlag
{
    GetTermChar().
    if g_TermChar = Terminal:Input:Enter { set _goFlag to True.}

    set curDir to FlightDirObject().
    UpdateCommonDispData().
    
    DispTelemetry(dispData).
}
local ts to time:seconds + _climbDur.
    
Sas off.

set t_Val to 1.
lock throttle to t_Val.
local eng to Ship:Engines[0].
until eng:thrust > 0
{
    wait until stage:ready.
    stage.
    wait 2.5.
}

set s_Val to Heading(curDir:FCG[0], initPit, curDir:FCG[2]).
lock steering to s_Val.
local loopBreak to False.

when ship:altitude > 25000 then
{
    RCS on.
}

local ts_1 to time:seconds + 5.

until time:seconds > ts_1
{
    OutMsg("Climb starting in {0}":Format(Round(ts_1 - Time:Seconds, 1))).
}
OutMsg("Climb Initiated").

from { local i to 0.} until i >= _climbDur or loopBreak step { set i to i + tUpdate.} do
{
    GetTermChar().

    local tick to Time:Seconds.

    if g_TermChar = Terminal:Input:EndCursor
    { 
        set loopBreak to True.
    }
    else
    {
        if g_TermChar = Terminal:Input:UpCursorOne
        {
            set pStep to pStep + pStepChangeDelta.
            set dispData["DT-PITCH CHANGE"] to pStep.
        }
        else if g_TermChar = Terminal:Input:DownCursorOne
        {
            set pStep to pStep - pStepChangeDelta.
            set dispData["DT-PITCH CHANGE"] to pStep.
        }
        else if g_TermChar = Terminal:Input:HomeCursor
        {
            set pStep to pStepDefault.
            set dispData["DT-PITCH CHANGE"] to pStep.
        }

        set curDir to FlightDirObject().
        //set r_Val to RollAngleForHeading(_tgtHdg).
        set tgtPitch to Max(pMax, tgtPitch + pStep).
        set s_Val to Heading(_tgtHdg, tgtPitch, r_Val).

        set dispData["TIME REMAINING"] to Round(ts - Time:Seconds, 2).
        UpdateCommonDispData().
        DispTelemetry(dispData).

        wait tUpdate.
    }
}

DispClr().

if loopBreak
{
    set g_TermChar to "".
    Terminal:Input:Clear.
    OutMsg("Climb aborted! Press End again to unlock steering and end script").
    OutInfo("UpArrow / DownArrow: Increase / Decrease Pitch (1-deg increment)").
    
    dispData:Remove("TIME REMAINING").
    dispData:Remove("DT-PITCH CHANGE").

    local tHdg to curDir:FCG[0].
    local tPit to curDir:FCG[1].

    until g_TermChar = Terminal:Input:EndCursor
    {
        set curDir to compass_and_pitch_for(Ship, Ship:Facing).

        if g_TermChar = Terminal:Input:UpCursorOne
        {
            set tPit to tPit + 1.
        }
        else if g_TermChar = Terminal:Input:DownCursorOne
        {
            set tPit to tPit - 1.
        }
        else if g_TermChar = Terminal:Input:DeleteRight
        {
            set tPit to curDir:FLT[1].
        }
        else if g_TermChar = Terminal:Input:LeftCursorOne
        {
            set tHdg to curDir:FCG[0] + 1.
        }
        else if g_TermChar = Terminal:Input:RightCursorOne
        {
            set tHdg to curDir:FCG[0] - 1.
        }
        else if g_TermChar = Terminal:Input:HomeCursor
        {
            set tHdg to curDir:FLT[0].
        }
        else if g_TermChar = Terminal:Input:EndCursor
        {
            set tHdg to _tgtHdg.
        }

        //set r_Val to RollAngleForHeading(tHdg).
        set s_Val to Heading(tHdg, tPit, r_Val).
        UpdateCommonDispData().
        DispTelemetry(dispData).
    }
}
else
{
    OutMsg("Climb complete!").
}
unlock steering.


////

local function FlightDirObject
{
    local facingDir to compass_and_pitch_for(Ship, Ship:Facing).
    local facingRoll to roll_for(Ship, Ship:Facing).
    local flightDir to compass_and_pitch_for(Ship, Ship:SrfPrograde).
    local flightRoll to roll_for(Ship, Ship:SrfPrograde).

    return Lexicon("FCG", list(facingDir[0], facingDir[1], facingRoll), "FLT", list(flightDir[0], flightDir[1], flightRoll)).
}

local function RollAngleForHeading
{
    parameter _tgtHeading,
              _maxRoll to 45.

    local dirLeft to Mod(360 + curDir:FLT[0] - 180, 360).
    local dirRight to Mod(360 + curDir:FLT[0] + 180, 360).
    local hdgDelta to Mod(360 + _tgtHeading - curDir:FLT[0], 360).
    local signedHdg to choose Mod(_tgtHeading - curDir:FLT[0], 180) if _tgtHeading - curDir:FLT[0] >= 0 and _tgtHeading - curDir:FLT[0] < 180 else -Mod(curDir:FLT[0] - curDir:FLT[0], 180).
    
    if hdgDelta > 180
    {

    }
    local maxRollAtDiff to 15.
    return Max(_maxRoll, (hdgDelta / maxRollAtDiff) * _maxRoll).
}

local function UpdateCommonDispData
{
    set dispData["PITCH CUR"] to Round(curDir:FLT[1], 2).
    set dispData["PITCH TGT DEV"] to Round(Abs(pMax - curDir:FCG[1]), 2).
    set dispData["AOA"] to Round(curDir:FCG[1] - curDir:FLT[1], 2).

    set dispData["HDG CUR"] to Round(curDir:FCG[0], 2).
    set dispData["HDG FLT"] to Round(curDir:FLT[0], 2).
    set dispData["HDG TGT DEV"] to Round(_tgtHdg - curDir:FCG[0], 2).
    set dispData["HDG DIR DEV"] to Round(_tgtHdg - curDir:FLT[0], 2).
    set dispData["ROLL TGT"] to Round(r_Val, 2).
    set dispData["ROLL CUR"] to Round(curDir:FCG[2], 2).

    set dispData["ALTITUDE"] to Round(Ship:Altitude, 1).
    set dispData["APOAPSIS"] to Round(Ship:Apoapsis, 1).
    set dispData["APO DIFF-TO-TGT"] to Round(_tgtAlt - Ship:Apoapsis, 1).
    set dispData["TIME TO APO"] to Round(ETA:Apoapsis, 2).
}