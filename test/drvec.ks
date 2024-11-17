@LazyGlobal off.
ClearScreen.

parameter _params is list().

// Dependencies
RunOncePath("0:/lib/depLoader").

// Declare Variables
global vecIteration to 0.

local baseVec to Ship:Position.
local tgtVec  to Body:Position.

local clearOnExit to True.
local enableVecDraws to True.

local vecColor to { return RGBA(Max(0.025, RANDOM()), Max(0.025, RANDOM()), Max(0.025, RANDOM()), 1). }.
local vecIterationString to vecIteration:ToString.
local vecName to "CREI SVV-{0}":Format(9000 + vecIterationString).
local vecScale to 1.0.
local vecWidth to vecScale * 0.25.

if HasTarget 
{ 
    set tgtVec to Target:Position.
    set vecName to "Target Thingy".
}

// Parse Params
if _params:length > 0 
{
    set vecName to _params[0].
    if _params:length > 1 { set tgtVec to choose _params[1]@ if _params[1]:IsType("Delegate") else type_to_vector(ship, _params[1]).  }
    if _params:length > 2 { set baseVec to choose _params[2]@ if _params[2]:IsType("Delegate") else type_to_vector(ship, _params[2]). }
    if _params:length > 3 { set vecColor to choose _params[3]@ if _params[3]:IsType("Delegate") else _params[3]. }
    if _params:length > 4 set vecScale to ParseStringScalar(_params[4]).
    if _params:length > 5 set vecWidth to ParseStringScalar(_params[5]).
    if _params:length > 6 set clearOnExit to _params[6] = True.
    if _params:length > 7 set enableVecDraws to _params[7] = True.
}

local vecIDoneDrawedIt to VecDraw(
    baseVec,
    tgtVec,
    vecColor,
    vecName,
    vecScale,
    enableVecDraws,
    vecWidth,
    True,
    True
).

Terminal:Input:Clear.
set g_TermChar to "".

OutMsg("The vector is doine getting good and drawn to the screen").

local scaleAdjustFactor is 0.925.
local scaleUpMulti is Max(1, Round(1 / scaleAdjustFactor, 3)).
local scaleDownMulti is Min(1, Round(scaleAdjustFactor, 3)).

if scaleAdjustFactor < 1
{
    set scaleUpMulti to Max(1, 1 / scaleAdjustFactor).
    set scaleDownMulti to scaleAdjustFactor.
}

local quitPending to False.
local doneFlag to false.
until doneFlag
{   
    GetTermChar().
    if g_TermChar:Length > 0
    {
        if g_TermChar = Terminal:Input:Backspace // Reset scale
        {
            set vecIDoneDrawedIt:Scale to Round(vecScale).
        }
        else if g_TermChar = Char(43) // Large positive increment; '+', or shift + =
        {
            set vecIDoneDrawedIt:Scale to Round(vecIDoneDrawedIt:Scale * (scaleUpMulti * 4), 2).
        }
        else if g_TermChar = Terminal:Input:UpCursorOne // Medium positive increment; up arrow
        {
            set vecIDoneDrawedIt:Scale to Round(vecIDoneDrawedIt:Scale * (scaleUpMulti * 2), 2).
        }
        else if g_TermChar = Char(61) // Small positive increment; '=', (+ with no shift)
        {
            set vecIDoneDrawedIt:Scale to Round(vecIDoneDrawedIt:Scale * scaleUpMulti, 2).
        }
        else if g_TermChar = Char(95) // Small negative increment; '-', (- with no shift)
        {
            set vecIDoneDrawedIt:Scale to Round(vecIDoneDrawedIt:Scale * scaleDownMulti, 2).
        }
        else if g_TermChar = Terminal:Input:DownCursorOne // Medium negative increment; down arrow
        {
            set vecIDoneDrawedIt:Scale to Round(vecIDoneDrawedIt:Scale * (scaleDownMulti * 2), 2).
        }
        else if g_TermChar = Char(95) // '_', or shift + _
        {
            set vecIDoneDrawedIt:Scale to Round(vecIDoneDrawedIt:Scale * (scaleDownMulti * 4), 2).
        }
        else if g_TermChar = Terminal:Input:LeftCursorOne
        {
            set vecIDoneDrawedIt:Width to Round(vecIDoneDrawedIt:Width * scaleDownMulti, 2).
        }
        else if g_TermChar = Terminal:Input:RightCursorOne
        {
            set vecIDoneDrawedIt:Width to Round(vecIDoneDrawedIt:Width * scaleUpMulti, 2).
        }
        else if g_TermChar = Terminal:Input:EndCursor
        {
            if enableVecDraws
            {
                set enableVecDraws to False.
                OutInfo("Quit? Press End again to confirm").
                set quitPending to True.
            }
            else if quitPending
            {
                set doneFlag to True.
            }
        }
        else if g_TermChar = Terminal:Input:HomeCursor
        {
            set enableVecDraws to True.
        }
        else
        {
            set quitPending to False.
        }
        set vecIDoneDrawedIt:Show to enableVecDraws.

        set g_TermChar to "".
        
    }
    wait 0.01.
}

if clearOnExit 
{
    ClearVecDraws().
    wait 0.25.
}
ClearScreen.