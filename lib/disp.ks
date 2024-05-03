// #include "0:/lib/depLoader.ks"
@LazyGlobal off.

// *~ Dependencies ~* //
// #region
// #endregion


// *~ Variables ~* //
// #region
    // *- Global
    // #region
    global g_col to 0.
    global g_line to 0.

    global g_termH to 45. // Terminal:Height.
    set Terminal:Height to g_termH.
    global g_termW  to 72. // Terminal:Width.
    set Terminal:Width to g_termW.

    // #endregion
    
    // *- Local
    // #region
    // #endregion

    // *- Global Anonymous Delegates
    // #region
    // #endregion

    // *- Local Anonymous Delegates
    // #region
    // #endregion
// #endregion


// *~ Functions ~* //
// #region

    // *- Basic utilities
    // #region

    // cr :: [<_line>] -> g_line
    // Increments g_line by one and returns the new value
    // Optionally accepts a param to set g_line to a new value before incrementing.
    global function cr
    {
        parameter _line is g_line.

        set g_line to choose _line + 1 if _line < g_termH else 10.
        return g_line.
    }
    
    // clr
    // Clears a line
    global function clr
    {
        parameter _line is g_line,
                  _len is Terminal:Width.

        print "":padright(_len) at (0, _line).
    }

    // OutInfo
    // Writes a line to the info section
    global function OutInfo
    {
        parameter _str,
                  _line is cr().

        set _str to "[INFO] " + _str.
        if _str:length > Terminal:Width
        {
            set _str to _str:SubString(0, Terminal:Width).
        }
        print _str:PadRight(Terminal:Width - _str:length) at (0, _line).
    }

    // OutMsg
    // Writes a line to the message section
    global function OutMsg
    {
        parameter _str,
                  _line is cr().

        set _str to "[MSG] " + _str.
        if _str:length > Terminal:Width
        {
            set _str to _str:SubString(0, Terminal:Width).
        }
        print _str:PadRight(Terminal:Width - _str:length) at (0, _line).
    }

    // OutString
    // Prints a string without a label
    global function OutStr
    {
        parameter _str,
                  _line is cr().

        set g_line to _line.
        set _str to _str + " ".

        if _str:length > Terminal:Width
        {
            print _str:SubString(0, Terminal:Width) at (0, g_line).
            print _str:SubString(Terminal:Width, _str:Length - Terminal:Width) at (0, cr()).
        }
        else
        {
            print _str:PadRight(Terminal:Width - _str:length) at (0, g_line).
        }
    }
    // #endregion

    // *- Display Modules
    // #region

    // DispPlan - Details of single plan
    global function DispPlan
    {
        parameter _plan
                 ,_line is g_line.

        set g_Line to _line - 1.

        local paramSplit to choose _plan[1]:Split(";") if _plan[1]:Contains(";") else _plan[1]:Split(",").
        local paramList to list().

        from { local i to 0.} until i >= paramSplit:Length step { set i to i + 1.} do
        {
            if paramSplit:Length > i
            {
                paramList:Add(paramSplit[i]).
            }
            else
            {
                paramList:Add("N/A").
            }
        }

        local _descriptList to list(
            "Script      : {0}":Format(_plan[0]) 
            ,"Params     : {0}":Format(paramList:Join(";"))
            ,"Stop Limit : {0}":Format(_plan[2]) 
        ).

        for str in _descriptList
        {
            OutStr(str, cr()).
        }
    }

    // DispPlans - paginated list of plans
    global function DispPlans
    {
        parameter _planList
                  ,_pageIdx is 0
                  ,_line is g_Line.

        set g_Line to _line.

        OutStr("[PAGE:{0}/{1}]":Format(_pageIdx, Ceiling(g_AvailablePlans:Length / 10)), g_line).
        OutStr("--------------", cr()).
        local startIdx to 10 * _pageIdx.
        local stopIdx to choose (startIdx + 10) if (g_AvailablePlans:Length - startIdx) >= 10 else g_AvailablePlans:Length - startIdx - 1.
        from { local i to startIdx. } until i > stopIdx step { set i to i + 1. } do
        {
            print "Printing: [{0}|{1}|{2}|{3}|{4}]":Format(_pageIdx, startIdx, stopIdx, i, Ceiling(g_AvailablePlans:Length / 10)) at (2, Terminal:Height - 5).
            OutStr("|- {0}: {1}  ":Format(i + 1, _planList[i]), cr()).
        }
        cr().
        OutStr("PRESS NUMBER FOR SELECTION ", cr()).
        OutStr("PRESS - / + TO PAGE", cr()).
    }

    // #endregion

// #endregion