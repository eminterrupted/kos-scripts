@lazyGlobal off.

// Global vars
global s_Val             to ship:facing.
global t_Val             to 0.

global g_ErrLvl to 0.
global g_DebugOut to true.

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
global g_HotStageActive to false.
global g_HotStageArmed to false.
global g_SpinStageArmed to false.

// Tagging
global g_Tag to lexicon(
     "PCN", ""
    ,"SID", ""
    ,"PRM", list()
    ,"ASL", 0
).

// Terminal Input Globals
global g_TermChar            to "".
global g_TermChar_LastUpdate to 0.

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



// This is the loop delegate lexicon. 
// It will hold delegates that should be iterated through at specific points in the gxLaunch loop, 
// with the keys mapping to the before, during, and after loop calls the loop will make to execute these
//
// - 0 (BEFORE) : Runs before anything else in the loop runs, even before the program block lookup
// - 1 (PROCESS): Runs this after program block has been located but before anything else in the program. Not quite during, but after all delegates in BEFORE have run at least
// - 2 (END)    : Runs after the program block has been executed, so at the end of the loop
global g_RegisteredLoopDelegates to lex(
    "BEGIN",   lex()
    ,"PROCESS", lex()
    ,"END",     lex()
).


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