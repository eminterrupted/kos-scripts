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
    global g_RunMode to 0.
    global g_Program to 0.
    global g_TS to 0.
    global g_LastUpdate to 0.

    // Program state for saving to archive
    global g_ProgramState to lexicon(
        "Program", 0
        ,"Runmode", 0
    ).

    // Staging
    global g_StageLimit to 3.
    global g_StageLimitSet to list().

    // Tags
    global g_MissionTag to lexicon().
    global g_MissionParams to list().
    global g_ReturnMissionList to list(
        "DownRange"     // Guided downrange suborbital, no reentry guidance
        ,"MaxAlt"       // Guided or unguided max altitude
        ,"SSO"          // Unguided launch, guided reentry
        ,"SubOrbital"   // Fully guided launch and reentry
    ).

    global g_GuidedAscentMissions to list(
        "DownRange"
        ,"Orbit"
        ,"PIDOrbit"
        ,"SubOrbital"
    ).

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
    global g_BoostersArmed   to false.
    global g_HotStagingArmed to false.
    global g_BoosterObj      to lexicon().

    // Ship control
    global t_Val to 0.
    global s_Val to Ship:Facing.

    global g_AngDependency to lexicon().
    global g_StartTurn to 3750.

    global g_PIDS to lexicon(). // This will hold all PID loops we use across multiple scripts
// #endregion



// *~ Collection Variables ~* //
// #region
global g_LoopDelegates  to lexicon(
    "Program", lexicon()
    // ,"Staging", lexicon()
    ,"Events", lexicon()
).
global g_PartInfo       to lexicon().
// #endregion



// *~ Global Delegates ~* //
// #region
// #endregion