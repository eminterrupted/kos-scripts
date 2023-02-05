// #include "0:/lib/globals.ks"
// #include "0:/lib/loadDep.ks"
@lazyGlobal off.

// *~--- Dependencies ---~* //
// #region
// #endregion


// *~--- Variables ---~* //
// #region
    // *- Local
    global g_EventTriggerActions to lexicon(
         "Decouple",    DoDecouple@
        ,"DC",          DoDecouple@
        ,"Ignite",      DoEngineIgnition@
        ,"IGT",         DoEngineIgnition@
        ,"Activate",    DoPartActivation@
        ,"ACT",         DoPartActivation@
        ,"Stage",       DoSingleStage@
        ,"STG",         DoSingleStage@
    ).

    // *- Global
    global g_OP to lexicon(
         "GE", { parameter _curVal, _tgtVal. return _curVal >= _tgtVal.}
        ,"GT", { parameter _curVal, _tgtVal. return _curVal >  _tgtVal.}
        ,"EQ", { parameter _curVal, _tgtVal. return _curVal =  _tgtVal.}
        ,"LT", { parameter _curVal, _tgtVal. return _curVal <  _tgtVal.}
        ,"LE", { parameter _curVal, _tgtVal. return _curVal <= _tgtVal.}
    ).

    global g_AbortArmed to false.
    global g_AbortFlag to false.

                
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
        local actFrmt to "{0," + round((Terminal:Width - actStr:Length) / 2) + "}" + actStr + "{0," + round((Terminal:Width - actStr:Length) / 2) + "}".
        print promptStr at (0, Terminal:Height - 3).
        print actFrmt:format(" ") at (0, Terminal:Height - 2).
        Terminal:Input:Clear.
        wait 0.01.
        wait until Terminal:Input:HasChar.
    }
// #endregion


