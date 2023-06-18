// *~ Global Variables ~* //
// #region
    
    // *- Vessel Control
    // #region
    global s_Val to Ship:Facing.
    global t_Val to 0.
    // #endRegion

    // *- Program flow
    // #region
    global g_LoopDelegates to lexicon().    // An object that will be iterated on in scripts, typically with a check and action delegate
    global g_Mission  to "".                // The mission tag, used to determine which plan to use
    global g_PlanLex to lexicon().          // Flight plan in a lexicon for easy parsing
    global g_ResultCode to 0.               // Used by functions to set the result status before returning
    // #endregion

    // *- Staging
    // #region
    global g_StageLimit to 0.   // This is the stage number that the autostager will stop at, if armed
    // #endregion

    // *- Strings
    // #region
    global g_ShipNameNormalized to Ship:Name:Replace(" ","_").  // Removes spaces for file-safe naming
    // #endregion

    // *- Terminal
    // #region
    global g_TermChar to "".    // A global buffer for the terminal character, requires GetTermChar() to be run
    // #endregion

    // Info Objects
    global g_PartRef to lexicon(). // Random collection of part references

// #endregion