// #include "0:/lib/libLoader.ks"
@lazyGlobal off.

// *~ Dependencies ~* //
// #region
// #endregion


// *~ Variables ~* //
// #region
    // *- Global
    // #region
    // #endregion

    // *- Local
    // #region
    global g_GridAssignments to lexicon().
    local  GridSpaceIdx to 0.
    local  GridSpaceLex to lexicon().
    // #endregion

    // *- Local Anonymous Delegates
    local l_GridRowLine to { 
        parameter _width , _char.  

        local str is "". 
        from { local i to 0.} until i = _width or i = Terminal:Width step { set i to i + 1.} do
        {
            set str to str + _char.
        }
        return str. 
    }.

    local l_GridColLine to {
        parameter _colWidth is 16, _char is "|".

        local colIdx to 0.
        local colCount to Floor(Terminal:Width / (_colWidth + 2)).  // Adding 2 to colWidth to account for grid lines
        local str to "|".
        until colIdx = colCount
        {
            from { local i to 1.} until i = _colWidth step { set i to i + 1.} do
            {
                set str to str + " ".
            }
            set colIdx to colIdx + 1.
            set str to str + _char.
        }
        return str.
    }.
    // #endregion
// #endregion


// *~ Functions ~* //
// #region

    // *~ Display Utilities
    // #region

    // cr :: (_inLine)<scalar>, [(_lineIncrement)]<scalar> -> (g_Line)<scalar>
    // Given a line number, sets g_line to the next line number and returns it
    global function cr
    {
        parameter _inLine is g_line,
                  _lineIncrement is 1.

        set g_Line to _inLine + _lineIncrement.
        return g_Line.
    }
    // #endregion

    // *- Message Display Functions
    // #region
    
    // OutMsg :: (Message)<string>, [(ErrorLevel)<Scalar>], [(TeeHUD)<bool>] -> (none)
    // Writes a message at line 5. 
    // TODO: If the ErrorLevel is 2 or higher, color codes the string for visibility
    global function OutMsg
    {
        parameter _str is "",
                  _errLvl is 0.
                  //_teeHUD is false. TODO: implement TeeHud function

        local msg_line to 8.
        if _str:length > 0
        {
            local errLabel to choose "MSG" if _errLvl < 1
                         else choose "WRN" if _errLvl < 2
                         else        "ERR".
            print "[{0}] {1} ":Format(errLabel, _str) at (2, msg_line).
        }
        else
        {
            for i in Range(1, Terminal:Width - 2, 1) //
            {
                set _str to _str + " ".
            }
            print _str at (1, msg_line).
        }
    }

    // OutInfo :: (Message)<string>, (LineIndex)<scalar> -> (none)
    // Writes a non-critical message at lines 6-8 depending on the line provided. 
    global function OutInfo
    {
        parameter _str is "",
                  _lineIdx is 0.
                  //_teeHUD is false. TODO: implement TeeHud function

        local line to 11.
        if _str:length > 0
        {
            print "[{0}] {1} ":Format("INFO", _str) at (2, line + _lineIdx).
        }
        else
        {
            for i in Range(1, Terminal:Width - 2, 1) //
            {
                set _str to _str + " ".
            }
            print _str at (1, line + _lineIdx).
        }
    }

    // *~ Display Components

    // DispAscentAngleStats :: (_statLex)<lexicon>, [(_line)<scalar>]
    // Does what it says. Since most of the vars in the ascentangle function are local,
    // it requires passing them all in via a telemetry-formatted lex
    global function DispAscentAngleStats
    {
        parameter _statLex.

        local titleStr to "ASCENT ANGLE".
        
        local boxIdx to 1.
        if g_GridAssignments:Values:Contains(titleStr)
        {
            set boxIdx to g_GridAssignments:Values:Find(titleStr).
        }
        else
        {
            for box in g_GridAssignments:Keys
            {
                if not g_GridAssignments[Box] = ""
                {
                    set boxIdx to box.
                    set g_GridAssignments[Box] to titleStr.
                }
            }
        }
        local col to GridSpaceLex[boxIdx][0].
        set g_Line to GridSpaceLex[boxIdx][1].
        print titleStr at (col, g_line).
        for key in _statLex:keys
        {
            print "|- {0,-16}: {1} ":format(key, _statLex[key]) at (col, cr()).
        }
    }

    // DispMain :: (_scriptPath)<Path> -> (nextLine)<scalar>
    // Prints the main terminal header, and returns the next available line for printing
    global function DispMain
    {
        parameter _scriptPath is ScriptPath(),
                  _termWidth is 72,
                  _termHeight is 0.

        set Terminal:Width to _termWidth.
        set Terminal:Height to choose _termHeight if _termHeight > 0 else 64.
        DoEvent(Core, "Open Terminal").

        set g_Line to 0.
        local progName      to "KASA MISSION CONTROL".
        local progVer       to "v0.01 {0} ({1})":Format(Char(5679), "Omega").
        local safeWidth     to Terminal:Width - 2 - progName:Length.
        local str to "{0,20}{1," + -(safeWidth) + "}".
        set str to str:Format(progName, progVer).
        
        print str at (0, g_Line).
        set str to "".
        for i in Range(0, Terminal:Width - 2, 1)
        {
            set str to str + "=".
        }
        print str at (0, cr()).
        print "MISSION: {0}":Format(Ship:Name)                  at (0, cr()).
        print "STATUS : {0}":Format(Ship:Status)                at (0, cr()).
        print "MET    : {0}":Format(TimeSpan(MissionTime):Full) at (0, cr()).
        print "PROGRAM: {0}":Format(_scriptPath)                at (0, cr()).
        cr().
        
        DispTermGrid(10, 68, 4, 1, true).
        set g_GridAssignments[0] to "MAIN".
        DispTermGrid(g_Line, 34, 16, 2).

        return g_Line.
    }
    // #endregion

    // *- Full Display
    // #region

    // DispTermGrid :: <scalar>_columnWidth, <scalar>_rowHeight -> <none>
    // Draws a grid on the terminal screen. Takes width of columns and height of rows as parameters.
    // Note: the function reserves one px on each side of the column for the grid lines
    // Example: On a 72col screen, a _columnWidth of 16 will result in 4 columns, with grid lines in between
    global function DispTermGrid
    {
        parameter _startAt      is 10,
                  _colWidth     is 34, 
                  _rowHeight    is 20,
                  _rowCount     is -1,
                  _refreshRef   is false.

        set g_Line to _startAt.

        local colWidthFloor to Floor(_colWidth).
        local colCount      to Floor((Terminal:Width) / (colWidthFloor + 2)).
        local colStr        to l_GridColLine:Call(_colWidth, "|").
        local colIdxList    to list(2).
        
        local rowLineWidth  to (_colWidth) * colCount.
        local headerStr     to l_GridRowLine:Call(rowLineWidth, "=").
        local rowStr        to l_GridRowLine:Call(rowLineWidth, "_").

        local rowCount      to choose _rowCount if _rowCount > 0 else Floor((Terminal:Height - g_Line - 5) / _rowHeight).
        local rowInnerIdx   to 0.
        local rowTotalIdx   to 0.

        if _refreshRef
        {
            set GridSpaceIdx    to 0.
            set GridSpaceLex    to lexicon().
            set g_GridAssignments to lexicon().
        }

        from { local i to 0.} until i = colCount step { set i to i + 1.} do
        {
            colIdxList:Add(2 + Mod(i * _colWidth, _colWidth)).
        }
        from { local iRow to 0.} until iRow = _rowCount step { set iRow to iRow + 1.} do
        {
            local rowLine to _startAt + 2 + Mod(iRow * _rowHeight, _rowHeight).
            from { local iCol to 0.} until iCol = colIdxList:Length step { set iCol to iCol + 1.} do
            {
                if g_GridAssignments:HasKey(GridSpaceIdx)
                {
                    if g_GridAssignments[GridSpaceIdx] = ""
                    {
                        set GridSpaceLex[GridSpaceIdx] to list(colIdxList[iCol], rowLine).
                    }
                }
                else
                {
                    set GridSpaceLex[GridSpaceIdx] to list(colIdxList[iCol], rowLine).
                    set g_GridAssignments[GridSpaceIdx] to "".
                }
                set GridSpaceIdx to GridSpaceIdx + 1.
            }
        }
    
        // print the header line
        print headerStr at (0, g_Line).
        
        // Print the grid for this row
        until rowTotalIdx = rowCount
        {
            set rowInnerIdx to 0.
            until rowInnerIdx >= _rowHeight - 1 or g_Line >= Terminal:Height - 6
            {
                print colStr at (0, cr()).
                set rowInnerIdx to rowInnerIdx + 1.
            }
            set rowTotalIdx to rowTotalIdx + 1.
            if rowTotalIdx < rowCount print rowStr at (0, cr()).
        }
        print headerStr at (0, cr()).
        // Neat
    }
    // #endregion
// #endregion