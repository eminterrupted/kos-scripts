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
    // GetEngineStatus :: (Engine)<Engine> -> (Engine Status)<Lexicon>
    // Returns the status of a provided engine with ModuleEnginesRF
    global function GetEngineStatus
    {
        parameter _eng.

        local EngStatus    to "".
        local FailCause     to "".

        if _eng:HasModule("ModuleEnginesRF")
        {
            local m to _eng:GetModule("ModuleEnginesRF").
            
            set EngStatus to GetField(m, "Status").
            if EngStatus = "Failed"
            {
                set FailCause to GetField(m, "Cause").
            }
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