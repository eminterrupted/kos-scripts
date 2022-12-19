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
        local actFrmt to "{0," + round((Terminal:Width - actStr:Length) / 2) + "}" + actStr + "{0," + round((Terminal:Width - actStr:Length) / 2) + "}".
        print promptStr at (0, Terminal:Height - 3).
        print actFrmt:format(" ") at (0, Terminal:Height - 2).
        Terminal:Input:Clear.
        wait 0.01.
        wait until Terminal:Input:HasChar.
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

        local _scriptFragments to list(_tagFragments[0]). // Disabling the ':' split here for backward compatibility purposes (used : in delimited params previously)
        //local _scriptFragments to _tagFragments[0]:Split(":").   // First-token string after the pipe split: "sounder:simple[325km,90]"
                                                                    // Separate the container ("sounder") from the script details ("simple[325km,90]")

        if _scriptFragments:Length > 1                  // If we have more than one fragment, we know we have the PCN in the first token, and the script details in the second
        {
            set _tagLex["PCN"]  to _scriptFragments[0].  // Should be "sounder"
            set _sidFrag        to _scriptFragments[1].        // Should now be "simple[325km,90]"
        }
        else if _scriptFragments:Length > 0
        {
            set _pcnFrag        to _scriptFragments[0]:Replace("]",""):Split("[").
            set _tagLex["PCN"]  to _pcnFrag[0].
            set _sidFrag        to _pcnFrag[1].
        }
        else
        {
            print "NO FREAKING FRAGMENTS YO".
            print 1 / 0.
        }

        // Parse if we have something, else default to the hardcoded 'setup.ks' script under the PCN
        if _sidFrag:MatchesPattern("[\[\]]")
        {
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
            local _sidSplit to choose _sidFrag:Split(",") if _sidFrag:Split(","):Length > 1 else _sidFrag:Split(":").
            for val in _sidSplit
            {
                _prm:Add(val).
            }
        }
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