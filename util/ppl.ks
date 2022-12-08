@lazyGlobal off.
clearScreen.

parameter inObj,
          tip is "".

runOncePath("0:/lib/disp.ks").
runOncePath("0:/lib/util.ks").

if inObj:TypeName = "List_value`1" or inObj:TypeName = "ListValue`1" or inObj:TypeName = "List"
{
    if inObj[0]:typename = "string"
    {
        if inObj[0]:startsWith("<tip>") 
        {
            set tip to inObj[0]:replace("<tip>","").
        }
    }
    DispList(inObj, tip).
} 
else if inObj:TypeName = "Lexicon" 
{
    if inObj:hasKey("<tip>") set tip to inObj["<tip>"].
    DispLex(inObj, tip).
}


// Functions to power above

// DispList :: <list>ObjToPrint, [<string> User Tip ] -> <none>
// Pretty-prints a list
local function DispList
{
    parameter _passedObj,
              _passedTip is "PRETTY PRINT LIST".

    local stCol to 0.
    local stLine to 2.

    local numCols to 2.
    local colSize to Terminal:width / numCols.
    local colLim to colSize * (numCols - 1).
    local lineLim to Terminal:height - 5.

    local titleDiv to { local div to "". from { local i to 0.} until i = _passedTip:length step { set i to i + 1.} do { set div to div + "-". } return div.}.    
    set g_col to stCol.
    set g_line to stLine.

    if _passedObj:isType("List")
    {
        from { local n is 0.} until n = _passedObj:length step { set n to n + 1.} do 
        {
            if g_line = stLine 
            {
                    print _passedTip at (g_col, g_line).
                    print titleDiv:call() at (g_col, cr()).
            }

            if g_line < lineLim
            {
                print "[{0,3}] [{1,-30}]  ":format(n, _passedObj[n]) at (g_col, cr()).
            } 
            else if g_col < colLim
            {
                set g_col to g_col + colSize.
                set g_line to stLine + 2.
                print "[{0,3}] [{1,-30}]  ":format(n, _passedObj[n]) at (g_col, cr()).
            } 
            else 
            {
                Breakpoint().
                clearScreen.
                set g_col to stCol.
                set g_line to stLine.
            }
        }
    }
}

// Lexicon
// Pretty print lexicons
global function DispLex 
{
    parameter _passedObj, 
              _passedTip is "PRETTY PRINT LEXICON".

    local stCol to 0.
    local stLine to 2.

    local numCols to 2.
    local lineLim to Terminal:height - 5.
    local colSize to Terminal:width / numCols.
    local colLim to colSize * (numCols - 1).
    local maxKeyLen to 3.
    local maxValLen to 30.

    if _passedTip = ""
    {
        if _passedObj:hasKey("<tip>") set _passedTip to _passedObj["<tip>"]:replace("<tip>","").
    }

    local titleDiv to { local div to "". from { local i to 0.} until i = _passedTip:length step { set i to i + 1.} do { set div to div + "-". } return div.}.            

    set g_col to stCol.
    set g_line to stLine.

    clearScreen. 
    
    for key in _passedObj:keys 
    {
        set maxKeyLen to max(maxKeyLen, key:tostring:length).
        set maxValLen to max(maxValLen, colSize - maxKeyLen - 5).
    }
    
    for key in _passedObj:keys
    {
        if g_line = stLine 
        {
                print _passedTip at (g_col, g_line).
                print titleDiv:call() at (g_col, cr()).
                cr().
        }
        print "[{0,10}] [{1,-25}]":format(key, _passedObj[key]) at (g_col, g_line).
        
        if g_line < lineLim
        {
            set g_line to cr().
        } 
        else if g_col < colLim
        {
            set g_col to g_col + colSize.
            set g_line to stLine + 2.   
        }
        else
        {
            Breakpoint().
            clearScreen.
            set g_col to stCol.
            set g_line to stLine.
        }
    }
}