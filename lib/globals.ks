@lazyGlobal off.

// Global vars
global sVal             to ship:facing.
global tVal             to 0.

global g_activeEngines  to lexicon().

global g_stopStageCondition to "MAIN".
global g_stopStageConditionCheckVal to 0.
global g_stopStage to 9.
global g_tag to lex().

global g_initDisp to true.
global g_termChar to "".
global g_TS to 0.
global g_counter to 0.

global g_idx to 0.

global g_scriptFlags to lex().
global g_scriptFlagDelegates to lex().

// global objects
global g_cache to lex().

global g_partInfo to    lex(
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