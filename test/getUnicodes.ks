parameter upperLim to 5000,
          outPath is Path("0:/log/data/unicodeCharacters.txt").

runPath("0:/lib/util").

DispMain(scriptPath()).

local g_log to initLog().
local termVertLim to terminal:height - 5.
local termHoriLim to terminal:width - 3.

set g_line to 2.

for idx in range(0, upperLim, 1)
{
    set ch to char(idx).
    set fStr to "  {0,4}    {1,-10}":format(idx, char(idx)).
    tee(fStr).
}

tee(" ").
tee("Unicode sequence complete up to " + upperLim).
wait 1.

local function tee
{
    parameter str, 
              col is 2.

    prn(str, col).
    logOut(str).
}

local function prn
{
    parameter _str, 
              col.

    local farX to termHoriLim - col.
    if g_line > termVertLim
    {
        clrDisp().
        set g_line to 2.
    }
    print ("{0,-" + farX + "}"):format(_str) at (col, cr()).
}

local function logOut
{
    parameter str.

    if g_log:isType("VolumeFile") g_log:writeln(str).
}

local function initLog
{
    if exists(outPath)
    {
        set g_log to open(outPath).
        return g_log.
    }
    else
    {
        create(outPath).
        set g_log to open(outPath).
        g_log:writeln("| CODE |    CHAR    |").
        g_log:writeln("---------------------").
        return g_log.
    }
}