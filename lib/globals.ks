// lib/globals - contains all global variables and delegates in one place
@lazyGlobal off.

// #include "0:/lib/libLoader.ks"

// *~ Dependencies ~* //
// #region
// #endregion

// *~ Config Settings ~* //
// #region
    set Config:IPU to 1000.
// #endregion


// *~ Simple Variables ~* //
// #region
    // Program flow control
    global g_ResultCode to 0.
    global g_TS to 0.

    // Program state for saving to archive
    global g_ProgramState to lexicon(
        "Program", 0
        ,"Runmode", 0
    ).

    // Staging
    global g_StageLimit to 3.
    global g_StageLimitSet to lexicon().

    // Tags
    global g_MissionTag to lexicon().
    global g_MissionParams to list().
    global g_ReturnMissionList to list("MaxAlt", "DownRange", "SubOrbital").

    // Terminal Metadata
    global g_Line   to 0.
    global g_Col    to 0.
    global g_DispGrid to lexicon(
        "SPEC", Lexicon(
            "HEADER", lexicon(
                "LINE", 0
                ,"COL", 1
                ,"COLWIDTH", 70
                ,"ROW", 2
                ,"ROWHEIGHT", 3
            ),
            "FLAGS", lexicon(
                "LINE", 10
                ,"COL", 4
                ,"COLWIDTH",  16
                ,"ROW", 1
                ,"ROWHEIGHT", 5
            ),
            "MAIN", lexicon(
                "LINE", 18
                ,"COL", 2
                ,"COLWIDTH",  34
                ,"ROW", 2
                ,"ROWHEIGHT", 20
            )
        )
    ).

    // Terminal Input
    global g_TermChar to "".
    global g_TermGrid to lexicon().

    // Engines
    global g_ActiveEngines          to list().
    global g_StageEngines_Active    to list().
    global g_StageEngines_Current   to list().
    global g_StageEngines_Next      to list().
    global g_ActiveEngines_Data     to lexicon().
    global g_BoostersArmed          to false.
    global g_BoosterObj             to lexicon().

    // Ship control
    global t_Val to 0.
    global s_Val to Ship:Facing.

    global g_StartTurn to 3750.
// #endregion



// *~ Collection Variables ~* //
// #region
global g_LoopDelegates  to lexicon(
    "Program", lexicon()
    ,"Staging", lexicon()
).
global g_PartInfo       to lexicon().
// #endregion



// *~ Global Delegates ~* //
// #region
// #endregion