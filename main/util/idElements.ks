@lazyGlobal off.
clearScreen.

runOncePath("0:/lib/util").
runOncePath("0:/lib/disp").

parameter params to list().

DispMain(scriptPath(), false).

local line to 9.
local eIdx to 0.

//0 "Red"
//1 "Magenta"
//2 "Violet"
//3 "Blue"
//4 "Cyan"
//5 "Green"
//6 "Yellow"
//7 "Orange"
//8 "White"
//9 "Black"

local eHighlight to "".
local pHighlight to "".
print eHighlight.
print pHighlight.

OutMsg("Vessel: " + ship:name).

if params:length > 0
{
    set eIdx to params[0].
}

for e in ship:elements 
{

    print "Name   : " + e:name at (2, crl()).
    print "Idx    : " + eIdx at (2, crl()).
    print "Color  : " + ColorLex:keys[eIdx] at (2, crl()).
    crl().

    set eHighlight to highlight(e, ColorLex[ColorLex:keys[eIdx]]).
}

OutInfo("Root Part: " + ship:rootpart).
set pHighlight to highlight(ship:rootPart, white).

Breakpoint().

for e in ship:elements
{
    set eHighlight to highlight(e, black).
    set eHighlight:enabled to false. 
}
set pHighlight:enabled to false.

local function crl
{
    set line to line + 1.
    return line. 
}