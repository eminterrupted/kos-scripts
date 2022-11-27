// #include "0:/lib/globals.ks"
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
        terminal:input:clear.
        wait 0.01.
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
        parameter _tag to core:tag.

        local _scriptId     to "".
        local _scriptStopStage to lex().
        local _tagLex       to lex().
        local _tagPrms      to list().
        local _tagScr       to list().
        local _tagSet       to "".
        local _tagStg       to "".
        local _tagStgCondition to "".
        local _tagStgLex    to lex().
        local _tagStgSet    to "".
        local _tagStgSplit  to list().
        local _tSplit       to _tag:split(";").
        local _tpSplit      to list().

        // from { local i to 0.} until i = _tSplit:length step { set i to i + 1.} do
        // for i in range(0, _tSplit:length, 1)
        from { local i to 0. local _tagFrag to list().} until i = _tSplit:length step { set i to i + 1. } do
        {
            set _scriptId to "{0}:{1}":format(core:part:uid, i).
            set _scriptStopStage to lex().
            set _tagFrag to _tSplit[i]:split("|").

            set _tagSet   to _tagFrag. // :_tSplit[i]:split("|")[1].
            // print "_tagSet: ({0})":format(_tagSet) at (2, 25).
            set _tagStgSet to _tagSet[1].
            // print "_tagStgSet ({0})":format(_tagStgSet) at (2, 27).
            if _tagStgSet:matchesPattern("[\[\]]")
            {
                // print "Pattern Matched ({0})":format(_tagStgSet) at (2, 30).
                // wait 0.01.
                // Breakpoint().
                set _tagStgSet to _tagStgSet:replace("[",""):replace("]",""):split(",").
                if _tagStgSet:length > 0 
                {
                    for _t in _tagStgSet
                    {
                        // print "_t: [{0}]":format(_t) at (2, 25).
                        // wait 0.01.
                        // Breakpoint().
                        set _tpSplit to choose _t:split(":") if _t:split(":"):length > 1 else _t:split(",").
                        // print "_tpSplit: ({0})":format(_tpSplit) at (2, 31).
                        // Breakpoint().
                        set _tagStg to _tpSplit[0].
                        set _tagStgCondition to _tpSplit[1].
                        set _scriptStopStage[_tpSplit[0]] to _tpSplit[1].
                    }
                }
                else
                {
                    set _scriptStopStage[_tagStg] to "MAIN". //print "_tpSplit <= 1 ({0})":format(_tpSplit) at (2, 40).
                }
            }
            else
            {
                // print "Pattern Not Matched ({0})":format(_tagStgSet) at (2, 30).
                // Breakpoint().
                set _tpSplit to _tagStgSet:split(":").
                if _tpSplit:length > 1
                {
                    set _tagStg to _tpSplit[0]:toNumber(0).
                    set _scriptStopStage[_tagStg] to _tpSplit[1].
                }
                else
                {
                    set _scriptStopStage[_tagStg] to "MAIN". //print "_tpSplit <= 1 ({0})":format(_tpSplit) at (2, 40).
                }
            }
            
            set _tagScr    to _tagFrag[0]:replace("]",""):split("["). 
            set _tagPrms   to choose _tagScr[1]:split(":") if _tagScr[1]:split(":"):length > 1 else _tagScr[1]:split(",").
            set _tagScr      to _tagScr[0].
            local _parsedTag to lex("TAG", _tSplit[i], "SCR", _tagScr, "PRM", _tagPrms, "STG", _scriptStopStage).
            set   _tagLex[_scriptId] to _parsedTag.
            set g_tag[_scriptId] to _parsedTag.
            set _tagStgLex[_scriptStopStage:keys[i]] to _scriptStopStage.
        }
        set g_stopStageLex["STPSTG"] to _tagStgLex.
        SetStopStage().

        return _tagLex.
    }

    // SetStopStage :: 
    // Sets the g_stopStage value to the next in the list.
    global function SetStopStage
    {
        parameter setNextValue to false.

        // print "g_stopStageLex:keys:length: {0}":format(g_stopStagelex:keys:length) at (2, 33).
        // print "g_stopStageLex: ({0})":format(g_stopStageLex["STPSTG"]) at (2, 34).
        local i to 0.
        if g_stopStageLex:keys:length > 1
        {
            local g_thisStage to g_stopStageLex["STPSTG"]:keys[i].
            // print g_stopStageLex["STPSTG"]:keys[0] at (2, 39).
            // for k in g_stopStageLex["STPSTG"]:keys
            // {
            //     print k at (2, 36 + i).
            //     set i to i + 1.
            // }
            // print g_stopStageLex["STPSTG"]:values[0]:values[0] at (5, 45).
            set g_stopStageCondition to "MAIN".
            if g_stopStageLex["STPSTG"]:hasKey(g_thisStage)
            {
                // set terminal:width to 120.
                // print g_stopStageLex at (2, 42).
                local l_thisContext to g_stopStageLex["STPSTG"][g_thisStage]:values[0].
                print "l_thisContext: [{0}]":format(l_thisContext) at (2, 50).
                print "g_stopStageCondition: [{0}]":format(g_stopStageCondition) at (2, 51).
                print "REF Present: {0}":format(g_stopStageLex:hasKey("REF")) at (2, 52).
                if g_stopStageLex:hasKey("REF")
                {
                    print "REF/STPSTG/{0} Present: {1}":format(l_thisContext, g_stopStageLex:hasKey("l_thisContext")) at (2, 53).
                }
                else print "REF Present: {1}":format(l_thisContext, false) at (2, 53).

                set g_stopStageCondition to g_stopStageLex["REF"][l_thisContext].
                // print "{0} ({1})":FORMAT(g_thisStage, g_stopStageLex["STPSTG"][g_thisStage]) at (2, 38).
                // print l_thisContext at (2, 39).
                // Breakpoint().
            }


            //Breakpoint().
            if setNextValue
            {
                if g_stopStageCondition
                {
                    g_stopStageLex:remove(g_stopStageLex["STPSTG"]:keys[0]).
                }
            }

            if g_stopStageLex["STPSTG"]:keys:length > 1
            {
                set g_stopStage to g_stopStageLex["STPSTG"]:values[0]:values[0].
                OutInfo("g_stopStage set to [{0}]":format(g_stopStage),1).
                g_stopStageLex["STPSTG"]:values[0]:remove(g_stopStageLex["STPSTG"]:values[0]:key[0]).
            }
            else if g_stopStageLex["STPSTG"]:keys:length = 1
            {
                set g_stopStage to g_stopStageLex["STPSTG"]:values[0]:values[0].
            }
            else 
            {
                set g_stopStage to 0.
            }
        }
        else
        {
            //print "[{0}]":format(g_stopStageLex) at (2, 35).
            // set g_stopStage to 0.
        }
    }
// #endregion