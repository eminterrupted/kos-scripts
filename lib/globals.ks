@lazyGlobal off.

// Global vars
global s_Val             to ship:facing.
global t_Val             to 0.

global g_ErrLvl to 0.

// Mission Plan Variables
global g_MP_Json to "".
global g_MP_List to list().
global g_missionPlan to "".

// List and Lex of active engines and active engines + data
global g_ActiveEngines      to list().
global g_ActiveEnginesLex   to lexicon().
global g_ConsumedResources  to lexicon().

// LogFile Directory
global g_LogPath to "0:\_mission\{0}\mission.log".

// Staging
global g_StopStage to 99.
global g_HotStageArmed to false.
global g_SpinStageArmed to false.

// Tagging
global g_Tag to lexicon().

// Random useful globals
global g_TermChar to "".

// Time globals
global g_ET_Mark to Time:Seconds. // Starting point for evaluating elapsed time
global g_ET to Time:Seconds - g_ET_Mark. // Elapsed time from g_ET_Mark
global g_ETA to -1.
global g_ETA_ECO to -1.
global g_ETA_TS to -1.
global g_TS to 0.
global g_TS_LastUpdate to 0.

global g_Counter to 0.
global g_Idx to 0.

// global objects
global g_Cache to lex().

global g_PartInfo to    lex(
    "Engines", lex(
            "SepMotors",    list(
                "sepMotorSmall",
                "ROSmallSpinMotor",
                "SnubOtron"
            ),
            "SolidFuels", list(
                "NGNC",
                "PSPC"
            )
        ), 
    "DockingPorts",     lex(), 
    "Decouplers",       lex(), 
    "Tanks",            lex()
).

global g_ResIgnoreList to list(
    "ElectricCharge"
    ,"Oxygen"
    ,"Atmosphere"
    ,"WasteAtmosphere"
    ,"Shielding"
    ,"_AirPump"
).

global g_StageInfo to lexicon(
    "HotStage",         lexicon()
    ,"SpinStabilized",  lexicon()
    ,"Engines",         lexicon()
    ,"Resources",       lexicon()
    ,"Stages",          lexicon()
).

global g_ShipLex to lexicon(
    "StageInfo", g_StageInfo
).