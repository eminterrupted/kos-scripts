@LazyGlobal off.
ClearScreen.

parameter _params is list().

// Dependencies
RunOncePath("0:/lib/depLoader").

// Declare Variables
local bootLoader to "".
local blDir to "0:/boot".
local blLocal to "1:/boot/bl.ks".

local bootFiles to Open(Path(blDir)):List.

// Parse Params
if _params:Length > 0 
{
    if _params[0]:IsType("String")
    {
        local blNameString to "{0}/{1}":Format(blDir, _params[0]).
        print blNameString at (0, 15).
        Wait 5.
        set bootLoader to Open(Path(blNameString)).
    }
    else if _params[0]:IsType("VolumeFile")
    {
        set bootLoader to _params[0].
    }
}
else
{
    OutInfo("Selection").
    local blIdx to ReturnSelectionIdxFromList(bootFiles:Keys).
    OutDebug(blIdx:ToString).

    set bootLoader to bootFiles:Values[blIdx].
}

if Exists(blLocal)
{
    DeletePath(blLocal).
}

local formattedBootLoader to "{0}/{1}":Format(blDir, bootLoader:Name).
CopyPath(formattedBootloader, blLocal).
set core:bootFileName to blLocal:Replace("1:","").

if Exists(blLocal)
{
    OutMsg("Success").
    OutInfo("Reboot? [y|enter] / [n|backspace]").

    set g_TermChar to "".

    until false
    {
        GetTermChar().

        if g_TermChar = "y" or g_TermChar = Terminal:Input:Enter
        {
            Reboot.
        }
        else if g_TermChar = "n" or g_TermChar = Terminal:Input:Backspace
        {
            OutInfo("No reboot").
            break.
        }
    }
}
else
{
    OutMsg("ERROR: File not found").
}