@lazyGlobal off.

// *~ Dependencies ~* //
// #region

// #include "0:/lib/module.ks"
// #include "0:/env/types/base_types.ks"
// #include "0:/env/types/string_types.ks"
runOncePath("0:/env/types/term_types.ks").

// #endregion

// *~ Variables ~* //
// #region
    // *- Common Local Variables
    // #region
    local __termStartLine to 0.
    local __termLine to __termStartLine.
    local __termHeight to 64.
    local __termWidth  to 80.
    local __termMsgWidth  to __termWidth - 13.
    local __termDebugLine to __termHeight - 9.
    local __termVer to "0.0.1 (pre-alpha tech demo)".
    local __termMsgLine to __termStartLine.
    local __termInfoLine to __termMsgLine + 2.
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
            set Terminal:Height to __termHeight.
            set Terminal:Width to __termWidth.
        }
        // Open the terminal on boot
        if _showTerm
        {
            do_event(Core, "Open Terminal").
        }
        set __termLine to __termStartLine.

        // Print the Process box
        // disp_box_multicol().
        draw_box_data().

        // top
        print __hDiv:Call("=") at (0, cr()).

        local panelStrings to list(
            "*~~*** SPACE MISSION EXECUTIVE ***~~*",
            " ",
            "Version        : {0,-28}":Format(__termVer),
            "Registered to  : Kerbin United Space Agency",
            " ",
            "Current Mission: {0}":Format(Ship:Name),
            " "
        ).
        disp_box_multicol(1, panelStrings).

        set __termMsgLine  to __termLine + 3.
        set __termInfoLine to __termLine + 6.

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
        disp_box_multicol(1, panelStrings).

        // Print the Message & Info Panel

        // Print the Status & Warning Panel

        // Determine how many panels are available

        // return current term positions

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

        local line to  __termDebugLine + _lineOffset.
        print ("[DGB]: {0,-" + (__termWidth - 9) + "}"):Format(_str) at (0, line).
        return line.
    }

    // out_msg
    //
    global function out_info
    {
        parameter _str is "",
                  _pos is 0.

        local infoLine to  __termInfoLine + Min(2, _pos).
        if _str:length = 0
        {
            print ("{0,-" + __termMsgWidth + "}"):Format(" ") at (12, infoLine).
        }
        else
        {
            print ("{0,-" + __termMsgWidth + "}"):Format(_str) at (12, infoLine).
        }
    }

    // out_msg
    //
    global function out_msg
    {
        parameter _str is "",
                  _pos is 0.

        local msgLine to  __termMsgLine + Min(1, _pos).

        if _str:length = 0
        {
            print ("{0,-" + __termMsgWidth + "}"):Format(" ") at (12, msgLine).
        }
        else
        {
            print ("{0,-" + __termMsgWidth + "}"):Format(_str) at (12, msgLine).
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
        print ("{0,-" + (__termMsgWidth):ToString + "}"):Format(_str:ToUpper) at (0, Terminal:Height - 3).
        wait until Terminal:Input:HasChar().
        return true.
    }

    // cr :: (_trLine)<int> -> (_trLine)<int>
    // Increments __termLine. Pass an int to override __termLine to a new value
    global function cr
    {
        parameter _trLine is __termLine.

        if _trLine <> __termLine
        {
            set __termLine to _trLine.
        }
        else
        {
            set __termLine to __termLine + 1.
            // #TODO Need to implement vertical safety here
        }
        return __termLine.
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

    
    // Methods

    // #region
    local hdgStyle to lexicon(
        "bdr", list("Double", list("0F", "F0", "0F", "F0")),
        "cor", list("Double", list("CC", "C3", "3C", "33")),
        "div", list("Double", list("3F", "CF", "FC", "F3", "FF")),
        "spc", list()
    ).

    local hdgBox to lex(
        "pos", list(0, 0),
        "size", list(__termWidth - 3, 16),
        "style", hdgStyle
    ).

    local uxDesignFiles to list().


    // Loads string data from one or more design csv files into a frame buffer object, and returns that object
    local function build_frame_ux {

        parameter _inputFileList is list().

        local frameBuffer to lexicon().
        
        local idx to 0.

        for _file in _inputFileList {
            if Exists(_file) {
                local fileCon to Open(_file):ReadAll.
                from { local _i to 0.} until _i = fileCon:Length step { set _i to _i + 1. set idx to idx + 1.} do {

                }
            }
        }

        return frameBuffer.
    }


    local function build_header
    {
        
    }


    local function build_style
    {
        parameter _styleDat.

        local builtStyle to lexicon().
        
        from { local _i to 0.} until _i = _styleDat:Keys:Length step { set _i to _i + 1.} do
        {
            local key to _styleDat:Keys[_i].
            local dat to _styleDat:Values[_i].

            if dat:Length = 0
            {
            }
            else
            {
                local keyStyle to dat[0].
                local selectedStyle to Styles:Line.
                local selectedCharSet to HexChar:Chars:Line.

                if keyStyle:Contains("/")
                {
                    for _leaf in keyStyle:Split("/")
                    {
                        // set selectedStyle to choose selectedStyle[_leaf] if selectedStyle:HasKey(_leaf) else selectedStyle.
                        set selectedCharSet to choose selectedCharSet[_leaf] if selectedCharSet:HasKey(_leaf) else selectedCharSet.
                    }
                }
                else
                {
                    set selectedCharSet to choose selectedCharSet[keyStyle] if selectedCharSet:HasKey(_leaf) else selectedCharSet.
                }
                set selectedCharSet to selectedCharSet:Hex.

                set builtStyle[key] to list().
                for hex in dat[1]
                {
                    local code to HexToCharCode(hex).
                }

                


                if not builtStyle:HasKey(key)
                {
                    set builtStyle[key] to list().
                }
            }
        }
    }




    // CharCodes.Methods.Add("HexToCharCode").
    // #endregion


    // update_frame_buffer ::
    // Takes term data (example, a box template from __shapes) and
    local function update_frame_buffer
    {

    }

    // draw_box_data
    global function draw_box_data
    {
        parameter _boxData is Shapes:Box:Base:Closed,
                  _style is "Normal".

        if _style:IsType("String")
        {
            set _style to Styles[_style].
        }

        local xPos0 to _boxData:Pos[0].
        local yPos0 to _boxData:Pos[1].
        local xPos1 to _boxData:Pos[2].
        local yPos1 to _boxData:Pos[3].

        local outSpace to list(xPos1 - xPos0, yPos1 - yPos0).

        local padding to _style:pad + 1.
        local inSpace  to list(outSpace[0] - padding - _boxData:Cols:Length, outSpace[1] - padding - _boxData:Rows:Length).

        local divDel to { parameter _ch, _len. local str to "". from { local _i to 0.} until _i = _len step { set _i to _i + 1.} do { set str to str + _ch. } return str. }.
        local innerTopDiv to divDel:Call(_style:bdr[0], outSpace[0] - 2).
        local innerBotDiv to divDel:Call(_style:bdr[2], outSpace[0] - 2).
        local innerMidDiv to divDel:Call(_style:bdr[0], outSpace[0] - 2).
        local innerMidStr to divDel:Call(" ", inSpace[0]).

        local topDiv to _style:cor[0] + innerTopDiv + _style:cor[1].
        local botDiv to _style:cor[2] + innerBotDiv + _style:cor[3].

        local midDiv to  _style:div[2] + innerMidDiv + _style:div[3].
        local midLine to _style:bdr[1] + innerMidStr + _style:bdr[3].
        local midNull to _style:bdr[1] + innerMidStr + _style:bdr[3].

        print topDiv at (xPos0, yPos0).
        from { local __line to yPos0 + 1. } until __line = yPos1 step { set __line to __line + 1.} do
        {
            print midLine at (xPos0, __line).
        }
        print botDiv at (xPos0, yPos1).

        // this returns the inner bounds for the box we just created
        return list(xPos0 + padding, yPos0 + padding, xPos1 - (padding + 1), xPos1 - (padding + 1)).
    }


    // disp_box_multicol
    local function disp_box_multicol
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
