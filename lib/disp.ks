@LazyGlobal off.

// *~ Dependencies ~* //
// #region

// #include "0:/lib/module.ks"

// #endregion

// *~ Variables ~* //
// #region
    // *- Common Values
    // #region
    local __trStartLine to 1.
    local __trLine to __trStartLine.
    local __trHeight to 64.
    local __trWidth  to 80.
    local __trVer to "0.0.1 (pre-alpha tech demo)".

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

    // :: Global
    // #region
    
    // InitTerm :: (input params)<type> -> (output params)<type>
    // Initializes the terminal display
    global function InitTerm
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
            set Terminal:Height to __trHeight.
            set Terminal:Width to __trWidth.
        }
        // Open the terminal on boot
        if _showTerm
        {
            DoEvent(Core, "Open Terminal").
        }
        set __trLine to __trStartLine.

        // Print the Process box 
        // top
        print __hDiv:Call("=") at (0, cr()).

        local panelStrings to list(
            "*~~*** SPACE MISSION EXECUTIVE ***~~*",
            " ",
            "Version        : {0,-28}":Format(__trVer),
            "Registered to  : Kerbin United Space Agency",
            " ",
            "Current Mission: {0}":Format(Ship:Name),
            " "
        ).
        DispBoxOutline(1, panelStrings).

        set panelStrings to list(
            "[ MSG] ",
            " ",
            "[INFO] ",
            " ",
            " ",
            " "
        ).
        DispBoxOutline(1, panelStrings).
        
        // Print the Message & Info Panel
        
        // Print the Status & Warning Panel

        // Determine how many panels are available
    }
    
    // #endregion

    // :: Local
    // #region
    
    // cr :: (_trLine)<int> -> (_trLine)<int>
    // Increments __trLine. Pass an int to override __trLine to a new value
    local function cr
    {
        parameter _trLine is __trLine.

        if _trLine <> __trLine
        {
            set __trLine to _trLine.
        } 
        else
        {
            set __trLine to __trLine + 1.
            // #TODO Need to implement vertical safety here
        }
        return __trLine.
    }

    // getSp :: 
    local function getSp
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
    // #endregion

    // *- DispHelpers

    // DispBoxOutline
    local function DispBoxOutline
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