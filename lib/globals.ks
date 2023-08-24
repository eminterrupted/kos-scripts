// lib/globals - contains all global variables and delegates in one place
@lazyGlobal off.

// #include "0:/lib/libLoader.ks"

// *~ Dependencies ~* //
// #region
// #endregion

// *~ Config Settings ~* //
// #region
    set Config:IPU to 1000.

    global g_DualCore to ship:partsTagged("Core2"):Length > 0.
// #endregion


// *~ Simple Variables ~* //
// #region
    // Program flow control

    global g_Counter to 0.
    global g_Debug to False.
    global g_Debug_Max to True.
    global g_Slowbug to False.
    global g_LastUpdate to 0.
    global g_Program to 0.
    global g_ResultCode to 0.
    global g_RunMode to 0.

    // Global timestamp / timer placeholders
    global g_TS to 0.
    global g_TS0 to 0.
    global g_TS1 to 0.
    global g_TS2 to 0.
    global g_TS3 to 0.
    global g_TSi to 0.

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
    global g_TermHasChar to False.

    // Engines
    global g_BoosterObj      to lexicon().

    // State Flags
    global g_AutoStageArmed         to False.
    global g_BoostersArmed          to False.
    global g_DecouplerEventArmed    to False.
    global g_HotStagingArmed        to False.
    global g_FairingsArmed          to False.
    global g_OnStageEventArmed      to False.
    global g_MECOArmed              to False.
    global g_LESArmed               to False.
    global g_RCSArmed               to False.

    // Ship control
    global t_Val to 0.
    global s_Val to Ship:Facing.

    global g_AngDependency to lexicon().
    global g_MECO to 0.
    global g_StartTurn to 3750.
    global g_SteeringDelegate to { return Ship:Facing.}.

    global g_PIDS to lexicon(). // This will hold all PID loops we use across multiple scripts
// #endregion



// *~ Collection Variables ~* //
// #region
global g_LoopDelegates  to lexicon(
    "Program", lexicon()
    // ,"Staging", lexicon()
    ,"Events", lexicon()
).
global g_ModEvents to lexicon(
    "Antenna", lexicon(
        "ModuleDeployableAntenna", lexicon(
            "Extend",   "extend antenna"
            ,"Retract", "retract antenna"
            ,"Toggle",  "toggle antenna"
        )
        ,"ModuleRealAntenna", lexicon(
            "Transmit",  "transmit data"
        )
    )
    ,"Decoupler", lexicon(
        "ModuleAnchoredDecoupler", lexicon(
            "Decouple", "decouple"
        )
        ,"ModuleDecouple", lexicon(
            "Decouple", "decouple"
        )
        ,"ProceduralFairingDecoupler", lexicon(
            "Decouple", "jettison fairing"
        )
    )
).

global g_PartInfo       to lexicon().
global g_PropInfo       to lexicon().
// #endregion



// *~ Global Delegates ~* //
// #region
// #endregion