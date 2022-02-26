@lazyGlobal off.
clearScreen.

runOncePath("0:/lib/util").
runOncePath("0:/lib/disp").

parameter params to list().

DispMain(scriptPath(), false).

local eIdx to 0.
local randR to random().
local randG to random().
local randB to random().

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

local turnOff to false.
local rainbow to false.

print eHighlight.
print pHighlight.

OutMsg("Vessel: " + ship:name).

if params:length > 0
{
    set eIdx to params[0].

    if (eIdx:typename = "string")
    {
        if (eIdx = "off")
        {
            set eIdx to 0.
            set turnOff to true.
        }
        else if (eIdx = "random")
        {
            set eIdx to 1 + floor(9*random()).
        }
        else if (eIdx = "rainbow")
        {
            set eIdx to 0.
            set rainbow to true.
        }
    }
}

if (not rainbow)
{
    for el in ship:elements 
    {
        set eHighlight to highlight(el, ColorLex[ColorLex:keys[eIdx]]).
    }
}
else 
{
    for p in ship:parts
    {
        //use curated list of colors
        // set eIdx to 1 + floor(9*random()).
        // set eHighlight to highlight(p, ColorLex[ColorLex:keys[eIdx]]).

        //assign truly random colors, at random!
        set randR to random().
        set randG to random().
        set randB to random().
        set eHighlight to highlight(p, rgb(randR, randG, randB)).
    }
}

set pHighlight to highlight(ship:rootPart, white).

if (turnOff)
{
    for el in ship:elements
    {
        set eHighlight to highlight(el, black).
        set eHighlight:enabled to false. 
    }
    set pHighlight:enabled to false.   

    set turnOff to false.  
}