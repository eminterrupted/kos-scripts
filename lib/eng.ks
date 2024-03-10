// #include "0:/lib/depLoader.ks"
@LazyGlobal off.

// *~ Dependencies ~* //
// #region
// #endregion


// *~ Variables ~* //
// #region
    // *- Global
    // #region
    global g_engConfigs is lexicon(
        "XLR43-NA-1", lex( "BT", 65)
    ).
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

    // GetEngineBurnTime
    global function GetEngineBurnTime
    {
        parameter _eng.

        local burnTime to -1.

        if _eng:IsType("Engine")
        {
            if g_engConfigs:Keys:Contains(_eng:Config)
            {
                set burnTime to g_engConfigs[_eng:Config]:BT.
            }
        }
        else if _eng:IsType("String")
        {
            if g_engConfigs:Keys:Contains(_eng)
            {
                set burnTime to g_engConfigs[_eng]:BT.
            }
        }

        return burnTime.
    }
    
    // #endregion

// #endregion