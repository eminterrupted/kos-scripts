// #include "0:/lib/libLoader.ks"
@lazyGlobal off.
// *~ Dependencies ~* //
// Required libraries not loaded by libLoader by default go here
// #region
// #include "0:/lib/globals"

// #endregion


// *~ Variables ~* //
// Local and global variables used in this library
// #region
    // *- Local
    // #region
    // #endregion

    // *- Global
    // #region
    // #endregion
// #endregion


// *~ Library Setup Functions ~* //
// Functions that run on library load to help setup stuff
// #region
SetKOSConfig().
// #endregion


// *~ Functions ~* //
// #region
  
    // *- Config
    // #region
    local function SetKOSConfig
    {
        parameter _ipu is 500
                 ,_ucp is False
                 ,_stat is False
                 ,_clobber is False
                 ,_verbose is True
                 ,_safeMode is True.

        set Config:IPU      to _ipu.
        set Config:UCP      to _ucp.
        set Config:Stat     to _stat.
        set Config:Clobber  to _clobber.
        set Config:Verbose  to _verbose.
        set Config:Safe     to _safeMode.
    }
    // #endregion


    // *- Tag Functions
    // #region

    // ParseCoreTag :: (_tag)<string> -> (_tagList)List<string>
    // Parses a tag for the following: Mission name, Stop Stage
    global function ParseCoreTag
    {
        parameter _tag is Core:Tag.

        local tagSplit to list().

        set tagSplit to _tag:Split("|").
        if tagSplit:Length > 0
        {
            set g_Mission to tagSplit[0].
            if tagSplit:Length > 1 set g_StageLimit to tagSplit[1]:ToNumber(0).
        }

        return list(
            g_Mission
            ,g_StageLimit
        ).
    }
    // #endregion


    // *- System Utilities
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
    // #endregion


    // *- Terminal Utilities
    // #region

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
// #endregion