// Event Triggers
// #region

    // DoDecoupleEvent :: <Part> -> <Bool>Success
    // Given a part, performs any availble decouple action on it
    local function DoDecouple
    {
        parameter p. 
        
        local m to "".
        if p:HasModule("ModuleDecouple") 
        {
            set m to p:GetModule("ModuleDecouple").
        } 
        else if p:HasModule("ModuleAnchoredDecoupler")
        {
            set m to p:GetModule("ModuleAnchoredDecoupler").
        } 
        
        if m:TypeName = "PartModule" 
        {
            if DoEvent(m, "Decouple") 
            { 
                return true.
            } 
            else if DoAction(m, "Decouple", true) 
            { 
                return true.
            } 
            else if DoEvent(m, "Decoupler Staging")
            {
                return true.
            } 
            else if DoAction(m, "Decoupler Staging", true)
            {
                return true.
            } 
            else
            {
                return false.
            }
        } 
        else
        {
            return false.
        }
    }

    // DoDecoupleEvent :: <Part> -> <Bool>Success
    // Given a part, performs any availble decouple action on it
    local function DoEngineIgnition
    {
        parameter p. 
        
        
        if p:IsType("Engine")
        {
            if not p:Ignition and not p:FlameOut
            {
                local fuelStable to false.

                if p:Ullage or p:PressureFed
                {
                    OutInfo("({0}) Engine ignition fuel stability: {1}":Format(p:Name, p:FuelStability), 1).
                    if p:FuelStability 
                    {
                        set fuelStable to True.
                    }
                    else if p:GetModule("ModuleEnginesRF"):GetField("propellant"):MatchesPattern(".*100\.00 %.*")
                    {
                        set fuelStable to True.
                    }
                }
                else set fuelStable to True.
                
                if fuelStable
                {
                    OutInfo("({0}) Engine ignition start":Format(p:Name), 1).
                    p:Activate.
                    return True.
                }
            }
        }
        return False.
    }

    global function DoPartActivation
    {
        parameter p.
        
        return true.
    }


    // GetETA :: <string>ETAType -> <Scalar>ETA
    // Gets an ETA based on a provided string identifier
    global function GetETA
    {
        parameter _etaType.

        if _etaType = "AP"
        {
            return ETA:Apoapsis.
        }
        else if _etaType = "PE"
        {
            return ETA:Periapsis.
        }
        else if _etaType = "REI"
        {
            if Ship:VerticalSpeed < 0 and Ship:Altitude >= Body:Atm:Height
            {
                //return abs((Ship:Altitude - Body:Atm:Height) / Ship:VerticalSpeed).
                return Sqrt((2 * (Ship:Altitude - Body:Atm:Height)) / GetLocalGravity(Body, Ship:Altitude)).
            }
            else 
            {
                return 999999.
            }
        }
        else if _etaType = "ECO"
        {
            local retVal to choose g_ConsumedResources["TimeRemaining"] if g_ConsumedResources:HasKey("TimeRemaining") else 99999999.
        }
    }

    global function DoSingleStage
    {
        parameter _deadParam to "".

        wait until Stage:Ready.
        Stage.
    }

    // OnEvent :: <Part> -> <Bool>Success?
    // Checks the provided part for an OnEvent tag. If found, parses and initiates a trigger for it if applicable
    global function InitOnEventTrigger
    {
        parameter _partList is ship:PartsTaggedPattern("OnEvent").

        for _part in _partList
        {
            if _part:Tag:Contains("OnEvent")
            {
                local parsedTag to _part:Tag:Split("|").
                if parsedTag:Length > 3
                {
                    if g_EventTriggerActions:HasKey(parsedTag[3])
                    {
                        local actionToPerform to g_EventTriggerActions[parsedTag[3]]:Bind(_part)@.

                        local parsedCondition to parsedTag[2]:Split(".").
                        local checkType to parsedCondition[0].
                        local checkRef to parsedCondition[1].
                        local checkOP to parsedCondition[2].
                        local checkVal to parsedCondition[3]:ToNumber(0).
                        local armStage to choose parsedCondition[4]:ToNumber() if parsedCondition:Length > 4 else _part:stage + 1.
                        
                        when stage:number = armStage then
                        {
                            if checkType = "ETA"
                            {
                                when g_OP[checkOP]:Call(GetETA(checkRef), Abs(checkVal)) then
                                {
                                    if actionToPerform:IsType("String")
                                    {
                                        OutInfo("No action for eventTrigger [{0}|{1}({2})]":Format(_part:name, _part:UID, _part:Tag), 1).
                                    }
                                    else
                                    {
                                        OutInfo("Performing eventTrigger [{0}|{1}({2})]":Format(_part:name, _part:UID, _part:Tag), 1).
                                        actionToPerform:Call().
                                    }
                                }
                            }
                            else if checkType = "TS"
                            {
                                local triggerTS to Time:Seconds + checkVal.
                                when Time:Seconds >= triggerTS then
                                {
                                    if actionToPerform:IsType("String")
                                    {
                                        OutInfo("No action for eventTrigger [{0}|{1}({2})]":Format(_part:name, _part:UID, _part:Tag), 1).
                                    }
                                    else
                                    {
                                        OutInfo("Performing eventTrigger [{0}|{1}({2})]":Format(_part:name, _part:UID, _part:Tag), 1).
                                        actionToPerform:Call().
                                    }
                                }
                            }
                            else if checkType = "ET" // Elapsed time. Example: Decoupler that is staged 3 seconds after engine ignition
                            {
                                set g_ET_Mark to Time:Seconds.
                                local triggerET to checkVal.
                                when Time:Seconds - g_ET_Mark >= triggerET then
                                {
                                    if actionToPerform:IsType("String")
                                    {
                                        OutInfo("No action for eventTrigger [{0}|{1}({2})]":Format(_part:name, _part:UID, _part:Tag), 1).
                                    }
                                    else
                                    {
                                        OutInfo("Performing eventTrigger [{0}|{1}({2})]":Format(_part:name, _part:UID, _part:Tag), 1).
                                        actionToPerform:Call().
                                    }
                                }
                            }
                            else if checkType = "ALT"
                            {
                                when g_OP[checkOP]:Call(Ship:Altitude, checkVal) then
                                {
                                    if actionToPerform:IsType("String")
                                    {
                                        OutInfo("No action for eventTrigger [{0}|{1}({2})]":Format(_part:name, _part:UID, _part:Tag), 1).
                                    }
                                    else
                                    {
                                        OutInfo("Performing eventTrigger [{0}|{1}({2})]":Format(_part:name, _part:UID, _part:Tag), 1).
                                        actionToPerform:Call().
                                    }
                                }
                            }
                            else if checkRef = "RALT"
                            {
                                when g_OP[checkOP]:Call(Ship:Altitude - Ship:GeoPosition:TerrainHeight, checkVal) then
                                { 
                                    if Kuniverse:TimeWarp:IsSettled 
                                    { 
                                        wait 0.075.
                                        if g_OP[checkOP]:Call(Ship:Altitude - Ship:GeoPosition:TerrainHeight, checkVal)
                                        {
                                            if actionToPerform:IsType("String")
                                            {
                                                OutInfo("No action for eventTrigger [{0}|{1}({2})]":Format(_part:name, _part:UID, _part:Tag), 1).
                                            }
                                            else
                                            {
                                                OutInfo("Performing eventTrigger [{0}|{1}({2})]":Format(_part:name, _part:UID, _part:Tag), 1).
                                                actionToPerform:Call().
                                            }
                                        }
                                        else
                                        {
                                            preserve.
                                        }
                                    } 
                                    else 
                                    { 
                                        preserve.
                                    } 
                                }
                            }
                        }
                    }
                    else
                    {
                        OutTee("OnEvent: [{0}] No trigger action defined for [{1}]":Format(_part:name, parsedTag[3]), 1).
                    }
                }
            }
        }
    }
