// lib/globals - contains all global variables and delegates in one place
@lazyGlobal off.

// #include "0:/lib/libLoader.ks"

// *~ Dependencies ~* //
// #region
// #endregion

// *~ Config Settings ~* //
// #region
    set Config:IPU to 1600.

    global g_DualCore to ship:partsTagged("Core2"):Length > 0.
// #endregion


// *~ Simple Variables ~* //
// #region
    // Program flow control
    global g_MainProcess to ScriptPath().
    global g_Counter to 0.
    global g_Debug to False.
    global g_Debug_Max to True.
    global g_DbgOffset to 0.
    global g_Slowbug to False.
    global g_LastUpdate to 0.
    global g_Program to 0.
    global g_ResultCode to 0.
    global g_RunMode to 0.

    // Global timestamp / timer placeholders
    global g_TR     to 0.
    global g_TS     to 0.
    global g_TS0    to 0.
    global g_TS0Ref to 0.
    global g_TS1    to 0.
    global g_TS1Ref to 0.
    global g_TS2    to 0.
    global g_TS2Ref to 0.
    global g_TS3    to 0.
    global g_TS3Ref to 0.
    global g_TSi    to 0.

    // Program state for saving to archive
    global g_ProgramState to lexicon(
        "Program", 0
        ,"Runmode", 0
    ).

    // Staging
    global g_StageCurrent to Stage:Number.
    global g_StageLast to Stage:Number.
    global g_StageNext to Stage:Number - 1.
    global g_StageLimit to 3.
    global g_StageLimitSet to list().
    global g_StageTracker to Stage:Number.

    // Tags
    global g_MissionTag to lexicon().
    
    global g_ReturnMissionList to list(
        "DownRange"     // Guided downrange suborbital, no reentry guidance
        ,"DownRanger"   // ^
        ,"MaxAlt"       // Guided or unguided max altitude
        ,"SSO"          // Unguided launch, guided reentry
        ,"SubOrbital"   // Fully guided launch and reentry
    ).

    global g_GuidedAscentMissions to list(
        "DownRange"
        ,"DownRanger"
        ,"Orbit"
        ,"PIDOrbit"
        ,"SubOrbital"
        ,"PIDSubOrbital"
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
    global g_TermCharRead to False.

    // Engines
    global g_BoosterObj      to lexicon().

    // Ship Metadata
    global g_ShipUIDs to list().

    // State Flags
    global g_AutoStageArmed         to False.
    global g_BoostersArmed          to False.
    global g_BoosterAirStart        to False.
    global g_DecouplerEventArmed    to False.
    global g_FairingsArmed          to False.
    global g_HotStagingArmed        to False.
    global g_InOrbit                to False.
    global g_LESArmed               to False.
    global g_MECOArmed              to False.
    global g_OnDeployActive         to False.
    global g_OnStageEventArmed      to False.
    global g_RCSArmed               to False.
    global g_SpinActive             to False.
    global g_SpinArmed              to False.
    global g_UIDUpdaterArmed        to False.

    // Ship control
    global r_Val to 0.
    global s_Val to Ship:Facing.
    global t_Val to 0.

    global g_AngDependency to lexicon().
    global g_MECO to 0.
    global g_StartTurn to 3750.
    global g_SteeringDelegate to { return Ship:Facing.}.

    global g_PIDS to lexicon(). // This will hold all PID loops we use across multiple scripts
// #endregion



// *~ Collection Variables ~* //
// #region

// Launch azimuth data object
global g_azData to list().

global g_ShipStageCache to lexicon().

// Terminal input mappings by script or context
global g_InputMappings to lexicon(
    "Context", lexicon()
    ,"Script", lexicon()
).

// loop delegate / event container
global g_LoopDelegates  to lexicon(
    "Program", lexicon()
    // ,"Staging", lexicon()
    ,"Events", lexicon()
    ,"RegisteredEventTypes", lexicon()
).

// Dictionary of module events mapped to friendly names
global g_ModEvents to lexicon(
    "Antenna", lexicon(
        "ModuleDeployableAntenna", lexicon(
            "Deploy",   "extend antenna"
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
            ,"DecoupleInterstage", "decouple top node"
        )
        ,"ProceduralFairingDecoupler", lexicon(
            "Decouple", "jettison fairing"
        )
    )
    ,"Solar", lexicon(
        "ModuleROSolar", lexicon(
            "Deploy", "extend solar panel"
        )
    )
    ,"Science", lexicon(
        "Experiment", lexicon(
            "Deploy", list(
                "start: magnetic scan"
                ,"start: micrometeorite detection"
            )
            ,"Retract", list(
                "stop: magnetic scan"
                ,"stop: micrometeorite detection"
            )
        )
    )
).

// Dictionary of miscellaneous part info and mappings
global g_PartInfo       to lexicon(
    "PartModRef", lexicon(
        "Antenna",     list("ModuleDeployableAntenna", "ModuleRealAntenna")
        ,"Decoupler",  list("ModuleAnchoredDecoupler", "ModuleDecouple", "ProceduralFairingDecoupler")
        ,"Solar",      list("ModuleROSolar")
        ,"Science",    list("Experiment")
    )
).

// Dictionary of miscellaneous propellant info and mappings
global g_PropInfo       to lexicon().
// #endregion



// *~ Global Delegates ~* //
// #region
// #endregion