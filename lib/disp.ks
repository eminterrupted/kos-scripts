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

    global g_termH to Terminal:Height. // Terminal:Height.
    // set Terminal:Height to g_termHeight.
    global g_termW  to Terminal:Width. // Terminal:Width.
    // set Terminal:Width to g_termWidth.

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
    
    global function clr
    {
        parameter _line is g_line,
                  _len is Terminal:Width.

        print "":padright(_len) at (0, _line).
    }
    // #endregion

// #endregion