// #endregion


// *- String manipulation
// #region

    // StripColorTags :: <string> -> string>
    // Removes <color> tags from strings, useful for part module fields
    global function StripColorTags
    {
        parameter _str.

        if _str:MatchesPattern("(\<color\=\w*\>).*(\<\/color\>)")
        {
            local oStr to _str.
            local sIdx to _str:Find(">") + 1.
            local eIdx to _str:FindAt("<", sIdx) - 1.
            set oStr to _str:Substring(sIdx, eIdx).
            return oStr.
        }
        else
        {
            return _str.
        }
    }

// #endregion


// *- Module manipulation
// #region
    
    // Events
    global function DoEvent
    {
        parameter _module, 
                  _event.
        
        if _module:HasEvent(_event)
        {
            _module:DoEvent(_event).
            return True.
        }
        else
        {
            return False.
        }
    }

    global function DoAction
    {
        parameter _module, 
                  _action,
                  _flag.
        
        if _module:HasAction(_action)
        {
            _module:DoAction(_action, _flag).
            return True.
        }
        else
        {
            return False.
        }
    }

    global function GetField
    {
        parameter _module,
                  _field,
                  _type is "any". // #TODO - Need to implement type checking helpers
        
        if _module:HasField(_field)
        {
            local oField to _module:GetField(_field).
            if oField:IsType("String")
            {
                set oField to StripColorTags(oField).
            }
            return oField.
        }
        else 
        {
            return False.
        }
    }

    global function SetField
    {
        parameter _module,
                  _field,
                  _newValue.
        
        if _module:HasField(_field)
        {
            _module:SetField(_field, _newValue).
            return true.
        }
        else 
        {
            return False.
        }
    }


// #endregion

// *- Gravity functions
// #region

    // GetLocalGravity :: [<Body>Body, <Scalar>Altitude] -> <Scalar>Local Gravity (m/s)
    global function GetLocalGravity
    {
        parameter _body is Ship:Body,
                  _alt  is Ship:Altitude.

        return constant:g * (_body:radius / (_body:radius + _alt))^2.   
    }

// #endregion

