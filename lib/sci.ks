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
    // *- Function Group
    // #region
    // FunctionName :: (input params)<type> -> (output params)<type>
    // Description
    global function CollectSamples
    {
        parameter _p is ship:rootPart.

        if _p:HasModule("HardDrive")
        {
            _p:GetModule("HardDrive"):DoEvent("transfer data here").
        }
    }

    // #endregion
// #endregion