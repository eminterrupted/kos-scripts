@lazyGlobal off.

parameter inObj. 

local dCol to 2. 
local dLine to 20.

if inObj:typename = "ListValue`1" {
    print_list().
} else if inObj:typename = "Lexicon" {
    print_lex().
}


local function print_lex {

    local col to dCol.
    local line is dLine.

    clearScreen. 
    print "PRETTY PRINT LEXICON" at (dCol, dLine - 2).
    print "--------------------" at (dCol, dLine - 1).

    for key in inObj:keys {
        if line < terminal:height - 3 {
            print "[" + key + "] = " + inObj[key] at (col, line).
            set line to line + 1.
        } else {
            print "** [press any key] **" at ( terminal:width - 25, terminal:height - 1).
            terminal:input:getChar().
            clearScreen.
            set col to dCol.
            set line to dLine.

            print "PRETTY PRINT LEXICON" at (dCol, dLine - 2).
            print "--------------------" at (dCol, dLine - 1).
        }
    }
}

local function print_list {

    local col to dCol.
    local line is dLine.

    clearScreen. 
    print "PRETTY PRINT LIST" at (dCol, dLine - 2).
    print "-----------------" at (dCol, dLine - 1).

    from { local n is 0.} until n = inObj:length step { set n to n + 1.} do {

        if line < terminal:height - 3 {
            print "[" + n + "] " + inObj[n] at (col, line).
            set line to line + 1.
        } else if col = dCol {
            set col to dCol + 40.
            set line to dLine.
            print "[" + n + "] " + inObj[n] at (col, line).
            set line to line + 1.
        } else {
            print "** [press any key] **" at ( terminal:width - 25, terminal:height - 1).
            terminal:input:getChar().
            clearScreen.
            set col to dCol.
            set line to dLine.

            print "PRETTY PRINT LIST" at (dCol, dLine - 2).
            print "-----------------" at (dCol, dLine - 1).
        }
    }
}