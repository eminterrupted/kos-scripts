@lazyGlobal off.

// Global vars
global s_Val             to ship:facing.
global t_Val             to 0.

// Mission Plan Variables
global g_missionPlan to "".

// List and Lex of active engines and active engines + data
global g_ActiveEngines      to list().
global g_ActiveEnginesLex   to lexicon().


global g_StopStage to 99.
global g_Tag to lexicon().

// Random useful globals
global g_TermChar to "".
global g_TS to 0.
global g_Counter to 0.
global g_Idx to 0.

// global objects
global g_Cache to lex().

global g_PartInfo to    lex(
    "Engines", lex(
            "SepMotors",    list(
                "sepMotorSmall",
                "ROSmallSpinMotor"
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