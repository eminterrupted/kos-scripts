clearScreen.

parameter parts to ship:parts.

if not (defined(partIdx)) global partIdx to 0.

local preTag to "".
local postTag to "".
local line to 0.

from { local i to partIdx.} until i >= parts:length step {set i to i + 1.} do {
    if line >= terminal:height - 5
    {
        set line to 0.
        clearScreen.
    }
    
    print "----------------------------------------------" at (0, cr()).
    set p to parts[i].
    set partIdx to i.
    set preTag to p:tag.
    set hl to highlight(p, cyan).
    print "Part Index: " + partIdx + "/" + (parts:length - 1) at (0, cr()).
    print "Part Name : " + p:name at (0, cr()).
    print "Part Tag  : " + preTag at (0, cr()).
    cr().
    print "Press Enter to rename, Backspace to skip, or Home for facing vector" at (0, cr()).
    local cont to false.
    until cont
    {
        if terminal:input:hasChar
        {
            local tChar to terminal:input:getChar.
            if tChar = terminal:input:backspace
            {
                set cont to true.
            }
            else if tChar = terminal:input:return
            {
                local tagDone to false.
                set postTag to preTag.
                print "Enter new part tag: " + postTag at (0, cr()).
                until tagDone
                {
                    if terminal:input:hasChar
                    {
                        set tChar to terminal:input:getChar(). 
                        if tChar = terminal:input:return
                        {
                            set p:tag to postTag.
                            set tagDone to true.
                            set cont to true.
                        }
                        else
                        {
                            if tChar = terminal:input:backspace
                            {
                                if postTag:length > 0 set postTag to postTag:remove(postTag:length - 1, 1).
                            }   
                            else
                            {
                                set postTag to postTag + tChar.
                            }
                        }
                        print postTag + " " at (20, line).
                    }
                }
                cr(). 
                print "Part " + partIdx + " tag changed from [" + preTag + "] to [" + postTag + "]" at (0, cr()).
                wait 0.25.
            }
            else if tChar = terminal:input:homeCursor
            {
                set pDraw to vecDraw(p:position, p:facing:forevector * 5, cyan, p:name, 2.5, true, 0.15).
            }
        }
    }
    set hl:enabled to false.
    clearVecDraws().
    print "----------------------------------------------" at (0, cr()).
    cr().
}

unset partIdx.
print "Tagging Complete" at (0, cr()).

local function cr 
{
    set line to line + 1.
    return line.
}