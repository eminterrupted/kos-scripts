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
    // #endregion
// #endregion


// *~ Functions ~* //
// #region

    // *- Engine Module Helpers
    // #region
    // GetEngineStatus :: (Engine)<Engine|PartModule> -> (Engine Status)<Lexicon>
    // Returns the status of a provided engine with ModuleEnginesRF
    global function GetEngineStatus
    {
        parameter _eng. // Can be either a part or module

        local EngStatus to "".
        local FailCause to "".
        local engMod    to "".

        if _eng:IsType("PartModule")
        {
            set engMod to _eng.
            set EngStatus to GetField(engMod, "Status").
        } 
        else if _eng:HasModule("ModuleEnginesRF")
        {
            set engMod to _eng:GetModule("ModuleEnginesRF").
        }

        if EngStatus:MatchesPattern("Fail") 
        {
            set FailCause to GetField(engMod, "Cause").
        }

        return lexicon(
             "STATUS", EngStatus
            ,"CAUSE" , FailCause
        ).
    }
    // #endregion

    // *- Engine Data
    // #region
    // FunctionName :: (input params)<type> -> (output params)<type>
    // Description
    // { code }
    // #endregion

// #endregion