// #include "0:/lib/depLoader.ks"
@LazyGlobal off.

// ***~~~ Dependencies ~~~*** //
// #region
// #endregion


// ***~~~ Variables ~~~*** //
// #region
    
    // *- Local
    // #region
    // #endregion

    // *- Global
    // #region
    global g_DataLog to "0:/data/logs/{0}.csv":Format(Ship:Name:Replace(" ","-")).
    // set g_LogOut to true.
    // #endregion
// #endregion

// ***~~~ Delegate Objects ~~~*** //
    // *- Local Anonymous Delegates
    // #region
    // #endregion

    // *- Global Anonymous Delegates
    // #region
    // #endregion
// #endregion


// Any common code needed to run as part of setup, run here
if g_LogOut
{
    if exists(g_DataLog) DeletePath(g_DataLog).
    log "MET,effPitAng,adjPitLim,curAltPres,tgtAltPitAng,curAlt,curAltErr,curApoErr,curEffErr,curTurnAltErr,curProPit,obtProPit,obtProPitAdj,srfProPit,srfProPitAdj" to g_DataLog.
}


// ***~~~ Functions ~~~*** //
// #region

//  *- Function Group
// #region

    // FunctionName :: (input params)<type> -> (output params)<type>
    // Description
    
// #endregion
// #endregion