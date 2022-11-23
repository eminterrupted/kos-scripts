// Global vars
runOncePath("0:/lib/globals.ks").

// External libs
runOncePath("0:/kslib/lib_navball.ks").

// KUSP libs
runOncePath("0:/lib/disp.ks").
runOncePath("0:/lib/util.ks").
runOncePath("0:/lib/vessel.ks").

// Setup Functions
ParseCoreTag().
//print "[{0}]":format(g_stopStageLex) at (2, 25).
// PrettyPrintObject(g_stopStageLex).
terminal:input:clear.
// until false
// {
//     if terminal:input:hasChar break.
// } 

local function PrettyPrintObject
{
    parameter _obj.

    if _obj:IsType("Lexicon") 
    {
        for k in _obj:keys
        {
            OutInfo("Key: {0}   Value: {1}":format(k, _obj[k])).
            BreakPoint().
        }
    }
    else if _obj:IsType("List")
    {
        for k in _obj
        {
            OutInfo("Item: {0}":format(k)).
            Breakpoint().
        }
    }
}