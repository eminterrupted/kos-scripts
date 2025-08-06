// #include "0:/lib/depLoader.ks"
@LazyGlobal off.

// *~ Dependencies ~* //
// #region
    // #include "0:/lib/depLoader.ks"
// #endregion


// *~ Variables ~* //
// #region
    // *- Global
    // #region
    // #endregion
    
    // *- Local
    // #region
    // #endregion

    // *- Global Anonymous Delegates
    // #region
    // #endregion

    // *- Local Anonymous Delegates
    // #region
    // #endregion
// #endregion


// *~ Functions ~* //
// #region

    // *- Mercury part handlers
    // #region

    global function SetupMercuryReentryHandler
    {
        // RCS Unit Drogue Jettison
        if Ship:PartsNamedPattern("ROC-MercuryRCS(2)?BDB"):Length > 0
        {
            local m to Ship:PartsNamedPattern("ROC-MercuryRCS(2)?BDB")[0]:GetModule("ModuleDecouple").
            local checkDel to { parameter _params is list(). return Alt:Radar <= 2500.}.
            local actionDel to { parameter _params is list(). if _params:length > 0 { if DoEvent(m, "Jettison Nose Unit") = 2 { DoEvent(m, "Decouple"). } return false.} else return false.}.
            CreateLoopEvent("NoseconeJett", "DC", list(m), checkDel@, actionDel@).
        }

        // Deploy the Mercury capsule landing bag if present\
        if Ship:PartsNamed("ROC-MercuryHS"):Length > 0
        {
            local m to Ship:PartsNamedPattern("ROC-MercuryHS")[0]:GetModule("ModuleAnimateGeneric").
            local checkDel to { parameter _params is list(). return Alt:Radar <= 500.}.
            local actionDel to { parameter _params is list(). if _params:length > 0 { if DoEvent(m, "Deploy Landing Bag") = 2 { DoEvent(m, "Deploy Landing Bag"). } return false.} else return false.}.
            CreateLoopEvent("LandingBagDeploy", "LDGBAG", list(m), checkDel@, actionDel@).
        }
    }
    // #endregion

// #endregion