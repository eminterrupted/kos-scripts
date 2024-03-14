@LazyGlobal off.

// *~ Variables ~* //
// #region
    // *- Global
    // #region

    // Abort flag
    global g_Abort     is false.
    global g_AbortCode is 0.

    // Errors / Error codes
    global g_ErrorCode  is 0.
    // g_ErrorCodeRef is populated by scripts / libraries for later use. 
    // Format: "EX00{0}P{1}R000{2}C{3}":Format(g_Program, (g_Runmode), g_ExeContext, g_Errorcode).
    // "E00{g_ErrorContext}{g_Errorcode}{g_Runmode}R{g_Program}P{g_ExecutionContext}C"

    global g_ErrorCodeRef is lexicon(). 

    // Mission plans
    global g_MissionPlan is lexicon(
        "M", list()
        ,"P",  list()
    ).
    global g_MissionPlans is list().

    // Program Flow / Standard Output
    global g_Debug      is false.
    global g_ExitCode   is 0.

    // Program State / Runmode / Context
    global g_Context    is 0.
    global g_Program    is 0.
    global g_Runmode    is 0.
    global g_StageStop  to Stage:Number.

    global g_State      is list( 0, 0, 0, g_StageStop).
    global g_StateCachePath is "1:/state.ves".

    // Terminal stuff
    global g_TermChar    is "".
    global g_TermHasChar is false.
    global g_TermQueue   is Queue().

    // Timestamps
    global g_TS to 0.

    // #endregion
// #endregion

// *~ Misc Global Reference Objects
// #region

    // AlphabetLookup
    global g_Alphabet to list(
         "A"
        ,"B"
        ,"C"
        ,"D"
        ,"E"
        ,"F"
        ,"G"
        ,"H"
        ,"I"
        ,"J"
        ,"K"
        ,"L"
        ,"M"
        ,"N"
        ,"O"
        ,"P"
        ,"Q"
        ,"R"
        ,"S"
        ,"T"
        ,"U"
        ,"V"
        ,"W"
        ,"X"
        ,"Y"
        ,"Z"      
    ).

// #endregion