// *- Warp functions
// #region

    // CheckWarpKey :: <none> -> <bool>
    // Checks if the designated warp key (Enter) is pressed.
    global function CheckWarpKey
    {
        if Terminal:Input:HasChar 
        {
            until not Terminal:Input:HasChar
            {
                set g_termChar to Terminal:Input:GetChar.
                if g_termChar = Terminal:Input:Enter
                {
                    return true.
                }
            }
            return false.
        }
        return false.
    }

    // Creates a trigger to warp to a timestamp using AG10
    global function InitWarp
    {
        parameter tStamp, 
                str is "timestamp",
                buffer is 15,
                warpNow to false.

        set tStamp to tStamp - buffer.
        if Time:Seconds <= tStamp
        {
            if warpNow 
            {
                WarpTo(tStamp).
                wait until KUniverse:Timewarp:IsSettled.
            }
            else
            {
                when g_TermChar = Terminal:Input:Enter then
                {
                    WarpTo(tStamp).
                    wait until KUniverse:Timewarp:IsSettled.
                }
                OutHUD("Press Enter in terminal to warp to " + str).
            }
        }
        else
        {
            OutHUD("Warp not available, too close to timestamp", 1).
        }
    }

    // Smooths out a warp down by altitude
    global function WarpToAlt
    {
        parameter tgtAlt.
        
        local warpFactor to 1.

        if tgtAlt > 1000000 set warpFactor to 1.
        else if tgtAlt > 500000 set warpFactor to 1.01.
        else if tgtAlt > 100000 set warpFactor to 1.03.
        else if tgtAlt > 10000 set warpFactor to 1.05.
        else set warpFactor to 1.075.

        if ship:altitude > tgtAlt
        {
            if ship:altitude <= tgtAlt * 1.00003125 * warpFactor set warp to 0.
            else if ship:altitude <= tgtAlt * 1.00125 * warpFactor set warp to 1.
            else if ship:altitude <= tgtAlt * 1.025 * warpFactor set warp to 2.
            else if ship:altitude <= tgtAlt * 1.75 * warpFactor set warp to 3.
            else if ship:altitude <= tgtAlt * 5 * warpFactor set warp to 4.
            else if ship:altitude <= tgtAlt * 25 * warpFactor set warp to 5.
            else if ship:altitude <= tgtAlt * 250 set warp to 6.
            else set warp to 7.
            //else set warp to 6.
        }
        else
        {
            if ship:altitude >= tgtAlt * 0.999996875 * warpFactor set warp to 0.
            else if ship:altitude >= tgtAlt * 0.99875 * warpFactor set warp to 1.
            else if ship:altitude >= tgtAlt * 0.75 * warpFactor set warp to 2.
            else if ship:altitude >= tgtAlt * 0.625 * warpFactor set warp to 3.
            else if ship:altitude >= tgtAlt * 0.500 * warpFactor set warp to 4.
            else if ship:altitude >= tgtAlt * 0.250 * warpFactor set warp to 5.
            else set warp to 6.
            //else if ship:altitude >= tgtAlt * 0.125 set warp to 6.
            //else set warp to 7.
        }
    }
// #endregion

// *- Logging
// #region

    // InitLog :: <none> -> <none>
    // Sets the log file path and writes a header to it
    global function InitLog
    {
        if g_LogPath:IsType("String")
        {
            set g_LogPath to g_LogPath:Format(g_Tag:PCN).
        }
        if exists(g_LogPath)
        {
            log " " to g_LogPath.
            log "*** MISSION LOG REINITIALIZED ***" to g_LogPath.
            log "DateTime: {0} (MET: {1})":Format(TimeSpan(Time:Seconds):Full, TimeSpan(MissionTime):Full) to g_LogPath.
            log "*********************************" to g_LogPath.
            log " " to g_LogPath.
        }
        else
        {
            log "*** MISSION LOG BEGIN ***" to g_LogPath.
            log "Mission : {0}":Format(Ship:Name) to g_LogPath.
            log "DateTime: {0}":Format(TimeSpan(Time:Seconds):Full) to g_LogPath.
            log "*************************" to g_LogPath.
            log " " to g_LogPath.
        }
    }

    //LogStr :: <string>LogString -> <none>
    // Logs a string to a log file for this mission
    global function LogStr
    {
        parameter _str, 
                  _errLvl is 0.

        local label to "INFO".
        if _errLvl > 1
        {
            set label to "*ERR".
        }
        else if _errLvl > 0
        {
            set label to "WARN".
        }
        log "[{0}][{1}]: {2}":Format(label, MissionTime, _str) to g_LogPath.
    }
// #endregion

// *- Terminal Input
// #region

    // GetTermChar :: none -> <terminalCharacter>CurrentTerminalCharacter
    // Returns the current character waiting on the terminal stack, if any
    global function GetTermChar
    {
        if Terminal:Input:hasChar
        {
            set g_TermChar to Terminal:Input:getChar.
        }
        else
        {
            set g_TermChar to "".
        }
        Terminal:Input:Clear.
        return g_TermChar.
    }

    // GetTermInput :: Alias for GetTermChar
    global function GetTermInput
    {
        return GetTermChar().
    }

