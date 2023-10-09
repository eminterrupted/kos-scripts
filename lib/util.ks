// #include "0:/lib/libLoader.ks"
@lazyGlobal off.

// *~ Dependencies ~* //
// #region
// #endregion


// *~ Variables ~* //
// #region
    // *- Local
    // #region
    local _ti to Terminal:Input.

    local l_sfxReference to lexicon(
        0, "0:/sfx/ZeldaUnlock.json"
    ).
    local l_timeTable to lexicon(
        "d", Earth:Orbit:Period
        ,"h", 3600
        ,"m", 60
        ,"s", 1
        ,"ms", 0.001
    ).
    // #endregion

    // *- Global
    // #region
    global g_kKode to list(
                _ti:UpCursorOne, 
                _ti:UpCursorOne, 
                _ti:DownCursorOne,
                _ti:DownCursorOne,
                _ti:LeftCursorOne,
                _ti:RightCursorOne,
                _ti:LeftCursorOne,
                _ti:RightCursorOne,
                "b",
                "a"
            ).
    global g_correctKodeInputsProvided to 0.
    global g_correctKodeInputsRequired to g_kKode:Length.

    global g_TermQueue to queue().
    // #endregion
// #endregion


// *~ Functions ~* //
// #region

    // *- Terminal Utilities
    // #region
    
        // Breakpoint :: [(Time to wait)<scalar>], [(Wait Message)<string>] -> (Continue)<bool>
        // Creates a breakpoint, and will continue on any key press and/or timeout if one is provided
        // By default, timeout is 0 which is indefinite
        global function Breakpoint
        {
            parameter _timeout is 0,
                    _waitMsg is "BREAKPOINT".

            local doneFlag      to false.
            local timeoutToggle to false.
            local timeoutTS     to Time:Seconds + _timeout.
            
            local msgStr        to "*** {0} ***":Format(_waitMsg).
            local msgCol        to (Terminal:Width - msgStr:Length) / 2.
            local msgLine       to Terminal:Height - 5.

            local infoStr       to "* Press ENTER to continue *".
            local infoCol       to (Terminal:Width - infoStr:Length) / 2.
            local infoLine      to Terminal:Height - 4.

            print msgStr at (msgCol, msgLine).

            until doneFlag
            {
                if CheckTermChar(Terminal:Input:Enter, True) // Adding update _updateGlobal flag to perform the update and check in one call
                {
                    set doneFlag to true. // User pressed Enter, we are done here
                    set g_TermChar to "".
                }

                if _timeout > 0 
                {
                    set infoStr to "* ENTER: Continue | END: Pause Timeout ({0, -7}s) *":Format(timeoutTS - Time:Seconds).
                    set infoCol to (Terminal:Height - infoStr:Length) / 2.

                    if g_TermChar = Terminal:Input:EndCursor // Since this is a simple check AND we know g_TermChar was already updated, we skip the function call here
                    {
                        set timeoutToggle to choose false if timeoutToggle 
                            else true.
                    }    

                    if timeoutToggle
                    {
                        set timeoutTS to timeoutTS + 1.
                    } 
                    else if Time:Seconds >= timeoutTS 
                    {
                        set doneFlag to true. // Timeout, we are done here
                    }
                }
                
                // print infoStr at (infoCol, infoLine).
                wait 0.1.
            }

            // Cleanup the display
            set msgStr to "".
            set infoStr to "".
            for i in Range(0, Terminal:Width - 1)
            {
                set msgStr to msgStr + " ".
                set infoStr to infoStr + " ".
            }
            print msgStr at (0, msgLine).
            print infoStr at (0, infoLine).

            return true.
        }

        // SECRET SECRET
        global function CheckKerbaliKode
        {
            if g_TermQueue:EMPTY // If queue has no elements, no-op
            {
                return.
            }

            if g_kKode[g_correctKodeInputsProvided] = g_TermQueue:Pop()
            {
                set g_correctKodeInputsProvided to g_correctKodeInputsProvided + 1.
                OutInfo("kKode [{0}/{1}]":Format(g_correctKodeInputsProvided, g_correctKodeInputsRequired), 1).

                if g_correctKodeInputsProvided = g_correctKodeInputsRequired
                {
                    // fireworks explodes everywhere
                    // a small pixelated kerbal waddles away into the sunset
                    OutInfo("KerbaliKode activated", 1).
                    PlaySFX(0).
                    OutInfo("", 1).
                    set g_TermHeight to g_TermHeight + 16.
                    set g_TermWidth to g_TermWidth + 34.
                    DispMain(g_MainProcess).
                    set g_Debug to not g_Debug. //toggle debug on or off
                }
                return.
            }

            OutInfo("", 1).
            set g_correctKodeInputsProvided to 0.
        }

        // CheckTermChar :: (Char to check)<TerminalInput> -> (Match)<bool>
        // Returns the boolean result of a check of the provided value against g_TermChar. 
        // _updateGlobal will set g_TermChar to the next char in the queue for comparison if available
        // With _updateGlobal flag set, no need to call GetTermChar() first
        global function CheckTermChar
        {
            parameter _char,
                    _updateGlobal is False.

            if _updateGlobal
            {
                GetTermChar().
            }
            local result to _char = g_TermChar.
            return result.
        }

        // GetTermChar :: (none) -> (Was new char present)<bool>
        // Checks to see if a terminal character is present. 
        // If yes, set g_TermChar to it and return true.
        global function GetTermChar
        {
            if Terminal:Input:HasChar 
            { 
                set g_TermChar to Terminal:Input:GetChar.
                g_TermQueue:Push(g_TermChar).
                set g_TermHasChar to True.
                Terminal:Input:Clear().
            }
            // else
            // {
            //     set g_TermHasChar to False.
            // }
            return g_TermHasChar.
        }


        global function UpdateTermScalar
        {
            parameter _scalar,
                      _intList is list(1, 5, 15, 30).
        
            local scalarVal to _scalar.

            OutInfo("-{0,-2}|-{1,-2}|-{2,-2}|-{3,-2}|-0+|+{3,-2}|+{2,-2}|+{1,-2}|+{0,-2}":Format(_intList[3], _intList[2], _intList[1], _intList[0])).
            OutInfo(" {0} | {1} | {2} | {3} | {4} | {5} | {6} | {7} | {8} ":Format(Char(8606), Char(8609), Char(8592), Char(8595), "0", Char(8593), Char(8594), Char(8607), Char(8608)), 1).

            local maxValFlag to False.
            local maxValIndicator to "".
            
            local keyMapActiveStr to " {0} | {1} | {2} | {3} | {4} | {5} | {6} | {7} | {8} ".

            if g_TermChar = Terminal:Input:DownCursorOne
            {
                set scalarVal to scalarVal - 1.
                set keyMapActiveStr to " {0} | {1} | {2} |[{3}]| {4} | {5} | {6} | {7} | {8} ".
            }
            else if g_TermChar = Terminal:Input:UpCursorOne
            {
                set scalarVal to scalarVal + 1.
                set keyMapActiveStr to " {0} | {1} | {2} | {3} | {4} |[{5}]| {6} | {7} | {8} ".
            }
            else if g_TermChar = Terminal:Input:LeftCursorOne
            {
                set scalarVal to scalarVal - 5.
                set keyMapActiveStr to " {0} | {1} |[{2}]| {3} | {4} | {5} | {6} | {7} | {8} ".
            }
            else if g_TermChar = Terminal:Input:RightCursorOne
            {
                set scalarVal to scalarVal + 5.
                set keyMapActiveStr to " {0} | {1} | {2} | {3} | {4} | {5} |[{6}]| {7} | {8} ".
            }
            else if g_TermChar = "("
            {
                set scalarVal to scalarVal - 15.
                set keyMapActiveStr to " {0} |[{1}]| {2} | {3} | {4} | {5} | {6} | {7} | {8} ".
            }
            else if g_TermChar = ")"
            {
                set scalarVal to scalarVal + 15.
                set keyMapActiveStr to " {0} | {1} | {2} | {3} | {4} | {5} | {6} |[{7}]| {8} ".
            }
            else if g_TermChar = "{"
            {
                set scalarVal to scalarVal - 30.
                set keyMapActiveStr to "[{0}]| {1} | {2} | {3} | {4} | {5} | {6} | {7} | {8} ".
            }
            else if g_TermChar = "}"
            {
                set scalarVal to scalarVal + 30.
                set keyMapActiveStr to " {0} | {1} | {2} | {3} | {4} | {5} | {6} | {7} |[{8}]".
            }
            else if g_TermChar = "0"
            {
                set scalarVal to 0.
                set keyMapActiveStr to " {0} | {1} | {2} | {3} |[{4}]| {5} | {6} | {7} | {8} ".
            }
            set g_TermChar to "".
            set maxValIndicator to choose "*" if maxValFlag else "".

            OutInfo(keyMapActiveStr:Format(Char(8606), Char(8609), Char(8592), Char(8595), "0", Char(8593), Char(8594), Char(8607), Char(8608)), 1).

            return scalarVal.
        }

    // #endregion

    // *- Part Module Utilities
    // #region
        // DoAction :: (_m)<Module>, (_action)<string>, [(_state)<bool>] -> (ResultCode)<scalar>
        // Given a part module and name of an action, performs if if present on the module.
        global function DoAction
        {
            parameter _m,
                      _action,
                      _state is true.

            set g_ResultCode to 0.

            if _m:HasAction(_action)
            {
                _m:DoAction(_action, _state).
                set g_ResultCode to 1.
            }
            else
            {
                set g_ResultCode to 2.
            }

            return g_ResultCode.
        }

        // DoAction :: (_m)<Module>, (_action)<string>, [(_state)<bool>] -> (ResultCode)<scalar>
        // Given a part module and name of an action, performs if if present on the module.
        global function DoEvent
        {
            parameter _m,
                      _event.

            set g_ResultCode to 0.

            if _m:HasEvent(_event)
            {
                _m:DoEvent(_event).
                set g_ResultCode to 1.
            }
            else
            {
                set g_ResultCode to 2.
            }

            return g_ResultCode.
        }

        // GetFormattedAction :: _m<PartModule>, _actionStr<String> -> <String>
        // Returns a properly formatted action name if present on the provided module.
        // If no action found, returns an empty string.
        global function GetFormattedAction
        {
            parameter _m,
                      _actionStr.

            for act in _m:AllActions
            {
                if act:Contains(_actionStr)
                {
                    return act:Replace("(callable) _, ",""):Replace(" is KSPAction","").
                }
            }
            return "".
        }

        // GetFormattedEvent :: _m<PartModule>, _eventStr<String> -> <String>
        // Returns a properly formatted event name if present on the provided module.
        // If no event found, returns an empty string.
        global function GetFormattedEvent
        {
            parameter _m,
                      _eventStr.

            for ev in _m:AllEvents
            {
                if ev:Contains(_eventStr)
                {
                    return ev:Replace("(callable) _, ",""):Replace(" is KSPEvent","").
                }
            }
            return "".
        }

        // GetField :: (_m)<Module>, (_field)<string> -> (fieldValue)<any>
        // Given a module and name of a field, retrieve it if present
        global function GetField
        {
            parameter _m,
                      _field.

            set g_ResultCode to 0.

            if _m:HasField(_field)
            {
                set g_ResultCode to 1.
                return _m:GetField(_field).
            }
            else
            {
                set g_ResultCode to 2.
                return "NUL".
            }
        }

        // SetField :: (_m)<Module>, (_field)<string>, (_value)<any> -> (ResultCode)<scalar>
        // Given a module and name of a field, set it to the provided value if the field is present on the module
        // Result codes:
        // -- 0: Nothing
        // -- 1: Success
        // -- 2: Warning (Field missing from module)
        // -- 3: Error (Field set action was unsuccessful)
        global function SetField
        {
            parameter _m,
                      _field,
                      _value.

            set g_ResultCode to 0.

            if _m:HasField(_field)
            {
                _m:SetField(_field, _value).
                if _m:GetField(_field) = _value
                {
                    set g_ResultCode to 1.
                }
                else
                {
                    set g_ResultCode to 3.
                }
            }
            else
            {
                set g_ResultCode to 2.
            }

            return _field.
        }
    // #endregion

    // *- Mission Tag Decoder Utilities
    // #region

    // ParseCoreTag :: (_tag)<String> -> (parsedTagObject)<Lexicon>
    // Parses a core tag, including launch params and stop stage
    // Format: (missionName)<string>|param1;param2;param3;param4|(stageStop)<scalar>
    global function ParseCoreTag
    {
        parameter _tag is core:tag.

        local newStopStage      to 0.
        local parsedMission     to "".
        local parsedParams      to list().
        local parsedStageStop   to 0.
        local parsedTag         to list(_tag).
        local prmResult         to "".
        local prmSplit          to list().
        local prmSet            to list().
        local stageExitGate     to "".
        local tempStageStop     to "".
        local tempStopSplit     to list().

        local parsedTagObject   to lexicon(
            "MISSION", _tag:Split("|")[0]
            ,"PARAMS", list()
            ,"STGSTOP", 0
            ,"STAGESTOP", 0
            ,"STGSTOPSET", list()
        ).

        if _tag:Contains("|")
        {
            set parsedTag       to _tag:Split("|").
            set tempStageStop to parsedTag[parsedTag:Length - 1].
            if tempStageStop:Contains(";")
            {
                // local stopIdx to 0.
                set tempStopSplit to tempStageStop:Split(";").

                for stageID in tempStopSplit
                {
                    parsedTagObject:StgStopSet:Add(stageID).
                }
                set parsedStageStop to parsedTagObject:StgStopSet[0]:ToNumber(-1).
                // from { local i to 0.} until i = tempStopSplit:Length step { set i to i + 1.} do
                // {
                //     local s to tempStopSplit[i].
                //     if s:Contains(":")
                //     {
                //         local splitStopPair to s:Split(":").
                //         set newStopStage     to splitStopPair[0]:ToNumber(-1).
                //         set stageExitGate to splitStopPair[1].
                //     }
                //     else
                //     {
                //         set newStopStage to s:ToNumber(-1).
                //         set stageExitGate    to "NE".
                //     }

                //     local gateDelegate to GetTimestampDelegate(stageExitGate).
                    
                //     if i = 0 set parsedStageStop to newStopStage.
                //     set parsedTagObject["STGSTOPSET"][stopIdx] to lexicon(
                //         "C",  gateDelegate
                //         ,"S", newStopStage
                //     ).
                //     set stopIdx to stopIdx + 1.
                // }
            }
            else
            {
                set parsedStageStop to tempStageStop:ToNumber(-1).
            }

            set parsedTagObject["MISSION"] to parsedTag[0].

            if parsedStageStop <> -1
            {
                set parsedTagObject["STGSTOP"] to parsedStageStop.
                set g_StageLimit to parsedStageStop.
                set g_StageLimitSet to parsedTagObject:StgStopSet.
            }
            else
            {
                set parsedTagObject["STGSTOP"] to 0.
                set g_StageLimit to parsedStageStop.
                set g_StageLimitSet to list(g_StageLimit).
            }

            if parsedTag:Length > 2 // Params
            {
                set prmSplit to parsedTag[1]:Split(";"). 
                if prmSplit:Length > 0
                {
                    // if prmSplit:Length = 1 
                    // { 
                    //     set prmSplit to parsedTag[1]:Split(","). 
                    // }
                
                    set prmSet to list().
                    from { local i to 0.} until i >= prmSplit:Length step { set i to i + 1.} do
                    {
                        local prm to prmSplit[i].
                        prmSet:Add(ParseStringScalar(prm)).
                    }
                }
            }
            else
            {
            }

            set parsedTagObject["PARAMS"] to prmSet.
            set g_MissionTag:Params to prmSet.
        }

        return parsedTagObject.
    }

    global function SetNextStageLimit
    {
        parameter _setStage is -1.
        
        local cTag to core:tag.
        local lastStgLim to g_StageLimit.
        if _setStage < 0
        {
            if g_StageLimitSet:Length > 1
            {
                set cTag to cTag:replace("|{0};":Format(g_StageLimit:ToString), "|").
                local tagSplit to cTag:Split("|").
                set g_StageLimit to tagSplit[tagSplit:Length - 1]:Split(";")[0]:ToNumber(Stage:Number).
                set g_MissionTag:STGSTP to g_StageLimit.
                g_StageLimitSet:Remove(0).
            }
            else
            {
                set g_StageLimit to 0.
                set cTag to cTag:Replace(cTag:Substring(cTag:FindLast("|") + 1, cTag:Length - cTag:FindLast("|") - 1), g_StageLimit:ToString).
                g_StageLimitSet:Clear().
                g_StageLimitSet:Add(g_StageLimit).
                set g_MissionTag:STGSTP to g_StageLimit.
            }
        }
        else
        {
            set g_StageLimit to _setStage.
            set cTag to cTag:Replace(cTag:Substring(cTag:FindLast("|") + 1, cTag:Length - cTag:FindLast("|") - 1), g_StageLimit:ToString).
            g_StageLimitSet:Clear().
            g_StageLimitSet:Add(g_StageLimit).
            set g_MissionTag:STGSTP to g_StageLimit.
        }

        if g_StageLimit <> lastStgLim
        {
            set core:tag to cTag.
            if g_Debug { OutDebug("g_StageLimit updated to {0}":Format(g_StageLimit)).}
        }
        return cTag.
    }


    global function ParseStringScalar
    {
        parameter _inputString.

        local scalar_result to -1.
        

        if _inputString:IsType("Scalar") // if it's already a scalar, well...
        {
            set scalar_result to _inputString.
        }
        else
        {
            if _inputString:MatchesPattern("\d*(km$|mm$)")
            {
                if _inputString:MatchesPattern("(^\d*(km$))")
                {
                    set scalar_result to _inputString:Replace("km", ""):ToNumber() * 1000.
                }
                else if _inputString:MatchesPattern("(^\d*(mm$))")
                {
                    set scalar_result to _inputString:Replace("mm", ""):ToNumber() * 1000000.
                }
            }
            else if _inputString:MatchesPattern("(^\d*)[dhmsDHMS]+")
            {
                set scalar_result to 0.
                local strSet to list(_inputString).
                
                for key in l_timeTable:Keys
                {
                    if strSet[0]:MatchesPattern("(^\d*{0}})":Format(key))
                    {
                        set strSet to _inputString[0]:Split(key).
                        set scalar_result to scalar_result + strSet[0]:ToNumber * l_timeTable[key].
                        strSet:Remove(0).
                    }
                }
            }
            else if _inputString:MatchesPattern("(^\d*$)")
            {
                OutInfo("Parsing [{0}] at 1:1":Format(_inputString)).
                set scalar_result to _inputString:ToNumber().
                wait 0.1.
            }
            else
            {
                set scalar_result to _inputString:ToNumber(-1).
            }
        }
        return scalar_result.
    }


    global function GetTimestampDelegate
    {
        parameter _eventStr.

        local resultDel to { return true.}.

        if _eventStr = "NE"
        {
            return resultDel@.
        }
        else if _eventStr:Contains(":")
        {
            local eventSplit to _eventStr:Split(":").
            local eventTimeStamp to GetEventTimeStamp(eventSplit[0]).
            local scalarEventTrig to eventSplit[1]:ToNumber(0).
            local resultTS to eventTimeStamp + scalarEventTrig.
            set g_TS to resultTS.
            set resultDel to { return Time:Seconds >= resultTS. }.
        }

        return resultDel@.
    }

    local function GetEventTimeStamp
    {
        parameter _eventStr.

        if _eventStr:MatchesPattern("(AP)+(O)?")
        {
            return Time:Seconds + ETA:Apoapsis.
        }
        else if _eventStr:MatchesPattern("(PE)+(R)?")
        {
            return Time:Seconds + ETA:Periapsis.
        }
    }
    // #endregion

    // *- Event Loop Execution and Parsing
    // #region
    
    // ExecLoopEventDelegates :: <none> -> <none>
    // If there are events registered in g_LoopDelegates, this executes them
    global function ExecGLoopEvents
    {
        local EventSet to g_LoopDelegates["Events"].
        local repeatEvent to false.
        
        for ev in EventSet:Keys
        {
            if GetLoopEventResult(EventSet[ev])
            {
                // result indicates whether to preserve
                set repeatEvent to DoLoopEventAction(EventSet[ev]).
                if not repeatEvent 
                {
                    UnregisterLoopEvent(EventSet[ev]:ID).
                }
            }
        }
    }
    // #endregion

    // *- Event registration and creation
    // #region
    global function CreateLoopEvent
    {
        parameter _id,
                  _type,
                  _params is list(),
                  _check is { return true.},
                  _action is { return false.}.


        OutInfo("CreateLoopEvent: Creating new event ({0})":Format(_id)).

        local newEvent to lexicon(
            "id",           _id
            ,"type",        _type
            ,"delegates",   lexicon(
                "check",    _check@
                ,"action",  _action@
            )
            ,"params",      _params
            ,"repeat",      false
        ).

        return newEvent.
    }

    global function DoLoopEventAction
    {
        parameter _eventData.

        local repeatFlag to true.

        if _eventData:HasKey("Delegates")                  
        {
            if _eventData:Delegates:HasKey("Action")
            {
                return _eventData:Delegates:Action:Call(_eventData:Params).
            }
        }
        return repeatFlag.
    }

    global function GetLoopEventResult
    {
        parameter _eventData.

        local loopResult to false.

        if _eventData:HasKey("Delegates")                  
        {
            if _eventData:Delegates:HasKey("Check")
            {
                return _eventData:Delegates:Check:Call(_eventData:Params).
            }
        }
        return loopResult.
    }

    // Register an event created in CreateEvent
    global function RegisterLoopEvent
    {
        parameter _eventData,
                  _idOverride is "*NA*".

        local localID to choose _eventData:id if _idOverride = "*NA*" else _idOverride.

        OutInfo("RegisterLoopEvent: Adding event ({0})":Format(localID)).

        if not g_LoopDelegates:HasKey("Events")
        {
            set g_LoopDelegates["Events"] to lexicon().
        }

        local doneFlag to false.
        from { local i to 0.} until doneFlag = true or i > g_LoopDelegates:Events:Keys:Length step { set i to i + 1.} do
        {
            // local namePair to "{0}_{1}":Format(localID, i:ToString()).
            if not g_LoopDelegates:Events:HasKey(localID)
            {
                g_LoopDelegates:Events:Add(localID, _eventData).
                set doneFlag to true.
            }
        }
        return doneFlag.
    }


    global function UnregisterLoopEvent
    {
        parameter _eventID.

        OutInfo("UnregisterLoopEvent: Removing event ({0})":Format(_eventID)).

        if g_LoopDelegates:Events:Keys:Contains(_eventID)
        {
            g_LoopDelegates:Events:Remove(_eventID).
        }
        return g_LoopDelegates:Events:Keys:Contains(_eventID).
    }
    // #endregion

    // Sound
    // #region

    // PlaySFX :: <int> -> <none>
    // Plays a sound effect based chosen by param idx
    global function PlaySFX
    {
        parameter sfxId is 0.

        local sfxData to readJson(l_sfxReference[Min(sfxId, l_sfxReference:Length - 1)]).
        local v0 to getVoice(9).
        from { local idx to 0.} until idx = sfxData:length step { set idx to idx + 1.} do
        {
            v0:play(sfxData[idx]).
            wait 0.13.
        }
    }
    // #endregion

    // Addon Wrappers
    // #region

    // Career
    // #region
    // TryRecoverVessel :: [_ves<Ship>], [_recoveryWindow<Scalar>] -> <None>
    global function TryRecoverVessel
    {
        parameter _ves is Ship,
                  _recoveryWindow is 30.

        if Addons:Available("Career")
        {
            local waitTimer to 5.
            set g_TS to Time:Seconds + waitTimer.
            local waitStr to "Waiting until {0,-5}s to begin recovery attempts".
            set g_TermChar to "".
            OutInfo("Press any key to abort").
            local abortFlag to false.
            until Time:Seconds > g_TS or abortFlag
            {
                OutMsg(waitStr:Format(Round(g_TS - Time:Seconds, 2))).
                GetTermChar().
                if g_TermChar <> ""
                {
                    set abortFlag to true.
                    OutInfo().
                }
                wait 0.01.
            }

            if abortFlag 
            {
                OutMsg("Aborting recovery attempts!").
                wait 0.25.
            }
            else
            {
                local getRecoveryState to { parameter __ves is Ship. if Addons:Career:IsRecoverable(__ves) { return list(True, "++REC").} else { return list(False, "UNREC").}}.
                local recoveryStr to "Attempting recovery (Status: {0})".
                set g_TS to Time:Seconds + _recoveryWindow.
                local abortStr to "Press any key to abort ({0,-5}s)".
                until Time:Seconds >= g_TS or abortFlag
                {
                    local recoveryState to getRecoveryState:Call(_ves).
                    if recoveryState[0]
                    {
                        Addons:Career:RecoverVessel(_ves).
                        OutMsg("Recovery in progress (Status: {0})":Format(recoveryState[1])).
                        OutInfo().
                        wait 0.01.
                        break.
                    }
                    else
                    {
                        OutMsg(recoveryStr:Format(recoveryState[1])).
                        OutInfo(abortStr:Format(g_TS - Time:Seconds, 2)).

                        GetTermChar().
                        if g_TermChar <> ""
                        {
                            set abortFlag to true.
                        }
                        wait 0.01.
                    }
                }
                
                if abortFlag
                {
                    OutMsg("Recovery aborted!").
                    OutInfo().
                }
                else
                {
                    OutMsg("Recovery failed. :(").
                }
                OutInfo().
            }
        }
        else
        {
            OutMsg("No recovery firmware found!").
            OutInfo().
            wait 0.25.
        }
    }

    // #endregion
    // #endregion
// #endregion