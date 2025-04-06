@LazyGlobal off.
ClearScreen.

parameter _warpStr is "".

// Dependencies
RunOncePath("0:/lib/depLoader").

// Declare Variables
local warpTable to lexicon(
    "y", 31536000
    ,"d", 86400
    ,"h", 3600
    ,"m", 60
    ,"s", 1
).

// Parse Params
if _warpStr:Length = 0
{
    OutMsg("No Warp String provided").
    wait 1.
}
else
{
    local workingString to _warpStr:Replace(" ",""):Replace(":","").

    local warpTime to 0.

    for denom in warpTable:Keys
    {
        local strSpl to workingString:Split(denom).
        if strSpl:Length > 1
        {
            set warpTime to warpTime + (strSpl[0]:ToNumber(0) * warpTable[denom]).
            set workingString to strSpl[1].
        }
    }

    local warpTS to Time:Seconds + warpTime.

    OutMsg("Warp to T+{0}? ":Format(TimeSpan(warpTime):Full)).
    OutInfo("*** Press ENTER to warp ***").

    local warpFlag to False.
    until Time:Seconds > WarpTS
    {
        GetTermChar().

        if g_TermChar <> ""
        {
            if g_TermChar = Terminal:Input:Enter
            {
                set warpFlag to True.
                OutInfo().
            }
            else if g_TermChar = Terminal:Input:Backspace
            {
                OutMsg("Cancelling Warp").
                OutInfo().

                set warp to 0.
            }
            set g_TermChar to "".
        }

        if Warp = 0
        {
            if warpFlag
            {
                OutInfo().
                WarpTo(WarpTS).
                set warpFlag to False.
            }
            else
            {
                OutMsg("Warp T+{0}? ":Format(TimeSpan(warpTime):Full)).
                OutInfo("*** Press ENTER to warp ***").
            }
        }
        else
        {
            OutMsg("Warping to T-{0} ":Format(TimeSpan(WarpTS - Time:Seconds):Full)).
            OutInfo().
        }
    }

    OutMsg("Warp Complete").
    OutInfo().
}