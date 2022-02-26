@lazyGlobal off.
clearScreen.

runOncePath("0:/lib/util").
runOncePath("0:/lib/disp").

DispMain(scriptPath(), false).

local line to 9.
local eIdx to 0.

local eHighlight to "".
local pHighlight to "".
print eHighlight.
print pHighlight.

OutMsg("Vessel: " + ship:name).

for el in ship:elements 
{

    print "Name   : " + el:name at (2, crl()).
    print "Idx    : " + eIdx at (2, crl()).
    print "Color  : " + ColorLex:keys[eIdx] at (2, crl()).
    crl().

    set eHighlight to highlight(el, ColorLex[ColorLex:keys[eIdx]]).
    set eIdx to eIdx + 1.
}

OutInfo("Root Part: " + ship:rootpart).
set pHighlight to highlight(ship:rootPart, white).

Breakpoint().

for el in ship:elements
{
    set eHighlight to highlight(el, black).
    set eHighlight:enabled to false. 
}
set pHighlight:enabled to false.

local function crl
{
    set line to line + 1.
    return line. 
}