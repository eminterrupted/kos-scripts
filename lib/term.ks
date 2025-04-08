@LazyGlobal off.

// *~ Dependencies ~* //
// #region

// #include "0:/lib/module.ks"

// #endregion

// *~ Variables ~* //
// #region
    // *- Common Values
    // #region
    local __trmStartLine to 1.
    local __trmLine to __trmStartLine.
    local __trmHeight to 64.
    local __trmWidth  to 80.
    local __trmMsgWidth  to __trmWidth - 13.
    local __trmDebugLine to __trmHeight - 9.

    local __trmVer to "0.0.1 (pre-alpha tech demo)".

    local __trmMsgLine to __trmStartLine.
    local __trmInfoLine to __trmMsgLine + 2.

    // #endregion

    // *- Delegates
    // #region

    // Print the Process box
    local __hDiv to { 
        parameter _divStyle is "-", 
                  _divWidth is Terminal:Width. 
                    
        local _str to "". 
        for i in range(0, _divWidth, 1) 
        { 
            set _str to _str + _divStyle.
        } 
        return _str. 
    }.

    // #endregion
// #endregion

// *** Library Setup Code *** //
// This should rarely be used! //
// #region

// #endregion

// *~ Functions ~* //
// #region

    // *- Main Display Initialization
    // #region

    // init_term :: (input params)<type> -> (output params)<type>
    // Initializes the terminal display
    global function init_term
    {
        parameter _resetTerm to true,
                  _resetTermSize to false,
                  _showTerm to false.

        // ClearScreen
        if _resetTerm
        {
            clearScreen.
        }
        // Set the terminal to the default size
        if _resetTermSize
        {
            set Terminal:Height to __trmHeight.
            set Terminal:Width to __trmWidth.
        }
        // Open the terminal on boot
        if _showTerm
        {
            do_event(Core, "Open Terminal").
        }
        set __trmLine to __trmStartLine.

        // Print the Process box 
        // top
        print __hDiv:Call("=") at (0, cr()).

        local panelStrings to list(
            "*~~*** SPACE MISSION EXECUTIVE ***~~*",
            " ",
            "Version        : {0,-28}":Format(__trmVer),
            "Registered to  : Kerbin United Space Agency",
            " ",
            "Current Mission: {0}":Format(Ship:Name),
            " "
        ).
        disp_box(1, panelStrings).

        set __trmMsgLine  to __trmLine + 3.
        set __trmInfoLine to __trmLine + 6.

        set panelStrings to list(
            " ",
            "[ MSG] ",
            " ",
            " ",
            "[INFO] ",
            " ",
            " ",
            " ",
            " "
        ).
        disp_box(1, panelStrings).
        
        // Print the Message & Info Panel
        
        // Print the Status & Warning Panel

        // Determine how many panels are available
    }
    // #endregion

    // *- Input helpers
    // #region

    // get_term_char
    // returns the next char in the terminal input queue if present, else ""
    global function get_term_char
    {
        local tchar to "".
        if terminal:Input:HasChar
        {
            set tchar to terminal:Input:GetChar.
        }
        return tChar.
    }
    // #endregion

    // *- Output Section (MSG and INFO)
    // #region

    // out_debug
    //
    global function out_debug
    {
        parameter _str,
                  _lineOffset is 0.

        local line to  __trmDebugLine + _lineOffset.
        print ("[DGB]: {0,-" + (__trmWidth - 9) + "}"):Format(_str) at (0, line).
        return line.
    }

    // out_msg
    //
    global function out_info
    {
        parameter _str is "",
                  _pos is 0.

        local infoLine to  __trmInfoLine + Min(2, _pos).
        if _str:length = 0
        {
            print ("{0,-" + __trmMsgWidth + "}"):Format(" ") at (12, infoLine).
        }
        else
        {
            print ("{0,-" + __trmMsgWidth + "}"):Format(_str) at (12, infoLine).
        }
    }

    // out_msg
    //
    global function out_msg
    {
        parameter _str is "",
                  _pos is 0.

        local msgLine to  __trmMsgLine + Min(1, _pos).

        if _str:length = 0
        {
            print ("{0,-" + __trmMsgWidth + "}"):Format(" ") at (12, msgLine).
        }
        else
        {
            print ("{0,-" + __trmMsgWidth + "}"):Format(_str) at (12, msgLine).
        }
    }
    // #endregion

    // *- Utilities
    // #region

    // breakpoint 
    // It's a breakpoint
    global function breakpoint
    {
        parameter _str is " *** Press any key to continue *** ".

        Terminal:Input:Clear.
        print ("{0,-" + (__trmMsgWidth):ToString + "}"):Format(_str:ToUpper) at (0, Terminal:Height - 3).
        wait until Terminal:Input:HasChar().
        return true.
    }

    // cr :: (_trLine)<int> -> (_trLine)<int>
    // Increments __trmLine. Pass an int to override __trmLine to a new value
    global function cr
    {
        parameter _trLine is __trmLine.

        if _trLine <> __trmLine
        {
            set __trmLine to _trLine.
        } 
        else
        {
            set __trmLine to __trmLine + 1.
            // #TODO Need to implement vertical safety here
        }
        return __trmLine.
    }

    // getSp :: 
    global function get_spacing
    {
        parameter _charSets to list(),
                 _availWidth to Terminal:Width.

        local avgCharCount to 0.
        local totCharCount to 0.
        local numCharSets to _charSets:Length.

        for chSet in _charSets
        {
            if not chSet:IsType("String")
            {
                if chSet:HasSuffix("ToString")
                {
                    set chSet to chSet:ToString().
                }
            }
            set avgCharCount to avgCharCount + chSet:Length.
        }
        set totCharCount to avgCharCount.
        set avgCharCount to choose 0 if (numCharSets = 0 or avgCharCount = 0) else avgCharCount / numCharSets.

        local remainingWidth to _availWidth - totCharCount.
        local panelWidth to Floor(remainingWidth / numCharSets).
        
        return panelWidth.
        
    }
    // #endregion

    // *- DispHandlers
    // #region

    // DispBoxOutline
    local function disp_box
    {
        parameter _numCols is 1,
                  _strDat is list().

        // sides
        local maxWidth to Terminal:Width - 4.
        local colWidth to (maxWidth / _numCols).

        local str to "~0,-2+".
        for i in Range(0, _numCols, 1)
        {
            set str to str + "~1,-{0}+":Format(colWidth).
        }
        set str to str + "~0,2+".
        set str to str:Replace("~","{"):Replace("+","}").

        for i in Range(0, (_strDat:Length + 1), 1)
        {
            if i > 0 and i < (_strDat:Length + 1)
            {
                print str:Format("|", _strDat[i - 1]) at (0, cr()).
            }
            else
            {
                print str:Format("|", " ") at (0, cr()).
            }
        }
        // Print the box bottom
        local div to __hDiv:Call("-", maxWidth + 2).
        print str:Replace("2","1"):Format("|", div, "|") at (0, cr()).
    }
    // #endregion

// #endregion