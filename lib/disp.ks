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

    // *- Function Group
    // #region

    global function cr
    {
        parameter _line is g_line.
        
        set g_line to _line + 1.
        return g_line.
    }
    
    // #endregion

// #endregion