// #endregion

// *- Tag parsing
// #region

    // ParseCoreTag :: [<string>Tag To Parse] -> <Lexicon>Parsed Tag Fragments
    // Parses a provided string (typically a kOS Core part tag) of a specified format
    // This is designed to work with a specific format to allow for defining mission params in the VAB
    //
    // Tag format: '<scriptFolderName>[<scriptIdentifier>,<scriptParam1>,<scriptParam2>,<etc...>]|<stageNumberForAutoStagingStop>'
    // Example   : 'sounder:simple[325km,90]]|0' will return a lexicon with the following schema:
    // lex( 
    //  "PCN", "sounder",           // PCN: Plan Container Name, the folder under _plan the setup script appears in
    //  "SID", "simple"             // SID: Script Identifier, the name appended to the desired setup script in PCN folder
    //  "PRM", list("325km","90")   // PRM: Parameters to be passed into the script. Each script will process a different number of params, 
    //                                      so this is a list for flexibility
    //  "ASL", 0                    // ASL: Auto-Staging Limiter: Unload the autostaging trigger once we have reached this stage
    //  )
    global function ParseCoreTag
    {
        parameter _tag is Core:Tag.

        local _tagLex       to lexicon( // See above comments for definition of this schema
             "PCN", ""                     
            ,"SID", ""
            ,"PRM", list()
            ,"ASL", 0
        ).

        local _asl              to 0.
        local _prm              to list().
        local _sid              to "".
        local _pcnFrag          to "".
        local _sidFrag          to "".

        local _tagFragments to _tag:Split("|"). // Split the string at the Pipe symbol to separate the script components from the auto-staging limiter component
                                                // If formatted correctly, this results in 2 parts. 
                                                // If we only get one part from this step, the tag is not formatted with a valid stage number defined for the 
                                                // Auto-Staging Limiter. In this case, default to stage 0 (which is the last possible stage for any ship with at least one stage)

        // local _scriptFragments to _tagFragments[0]. // Disabling the ':' split here for backward compatibility purposes (used : in delimited params previously)
        // //local _scriptFragments to _tagFragments[0]:Split(":").   // First-token string after the pipe split: "sounder:simple[325km,90]"
        //                                                             // Separate the container ("sounder") from the script details ("simple[325km,90]")

        if _tagFragments[0]:Contains(":") // If we have more than one fragment, we know we have the PCN in the first token, and the script details in the second
        {
            set _pcnFrag        to _tagFragments[0]:Split(":")[0].  // Should be "sounder"
            set _sidFrag        to _tagFragments[0]:Split(":")[1].  // Should now be "simple[325km,90]"
        }
        else if _tagFragments[0]:MatchesPattern(".*\[.*\].*")
        {
            // OutInfo("TagFragMatch: {0}":Format(_tagFragments[0])).
            // breakpoint().
            local tempTagFrag to _tagFragments[0]:Replace("]",""):Split("[").
            set _pcnFrag  to tempTagFrag[0].
            set _sidFrag  to tempTagFrag[1].
            // OutInfo("_pcnFrag: [{0}] | _sidFrag: [{1}]":Format(tempTagFrag[0], tempTagFrag[1])).
            // Breakpoint().
        }
        else if _tagFragments[0]:Length > 0
        {
            set _pcnFrag to _tagFragments[0].
        }
        else
        {
            print "NO FREAKING FRAGMENTS YO".
            print 1 / 0.
        }

        // Parse if we have something, else default to the hardcoded 'setup.ks' script under the PCN
        if _sidFrag:MatchesPattern("[\[\]]")
        {
            // OutInfo("_sidFrag pattern matched").
            // Breakpoint().
            local _prmFrag to _sidFrag:Replace("]",""):Split("["). // Cleans up the extraneous delimiter in the string prior to splitting at the point the SID ends and the params begin
            set _sid to _prmFrag[0].                     // Value here should be "simple"
            
            if _prmFrag:Length > 1        // More than one fragment means we have parameters to get
            {
                for val in _prmFrag[1]:Split(",")       // Parameters are comma-delimited within the square brackets
                {
                    _prm:Add(val). // This list will be added to _tagLex in the next step
                }
            }
        }
        else
        {
            // OutInfo("_sidFrag pattern not matched").
            // Breakpoint().
            if _sidFrag:Length > 0 
            {
                // OutInfo("_sidFrag length > 0").
                // Breakpoint().
                local _sidSplit to choose _sidFrag:Split(",") if _sidFrag:Split(","):Length > 1 else _sidFrag:Split(":").
            
                for val in _sidSplit
                {
                    // OutInfo("_prm: Adding {0}":Format(val)).
                    _prm:Add(val).
                    // Breakpoint().
                }
            }
        }
        set _tagLex["PCN"] to _pcnFrag.
        set _tagLex["SID"] to _sid. // This can be an empty string, it will just default to "Setup.ks" under the path
        set _tagLex["PRM"] to _prm.     // Add the parameters - either an empty list, or ones found above

        // Now set the ASL - AutoStaging Limiter
        if _tagFragments:Length > 1
        {
            set _asl to _tagFragments[1]:Replace("[",""):Replace("]",""):ToNumber(). // Attempts to convert the string to a scalar, removing any brackets in the process
                                                                                     // If it fails because the string is not able to be cast, then breaks because we shouldn't go without a stage limiter
            set _tagLex["ASL"] to _asl.
        }

        return _tagLex.
    }


    // ExpandToNumber :: <string>Number representation -> <scalar>Output number
    // Given a string that represents a number, will try to parse the string to return a scaled value back with in-line string modifiers applied
    // Examples: 
    //          325km -> 325000m
    //         1250kg -> 1.25t
    //       1.57km/s -> 1570 m/s
    global function ExpandToNumber
    {
        parameter _inString.

        if _inString:MatchesPattern("^[\d\.]*([KMGT]+m$)")  // Distance
        {
            if      _inString:EndsWith("Km") return _inString:Replace("Km",""):ToNumber(-1) * 1000.
            else if _inString:EndsWith("Mm") return _inString:Replace("Mm",""):ToNumber(-1) * 1000000.
            else if _inString:EndsWith("Gm") return _inString:Replace("Gm",""):ToNumber(-1) * 1000000000.
            else if _inString:EndsWith("Tm") return _inString:Replace("Tm",""):ToNumber(-1) * 1000000000000.
        }
        else if _inString:MatchesPattern("^[\d\.]*(Kg?$)")  // Weight
        {
            // No need for additional checks now, but will in future if we add more amounts
            return _inString:Replace("Kg",""):ToNumber(-1) / 1000.
        }
        else if _inString:MatchesPattern("^\d*$")
        {
            return _inString:ToNumber().
        }

        return _inString. // If we didn't match anything, then return value as-is.
    }
