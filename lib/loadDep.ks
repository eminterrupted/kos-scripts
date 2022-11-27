parameter _initDisp to true.

// Global vars
runOncePath("0:/lib/globals.ks").

// External libs
runOncePath("0:/kslib/lib_navball.ks").

// KUSP libs
runOncePath("0:/lib/disp.ks").
runOncePath("0:/lib/util.ks").
runOncePath("0:/lib/vessel.ks").

// local Vars
local l_altPad to 25000.

// local delegates for below
local reachedAp         to { if g_TS = 0 { set g_TS to time:seconds + eta:apoapsis.} if g_TS < (time:seconds + eta:apoapsis) { set g_TS to 0. return true.} else { return false.}.}.
local reachedPe         to { if g_TS = 0 { set g_TS to time:seconds + eta:periapsis.} if g_TS < (time:seconds + eta:periapsis) { set g_TS to 0. return true.} else { return false.}.}.
local reachedReentry    to { return ship:altitude <= body:atm:height + l_altPad.}.
local reachedMECO       to { return ship:availableThrust > 0. }.
local returnMain        to { return false. }.

global g_stopStageLex to lex(
    "REF", lex(
        "AP",       reachedAp@
        ,"PE",      reachedPe@
        ,"REENTRY", reachedReentry@
        ,"MAIN",    returnMain@
        ,"MECO",    reachedMECO@
    )
    ,"STAGES", lex(
    )
    ,"STPSTG", lex( 
    )
).

// Setup Functions
if _initDisp InitDisp().
ParseCoreTag().

//print "[{0}]":format(g_stopStageLex) at (2, 25).
// PrettyPrintObject(g_stopStageLex).
terminal:input:clear.
// until false
// {
//     if terminal:input:hasChar break.
// } 