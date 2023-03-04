// #include "0:/lib/loadDep.ks"
@lazyGlobal off.

// *~ Dependencies ~* //
// #region
// #endregion


// *~ Variables ~* //
// #region
    // *- Local
    // #region
    // #endregion

    // *- Global
    // #region
    global g_LogDelegates to lexicon(
        "ATM", lexicon(
            "Altitude"      ,{ return Round(Ship:Altitude). }
            ,"Pressure"     ,{ return Round(Body:ATM:AltitudePressure(Ship:Altitude), 5). }
            ,"Q-Pressure"   ,{ return Round(Ship:Q, 5). }
            ,"AirSpeed"     ,{ return Round(Ship:AirSpeed, 2). }
            ,"VerticalSpeed",{ return Round(Ship:VerticalSpeed, 2). }
            ,"GroundSpeed",  { return Round(Ship:GroundSpeed, 2). }
        )
    ).
    // #endregion
// #endregion


// *~ Functions ~* //
// #region
    // *- Function Group
    // #region
    // GetAtmosphericData :: <none> -> (AtmosphericData)<Lexicon>
    // Returns Pressure and soon temp data at the current altitude
    global function GetAtmosphericData
    {
        local dataObj to lexicon().

        for delKey in g_LogDelegates:ATM:Keys
        {
            set dataObj[delKey] to g_logDelegates:ATM[delKey]:Call().
        } 
        return dataObj.
    }
    // #endregion
// #endregion