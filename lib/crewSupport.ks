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


// ***~~~ Functions ~~~*** //
// #region

//  *- Life Support
// #region

    // CycleCO2Scrubbers :: (_moduleList)<List>, (_forceOn)<bool> -> (none)
    // Cycles LI-OH CO2 Scrubbers. Unless _forceOn is True, Will not enable any turned off, only cycle already-running scrubbers
    global function CycleCO2Scrubbers
    {
        parameter _moduleList is List(),
                  _forceOn is False.

        if _moduleList:Length = 0
        {
            set _moduleList to Ship:ModulesNamed("ProcessController").
        }

        // Cycle
        for loopCount in Range(0,1,1)
        {
            for m in _moduleList
            {
                if _forceOn
                {
                    for actStr in m:AllActions
                    {
                        if actStr:MatchesPattern("lioh.*scrubber")
                        {
                            local act to actStr:Substring(11, actStr:Length - 24).
                            DoAction(m, act).
                        }
                    }
                }
                else
                {
                    for evStr in m:AllEvents
                    {
                        if evStr:MatchesPattern("lioh.*running")
                        {
                            // 11: '(callable)' 
                            // 24: '(callable)' + ', isKSPEvent'
                            local ev to evStr:Substring(11, evStr:Length - 24).  Replace("(callable) ", ""):Replace(", is KSPEvent", "").
                            DoEvent(m, act).
                        }
                    }
                }
            }
            wait 3.
        }
    }

    
// #endregion
// #endregion