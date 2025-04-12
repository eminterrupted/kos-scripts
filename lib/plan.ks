@LazyGlobal off.

// *~ Dependencies ~* //
// #region

// #endregion

// *~ Variables ~* //
// #region
    // *- Common Values
    // #region
    global CoreTagRef to lexicon(
        "regex", lex(
            "cat", lex(
                "drgr",    "(downrange(r)?|dr)",
                "obit",      "(orbit(al)?|obt)",
                "sndr",      "(sounder|sdr|sr)",
                "subo",   "(suborbit(al)?|sub|so)"
            )
        )
    ).

    // #endregion

    // *- Delegates
    // #region

    // #endregion
// #endregion

// *** Library Setup Code *** //
// This should rarely be used! //
// #region

// #endregion

// *~ Functions ~* //
// #region

    // *- Tag Parser
    // #region

    // parse_core_plan :: (_core<kOSProcessor>) -> parsedPlan<lexicon>
    // Given a kOSProcessor core with a valid plan kOS nametag, parses it and returns a lex containing the components
    global function parse_core_plan
    {
        parameter _core is core.

        local pTag to _core:Tag.

        local ptL0 to lexicon(
            "_Tag", pTag,
            "Cat", "",
            "Param", list(),
            "StgLim", list(0)
        ).

        if pTag:Length > 0
        {
            local ptL1 to pTag:Split("|").
            local ptL2 to list().

            set ptL0["Cat"] to ptL1[0].
            if ptL1:Length > 1
            {
                set ptL2 to list().
                local spltSet to ptL1[1]:Split(";").
                if spltSet[0] = "cur"
                {
                    ptL2:add(Round(compass_for(Ship, Ship:Facing), 1)).
                }
                else
                {
                    local convertedStr to spltSet[0]:ToNumber(-998).
                    if convertedStr = -998
                    {
                        ptL2:Add(str).
                    }
                    else
                    {
                        ptL2:Add(convertedStr).
                    }
                }
                from { local _i to 0.} until _i = spltSet:Length step { set _i to _i + 1.} do
                {
                    local _str to spltSet[_i].
                    if _i = 0
                    {
                        if _str = "cur"
                        {
                            set _str to Round(compass_for(Ship, Ship:Facing), 2).
                        }
                    }
                    local convertedStr to choose _str:ToNumber(-999) if _str:HasSuffix("ToNumber") else _str.
                    ptL2:Add(convertedStr).
                }
                set ptL0["Param"] to ptL2:Copy.
            }
            
            if pTag:Length > 2
            {
                set ptL2 to list().
                local spltSet to ptL1[2]:Split(";").
                for str in spltSet
                {
                    local convertedStr to str:ToNumber(-998).
                    if convertedStr = -998
                    {
                        ptL2:Add(str).
                    }
                    else
                    {
                        ptL2:Add(convertedStr).
                    }
                }
                set ptL0["StgLim"] to ptL2:Copy.
            }
        }

        return ptL0.
    }

    
    // FunctionName :: (input params)<type> -> (output params)<type>
    // Description
    
    // #endregion
    
    // #endregion

// #endregion