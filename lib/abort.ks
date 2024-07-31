// #include "0:/lib/depLoader.ks"
// #include "0:/lib/reentry.ks"
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
    global g_AbortSys_Armed to False.
    global g_AbortSys_Active to False.

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

//  *- Abort System Arming
// #region

    // ArmAbortSys :: (none) -> (sysState)<Lex(sysArmed, checkDel, actionDel)>
    // Arms the abort system (what happens when the Abort action is triggered)
    global function ArmAbortSystem
    {
        local LES to GetAbortSystem().

        if LES:ENG:Length > 0 and (LES:DC0:Length > 0 or LES:DC1:Length > 0)
        {
            local checkDel to {
                return Abort.
            }.

            local actionDel to {
                RunPath("0:/main/launch/launchAbort.ks", list()).
            }.
            return list(True, checkDel@, actionDel@).
        }
        else
        {
            return list(False, g_NulCheckDel@, g_NulActionDel@).
        }
    }

    // GetAbortSystem
    global function GetAbortSystem 
    {
        local LES to Lexicon(
            "ENG", list()
            ,"DC0", list()
            ,"DC1", list()
        ).
        
        for eng in Ship:Engines
        {
            if eng:Name:MatchesPattern("(LES|Launch.*Escape)") or eng:Tag:MatchesPattern("LES")
            {
                LES:ENG:Add(eng).
            }
        }

        for dc in Ship:Decouplers
        {
            if dc:Name:MatchesPattern("(LES|Launch.*Escape)")
            {
                LES:DC1:Add(dc).
            }
            else if dc:Tag:MatchesPattern("LES\|(DC$|DC0$)")
            {
                LES:DC0:Add(dc).
            }
            else if dc:Tag:MatchesPattern("LES\|DC1$")
            {
                LES:DC1:Add(dc).
            }
        }

        return LES.
    }
    
// #endregion
// #endregion