@lazyGlobal off.
clearScreen.

runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_util").

disp_main(scriptPath(), false).


local colors to list(
    red,
    magenta,
    rgb(0.25, 0, 0.75),
    blue,
    cyan,
    green,
    yellow,
    rgb(1, 1, 0)
).

local colorStr to list(
    "Red",
    "Magenta",
    "Violet",
    "Blue",
    "Cyan",
    "Green",
    "Yellow",
    "Orange"
).

local line to 9.

local eIdx to 0.
local eHighlight to "".
local pHighlight to "".

disp_msg("Vessel: " + ship:name).

for e in ship:elements 
{

    print "Name   : " + e:name at (2, cr()).
    print "Idx    : " + eIdx at (2, cr()).
    print "Color  : " + colorStr[eIdx] at (2, cr()).
    cr().

    set eHighlight to highlight(e, colors[eIdx]).

    set eIdx to eIdx + 1.
}

disp_info("Root Part: " + ship:rootpart).
set pHighlight to highlight(ship:rootPart, white).


local function cr
{
    set line to line + 1.
    return line. 
}