// #endregion

// TODO: Work In Progress 'Util' functions
global function SortList
{
    parameter _unsortedList.

    local _maxVal to 0.
    local _minVal to 99.
    local workingCopy to _unsortedList:Copy.
    local resultList to list().

    // This is the order in which list sorting is done. SortList will basically iterate through this list to find the right spot to insert in the result list. Not case sensitive because kOS itself isn't
    local sortDict to list(
        "_"
        ,"0"
        ,"1"
        ,"2"
        ,"3"
        ,"4"
        ,"5"
        ,"6"
        ,"7"
        ,"8"
        ,"9"
        ,"a"
        ,"b"
        ,"c"
        ,"d"
        ,"e"
        ,"f"
        ,"g"
        ,"h"
        ,"i"
        ,"j"
        ,"k"
        ,"l"
        ,"m"
        ,"n"
        ,"o"
        ,"p"
        ,"q"
        ,"r"
        ,"s"
        ,"t"
        ,"u"
        ,"v"
        ,"w"
        ,"x"
        ,"y"
        ,"z"
    ).

    for item in workingCopy
    {
        if item:IsType("String")
        {   
            // Sort based on the first character using the following format:
            // 1) _
            // 2) [0-9]
            // 3) [a-zA-Z]
            // 4) [Eveything else]

            // if there already exists an item with the same first character, use the second character... and so on.
            local sortInt to sortDict:Find(item[0]).
            
            
            if      item[0]:MatchesPattern("^_")        { resultList:Add(item). }
            else if item[0]:MatchesPattern("^[0-9]+")   { resultList:Add(item). }
        }
    }    
}