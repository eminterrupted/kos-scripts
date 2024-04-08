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
    global g_termW  to 90. // Terminal:Width.
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

// #endregion