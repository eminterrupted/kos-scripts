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

    global g_termHeight to 60. // Terminal:Height.
    global g_termWidth  to 72. // Terminal:Width.

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

        set g_line to _line + 1.
        return g_line.
    }
    
    // #endregion

// #endregion