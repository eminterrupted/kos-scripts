// #include "0:/lib/depLoader.ks"
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
    // #endregion
// #endregion


// *~ Functions ~* //
// #region
    // *- Function Group
    // #region
    // GetValidExperiments :: (_part)<Part> -> (validExperiements)<Lexicon>
    // Given a part with Experiment modules, returns the ones that are currently active
    // **NOTE** : Due to a limitation between KSP and kOS, the part's PAW window must be 
    //            opened before this function can see active experiements
    global function GetValidExperiments
    {
        parameter _part.

        local expObj to lexicon().

        for exp in _part:ModulesNamed("Experiment")
        {
             if exp:AllEvents[0] <> "(callable) _, is KSPEvent" 
             {
                local expAction to GetKSPActionFromExperiment(exp:AllEvents[0]).
                if not expAction[1]:Contains("running") and expAction[1]:Length > 0
                {
                    set expObj[expAction[0]] to list(exp, expAction[1]).
                }
             }
        }
        
        return expObj.
    }
    // #endregion
// #endregion



global function GetKSPActionFromExperiment
{
    parameter _string.

    local expName to "".
    local expAction to "".

    local stringSplit to _string:Split("<b>").
    if stringSplit:Length > 1 {
      set expName to stringSplit[1]:Substring(0, stringSplit[1]:Find("<")).
      set expAction to _string:Replace("(callable) ",""):Replace(", is KSPAction").
    }
    return list(expName, expAction).
}