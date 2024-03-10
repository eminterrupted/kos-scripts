@LazyGlobal off.

// *~ Variables ~* //
// #region
    // *- Global
    // #region

    // Mission plans
    global g_MissionPlan is lexicon(
        "M", list()
        ,"P",  list()
    ).
    global g_MissionPlans is list().

    // State / context
    global g_Context    is "".
    global g_Program    is 0.
    global g_Runmode    is 0.
    global g_State      is list(0,0,0).
    global g_StateCachePath is "1:/state.ves".

    // Terminal stuff
    global g_TermChar    is "".
    global g_TermHasChar is false.
    global g_TermQueue   is Queue().

    // Timestamps
    global g_TS to 0.
    // #endregion
// #endregion