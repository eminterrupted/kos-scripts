@lazyGlobal off.

global sVal             to ship:facing.
global tVal             to 0.

global g_stopStageCondition to "MAIN".
global g_stopStageConditionCheckVal to 0.
global g_stopStage to 9.
global g_tag to lex().

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

// local delegates for below
local reachedAp         to { parameter _tsAP is time:seconds + eta:apoapsis. return time:seconds >= _tsAP.}.
local reachedPe         to { parameter _tsPE is time:seconds + eta:apoapsis. return time:seconds >= _tsPE.}.
local reachedReentry    to { parameter _altPad is 25000. return ship:altitude <= body:atm:height + _altPad.}.
local reachedMECO       to { parameter _ves to ship. return _ves:availableThrust > 0. }.

global g_stopStageLex to lex(
    "REF", lex(
        "AP",       reachedAp@
        ,"PE",      reachedPe@
        ,"REENTRY", reachedReentry@
        ,"MAIN",    false
        ,"MECO",    reachedMECO@
    )
    ,"STAGES", lex(
    )
).