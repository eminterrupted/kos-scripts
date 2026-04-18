@lazyGlobal off.
clearScreen.

parameter _inObj,
          _tip        is "",
          _teeOutput  is false,
          _outputPath is "".

runOncePath("0:/lib/libLoader").

local sanitizedOutputPath to "".

if _teeOutput
{
    if _outputPath:MatchesPattern("^0:/data/ref/ppl/.*\..*")
    {
        set sanitizedOutputPath to _outputPath.
    }
    else if _outputPath:MatchesPattern("^0:/data/ref/ppl/\w+$")
    {
        set sanitizedOutputPath to _outputPath + ".txt".
    }
    else if _outputPath:MatchesPattern("^\./.*\..*")
    {
        set sanitizedOutputPath to _outputPath:Replace("./", "0:/data/ref/ppl/").
    }
    else if _outputPath <> ""
    {
        local lastLeafPos to _outputPath:FindLast("/") + 1.
        local _outputFile to _outputPath:Substring(lastLeafPos, _outputPath:Length - lastLeafPos).
        set sanitizedOutputPath to "0:/data/ref/ppl/" + _outputFile.
    } 
    else
    {
        local realTimeSpan to TimeSpan(KUniverse:RealTime).
        set sanitizedOutputPath to "0:/data/ref/ppl/ppl_{0}_{1}-{2}.txt":Format(_tip:Replace(" ","_"):Replace(":","_"), realTimeSpan:Year + 1970, realTimeSpan:Day).
    }
}

if _inObj:TypeName = "List_value`1" or _inObj:TypeName = "ListValue`1" or _inObj:TypeName = "List"
{
    if _teeOutput
    {
        WriteJson(_inObj, "{0}.json":Format(sanitizedOutputPath:Substring(0, sanitizedOutputPath:FindLast(".")))).
    }
    if _inObj[0]:typename = "string"
    {
        if _inObj[0]:startsWith("<tip>") 
        {
            set _tip to _inObj[0]:replace("<tip>","").
        }
    }
    DispList(_inObj, _tip, sanitizedOutputPath).
} 
else if _inObj:TypeName = "Lexicon" 
{
    if _teeOutput
    {
        WriteJson(_inObj, "{0}.json":Format(sanitizedOutputPath:Substring(0, sanitizedOutputPath:FindLast(".")))).
    }
    if _inObj:hasKey("<tip>") set _tip to _inObj["<tip>"].
    DispLex(_inObj, _tip, sanitizedOutputPath).
}


// Functions to power above

// DispList :: <list>ObjToPrint, [<string> User Tip ] -> <none>
// Pretty-prints a list
local function DispList
{
    parameter _passedObj,
              _passedTip is "PRETTY PRINT LIST",
              _teeOutputPath is "".

    local stCol to 0.
    local stLine to 12.

    local numCols to 2.
    local colSize to Terminal:width / numCols.
    local colLim to colSize * (numCols - 1).
    local lineLim to Terminal:height - 5.

    local titleDiv to { local div to "". from { local i to 0.} until i = _passedTip:Length step { set i to i + 1.} do { set div to div + "-". } return div.}.    
    set g_col to stCol.
    set g_line to stLine.

    local tee to _teeOutputPath:Length > 0.

    if _passedObj:isType("List")
    {
        from { local n is 0.} until n = _passedObj:Length step { set n to n + 1.} do 
        {
            if g_line = stLine 
            {
                print _passedTip at (g_col, g_line).
                print titleDiv:call() at (g_col, cr()).

                if tee
                {
                    log _passedTip to _teeOutputPath.
                    log titleDiv:call() to _teeOutputPath.
                }
            }

            if g_line < lineLim
            {
                local str to "[{0,3}] [{1,-30}]  ":format(n, _passedObj[n]).
                print str at (g_col, cr()).
                
                if tee
                {
                    log str to _teeOutputPath.
                }
            } 
            else if g_col < colLim
            {
                set g_col to g_col + colSize.
                set g_line to stLine + 2.
                local str to "[{0,3}] [{1,-30}]  ":format(n, _passedObj[n]).
                print str at (g_col, cr()).
                
                if tee
                {
                    log str to _teeOutputPath.
                }
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
              _passedTip is "PRETTY PRINT LEXICON",
              _teeOutputPath is "".

    local stCol to 0.
    local stLine to 2.

    local numCols to 2.
    local lineLim to Terminal:height - 5.
    local colSize to Terminal:width / numCols.
    local colLim to colSize * (numCols - 1).
    local maxKeyLen to 3.
    local maxValLen to 30.

    local tee to _teeOutputPath:Length > 0.

    if _passedTip = ""
    {
        if _passedObj:hasKey("<tip>") set _passedTip to _passedObj["<tip>"]:replace("<tip>","").
    }

    local titleDiv to { local div to "". from { local i to 0.} until i = _passedTip:Length step { set i to i + 1.} do { set div to div + "-". } return div.}.            

    set g_col to stCol.
    set g_line to stLine.

    clearScreen. 
    
    for key in _passedObj:keys 
    {
        set maxKeyLen to max(maxKeyLen, key:tostring:Length).
        set maxValLen to max(maxValLen, colSize - maxKeyLen - 5).
    }
    
    for key in _passedObj:keys
    {
        if g_line = stLine 
        {
                print _passedTip at (g_col, g_line).
                print titleDiv:call() at (g_col, cr()).
                cr().

                if tee
                {
                    log _passedTip to _teeOutputPath.
                    log titleDiv:call() to _teeOutputPath.
                }
        }
        
        local str to "[{0,10}] [{1,-25}]":format(key, _passedObj[key]).
        print str at (g_col, g_line).
        
        if tee
        {
            log str to _teeOutputPath.
        }

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