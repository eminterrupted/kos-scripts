// #include "0:/lib/loadDep.ks"
@lazyGlobal off.

// *~--- Dependencies ---~* //
// #region
// #endregion


// *~--- Variables ---~* //
// #region
    // *- Local

    // *- Global
// #endregion

// *~--- Functions ---~* //
// #region


// *- Utilities and useful functions
// #region

    // Breakpoint :: [<string>PromptString] -> none
    // Halts the script with an optional prompt until the user presses a key
    global function Breakpoint
    {
        parameter promptStr to "".

        local actStr to "*** PRESS ANY KEY TO CONTINUE ***".
        local actFrmt to "{0," + round((terminal:width - actStr:length) / 2) + "}" + actStr + "{0," + round((terminal:width - actStr:length) / 2) + "}".
        print promptStr at (0, terminal:height - 3).
        print actFrmt:format(" ") at (0, terminal:height - 2).
        wait until terminal:input:haschar.
    }

// #endregion



// *- Script Flags - For setting, caching, and manipulating flags used in scripts
// #region

    // InitScriptFlags
    // Sets up the script flags object
    global function InitScriptFlags
    {
        local iKey to "".
        local iVar to "".
        local flagLex to lex("REF", lex("NAME", lex(), "ID", lex())).
        
        from { local i to 0.} until i = flagLex["REF"]["ID"]:Keys:Length step { set i to i + 1.} do
        {
            local idLex to flagLex["REF"]["ID"].
            set iKey to idLex:keys[i].
            set iVar to idLex:values[i].
            set flagLex["REF"]["NAME"][iVar] to iKey.
            if flagLex:hasKey(iKey)
            {
            }
            else
            {
                set flagLex[iKey] to false.
            }
        }
        
        return flagLex.
    }

    // ToggleScriptFlag :: <string>FlagID, [<string>FlagVal] -> <bool>NewFlagValue
    // Toggles a script flag
    global function ToggleScriptFlag
    {
        parameter _flagID,
                _flagVal is "toggle".

        local flagCurrent to false.  // Set to false by default as we will toggle on in the next step

        if _flagVal = "toggle"
        {
            if g_scriptFlags:hasKey(_flagID) 
            {
                set flagCurrent to g_scriptFlags[_flagID].
            }
            else 
            {
                set flagCurrent to false.  // Set to false by default as we will toggle on in the next step
            }
        }
        else if _flagVal = false or _flagVal = "false"
        {
            set flagCurrent to true. 
        }
        
        // Here is where we invert the value, then write to g_scriptFlags.
        local flagResult  to choose false if flagCurrent else true.
        set g_scriptFlags[_flagID] to flagResult.
        local str to "{0}: {1}":format(g_scriptFlags["REF"]["ID"][_flagID], flagResult).
        OutInfo(str).
        print str at (40, 4).

        return flagResult.
    }

    // SetScriptFlag :: <string>FlagID, [<string>FlagVal] -> <bool>NewFlagValue
    // Sets a script flag to a provided value, and returns it
    global function SetScriptFlag
    {
        parameter _flagID,
                _flagVal.

        local flagName to g_scriptFlags["Ref"][_flagID].
        set   g_scriptFlags[_flagID] to _flagVal.
        OutInfo("[{0}] {1} was set to {2}":format("SetScriptFlag", _flagID, flagName, _flagVal)).
        OutScriptFlags().

        return _flagVal.
    }
// #endregion

// *- Terminal Input
// #region

    // GetTermChar :: none -> <terminalCharacter>CurrentTerminalCharacter
    // Returns the current character waiting on the terminal stack, if any
    global function GetTermChar
    {
        if terminal:input:hasChar
        {
            set g_termChar to terminal:input:getChar.
        }
        else
        {
            set g_termChar to "".
        }
        terminal:input:clear.
        return g_termChar.
    }

    // GetTermInput :: Alias for GetTermChar
    global function GetTermInput
    {
        return GetTermChar().
    }

// #endregion

// *- Tag parsing
// #region

    // Parses a core's tag for script execution
    global function ParseCoreTag
    {
        parameter _tag to core:tag,
                  _addToGlobals to true.

        local _tagLex        to lex().
        local _tSplit        to _tag:split(";").
        local _tpSplit      to list().

        // from { local i to 0.} until i = _tSplit:length step { set i to i + 1.} do
        // for i in range(0, _tSplit:length, 1)
        from { local i to 0. local _tagFrag to list().} until i = _tSplit:length step { set i to i + 1. } do
        {
            local _scriptId to "{0}:{1}":format(core:part:uid, i).
            set _tagFrag to _tSplit[i]:split("|")[1].

            //local _tagFrag  to _tSplit[i]:split("|").
            //print _tagFrag   at (2, 38).
            if _tagFrag:length <= 1
            {
                print _tagFrag at (2, 37).
                Breakpoint().
            }
            else if _tagFrag:length = 2
            {
                print _tagFrag at (2, 37).
                Breakpoint().
            }

            local _tagStg   to _tagFrag[1]. // :_tSplit[i]:split("|")[1].
            //Breakpoint().
            local _tagStgLex  to lexicon().

            if _tagStg:matchesPattern("[\[\]]")
            {
                set _tagStg to _tagFrag:replace("[",""):replace("]","").
                set _tagStg to _tagStg:split(",").
                if _tagStg:length > 1 
                {
                    for _t in _tagStg 
                    {
                        set _tpSplit to _t:split(":").
                        set _tagStgLex[_tpSplit[1]] to _tpSplit[0]:toNumber().
                    }
                }
            }
            else
            {
                set _tagStg to _tagStg:toNumber(0).
                set _tagStgLex["MAIN"] to _tagStg.
            }
            
            local _tagScr    to _tSplit[i]:split("|")[0]:replace("]",""):split("["). 
            local _tagPrms   to choose _tagScr[1]:split(",") if _tagScr:length > 1 else list().
            set _tagScr      to _tagScr[0].
            
            local _parsedTag to lex("TAG", _tSplit[i], "SCR", _tagScr, "PRM", _tagPrms, "STG", _tagStgLex).
            set   _tagLex[_scriptId] to _parsedTag.
            if _addToGlobals
            {
                set g_tag[_scriptId] to _parsedTag.
                set g_stopStageLex to _tagStgLex.
            }
            //set g_stopStageLex to _tagStgLex.
            SetStopStage().
        }

        return _tagLex.
    }

    // SetStopStage :: 
    // Sets the g_stopStage value to the next in the list.
    global function SetStopStage
    {
        parameter setNextValue to false.

        if g_stopStageLex:keys:length > 0
        {
            set g_stopStageCondition to g_stopStageLex:keys[0].
            if setNextValue
            {
                if g_stopStageLex["REF"][g_stopStageCondition]
                {
                    g_stopStageLex:remove(g_stopStageLex:keys[0]).
                }
            }

            if g_stopStageLex:keys:length > 1
            {
                set g_stopStage to g_stopStageLex:values[0].
            }
            else if g_stopStageLex:keys:length = 1
            {
                set g_stopStage to g_stopStageLex["MAIN"].
            }
            else 
            {
                set g_stopStage to 0.
            }
        }
        else
        {
            set g_stopStage to 0.
        }
    }
// #endregion