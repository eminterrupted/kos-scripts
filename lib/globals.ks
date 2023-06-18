// *~ Global Variables ~* //
// #region
    
    // *- Program flow
    // #region
    global g_Mission  to "".     // The mission tag, used to determine which plan to use
    global g_PlanLex to lexicon().

    global g_LoopDelegates to lexicon().
    // #endregion

    // Staging
    // #region
    global g_StageLimit to 0.   // This is the stage number that the autostager will stop at, if armed
    // #endregion

    // Strings
    // #region
    global g_ShipNameNormalized to Ship:Name:Replace(" ","_").
    // #endregion

// #endregion