@lazyGlobal off.

global sVal             to ship:facing.
global tVal             to 0.

global g_tag to lex().
global g_stopStageCondition to "MAIN".
global g_stopStage to 9.

global g_termChar to "".

global g_scriptFlags to lex().
global g_scriptFlagDelegates to lex().

// global objects
global g_cache to lex().

global g_partInfo to    lex(
"Engines", lex(
        "SepMotors",    list(
            "sepMotorSmall",
            "ROSmallSpinMotor"
        )
    ), 
"DockingPorts",     lex(), 
"Decouplers",       lex(), 
"Tanks",            lex()
).

global g_stopStageLex to lex(
    "REF", lex(
        "AP",       { parameter _etaAP. return time:seconds >= _etaAP.}
        ,"PE",      { parameter _etaPE. return time:seconds >= _etaPE.}
        ,"REENTRY", { parameter _altPad. return ship:altitude <= body:atm:height + _altPad.}
        ,"MAIN",    { return true.}
        ,"MECO",    { return ship:availableThrust > 0. }
    )
).