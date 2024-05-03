@LazyGlobal off.
ClearScreen.

parameter _params is list().

// Dependencies
RunOncePath("0:/lib/depLoader").

// Declare Variables
local waitTime to 3600.

// Parse Params
if _params:length > 0 
{
  set waitTime to ParseStringScalar(_params[0], waitTime).
}

local ts_0 to Round(Time:Seconds + waitTime).

set g_line to 4.
local line to g_line.

until Time:Seconds >= ts_0
{
    set g_line to line.
    GetTermChar().
    local span to TimeSpan(ts_0 - Time:Seconds).
    OutMsg("[WaitFor]: {0} ":Format(span:Full), cr()).
    wait 0.01.
    if g_TermChar <> ""
    {
        if g_TermChar = Terminal:Input:Enter
        {
            OutMsg("Breaking", cr()).
            Break.
        }
        else if g_TermChar = "w"
        {
            OutMsg("Warping").
            WarpTo(ts_0 - 60).
        }
        else if g_TermChar = Terminal:Input:Backspace
        {
            OutMsg("Stopping Warp").
            set warp to 0.
        }
    }
}

OutMsg("All done!").
