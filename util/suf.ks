@lazyGlobal off.

parameter p. 

local dCol to 2. 
local dLine to 20.

local col to dCol.
local line is dLine.

local suffixList to p:suffixnames.

clearScreen. 
print "SUFFIX NAMES FOR PART: " + p:name at (dCol, dLine - 2).
print "----------------------------------------------------" at (dCol, dLine - 1).

from { local n is 0.} until n = suffixList:length step { set n to n + 1.} do {

    if line < terminal:height - 3 {
        print "[" + n + "] " + suffixList[n] at (col, line).
        set line to line + 1.
    } else if col = dCol {
        set col to dCol + 40.
        set line to dLine.
        print "[" + n + "] " + suffixList[n] at (col, line).
        set line to line + 1.
    } else {
        print "** [press any key] **" at ( terminal:width - 25, terminal:height - 1).
        terminal:input:getChar().
        clearScreen.
        set col to dCol.
        set line to dLine.

        print "SUFFIX NAMES FOR PART: " + p:name at (dCol, dLine - 2).
        print "----------------------------------------------------" at (dCol, dLine - 1).
    }
}