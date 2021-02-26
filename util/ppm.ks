@lazyGlobal off.

parameter part. 

local line is 5.

clearScreen. 
print "MODULES FOR PART: " + part:name.
print "----------------------------------------------------".
print " ".

from { local n is 0.} until n = part:modules:length step { set n to n + 1.} do 
{
    local m is part:getModuleByIndex(n).

    if line < terminal:height - 35 
    {
        set line to line + 1.
        print "MODULE(" + m:name + "):".

        set line to line + 1 + m:allactions:length + m:allevents:length + m:allfields:length.
        print m.

        set line to line + 1.
        print " ".
    }
    else 
    {
        print "** [press any key] **" at ( terminal:width - 30, terminal:height - 5).
        terminal:input:getChar().
        clearScreen.
        set line to 0.
    }
}