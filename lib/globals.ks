// lib/globals - contains all global variables and delegates in one place
@lazyGlobal off.

// #include "0:/lib/libLoader.ks"

// *~ Dependencies ~* //
// #region
// #endregion



// *~ Simple Variables ~* //
// #region
    // Program flow control
    global g_ResultCode to 0.

    // Staging
    global g_StageLimit to 3.

    // Tags
    global g_MissionTag to lexicon().

    // Terminal Metadata
    global g_Line   to 0.
    global g_Col    to 0.

    // Terminal Input
    global g_TermChar to "".

    // Engines
    global g_ActiveEngines          to list().
    global g_StageEngines_Active    to list().
    global g_StageEngines_Current   to list().
    global g_StageEngines_Next      to list().

    // Ship control
    global t_Val to 0.
    global s_Val to Ship:Facing.
// #endregion



// *~ Collection Variables ~* //
// #region
global g_LoopDelegates  to lexicon().
global g_PartInfo       to lexicon().
// #endregion



// *~ Global Delegates ~* //
// #region
// #endregion