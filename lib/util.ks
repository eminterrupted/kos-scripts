// #include "0:/lib/libLoader.ks"
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

    // *- System / Terminal Utilities
    // #region
    
        // Breakpoint :: [(Time to wait)<scalar>], [(Wait Message)<string>] -> (Continue)<bool>
        // Creates a breakpoint, and will continue on any key press and/or timeout if one is provided
        // By default, timeout is 0 which is indefinite
        global function Breakpoint
        {
            parameter _timeout is -1,
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
                
                print infoStr at (infoCol, infoLine).
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

        // CheckTermChar :: (Char to check)<TerminalInput> -> (Match)<bool>
        // Returns the boolean result of a check of the provided value against g_TermChar. 
        // _updateGlobal will set g_TermChar to the next char in the queue for comparison if available
        // With _updateGlobal flag set, no need to call GetTermChar() first
        global function CheckTermChar
        {
            parameter _char,
                    _updateGlobal is false.

            if _updateGlobal
            {
                if Terminal:Input:HasChar
                {
                    set g_TermChar to Terminal:Input:GetChar.
                    Terminal:Input:Clear().
                }
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
                Terminal:Input:Clear().
                return true.
            }
            else
            {
                return false.
            }
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

        local newStopStage         to 0.
        local parsedMission     to "".
        local parsedParams      to list().
        local parsedStageStop   to 0.
        local parsedTag         to list(_tag).
        local prmResult         to "".
        local prmSplit          to list().
        local prmSet            to list("0", "0").
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

            set parsedTagObject["MISSION"]  to parsedTag[0].

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

            if parsedTag:Length > 2
            {
                set prmSplit to parsedTag[1]:Split(";"). // Params
                
                if prmSplit:Length = 0
                {
                }
                else
                {
                    set prmSet to list().

                    if prmSplit:Length = 1 
                    { 
                        set prmSplit to parsedTag[1]:Split(","). 
                    }
                
                    for prm in prmSplit
                    {
                        prmSet:Add(ParseStringScalar(prm)).
                    }
                }
            }
            else
            {
            }

            set parsedTagObject["PARAMS"]   to prmSet.
            set g_MissionParams to prmSet.
        }

        return parsedTagObject.
    }


    global function SetNextStageLimit
    {
        parameter _tag is core:tag.

        if g_StageLimitSet:Length > 1
        {
            set _tag to _tag:replace("|{0};":Format(g_StageLimit:ToString), "|").
            local tagSplit to _tag:Split("|").
            set g_StageLimit to tagSplit[tagSplit:Length - 1]:Split(";")[0]:ToNumber(Stage:Number).
            set g_MissionTag:STGSTP to g_StageLimit.
            g_StageLimitSet:Remove(0).
        }
        set core:tag to _tag.
        return _tag.
    }


    global function ParseStringScalar
    {
        parameter _inputString.

        local scalar_result to -1.
        if _inputString:MatchesPattern("\d*(m$|k$|km$|mm$)")
        {
            if _inputString:MatchesPattern("(^\d*(k$|km$))")
            {
                set scalar_result to _inputString:Replace("k", ""):Replace("m", ""):ToNumber() * 1000.
            }
            else if _inputString:MatchesPattern("(^\d*(mm$))")
            {
                set scalar_result to _inputString:Replace("mm", ""):ToNumber() * 1000000.
            }
            else if _inputString:MatchesPattern("(^\d*(m$))")
            {
                set scalar_result to _inputString:Replace("m", ""):ToNumber().
            }
        }
        else if _inputString:MatchesPattern("^\d*$")
        {
            set scalar_result to _inputString:ToNumber().
        }
        else
        {
            set scalar_result to _inputString:ToNumber(-1).
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