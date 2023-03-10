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

    // *~ Display Utilities
    // #region

    // cr :: (_inLine)<scalar>, [(_lineIncrement)]<scalar> -> (g_Line)<scalar>
    // Given a line number, sets g_line to the next line number and returns it
    global function cr
    {
        parameter _inLine is g_line,
                  _lineIncrement is 1.

        set g_Line to _inLine + _lineIncrement.
        return g_Line.
    }
    // #endregion

    // *- Message Display Functions
    // #region
    
    // OutMsg :: (Message)<string>, [(ErrorLevel)<Scalar>], [(TeeHUD)<bool>] -> (none)
    // Writes a message at line 5. 
    // TODO: If the ErrorLevel is 2 or higher, color codes the string for visibility
    global function OutMsg
    {
        parameter _str is "",
                  _errLvl is 0.
                  //_teeHUD is false. TODO: implement TeeHud function

        if _str:length > 0
        {
            local errLabel to choose "MSG" if _errLvl < 1
                         else choose "WRN" if _errLvl < 2
                         else        "ERR".
            print "[{0}] {1} ":Format(errLabel, _str) at (2, 5).
        }
        else
        {
            for i in Range(0, Terminal:Width - 1, 1) //
            {
                set _str to _str + " ".
            }
            print _str at (0, 5).
        }
    }

    // OutInfo :: (Message)<string>, (LineIndex)<scalar> -> (none)
    // Writes a non-critical message at lines 6-8 depending on the line provided. 
    global function OutInfo
    {
        parameter _str is "",
                  _lineIdx is 0.
                  //_teeHUD is false. TODO: implement TeeHud function

        local line to 6.
        if _str:length > 0
        {
            print "[{0}] {1} ":Format("INFO", _str) at (2, line + _lineIdx).
        }
        else
        {
            for i in Range(0, Terminal:Width - 1, 1) //
            {
                set _str to _str + " ".
            }
            print _str at (0, line + _lineIdx).
        }
    }

    // *~ Display Components

    // DispMain :: (_scriptPath)<Path> -> (nextLine)<scalar>
    // Prints the main terminal header, and returns the next available line for printing
    global function DispMain
    {
        parameter _scriptPath is ScriptPath().

        set g_Line to 0.
        local progName      to "KASA MISSION CONTROL".
        local progVer       to "v0.01 ALPO".
        local safeWidth     to Terminal:Width - 2 - progName:Length.
        local str to "{0,20}{1," + -(safeWidth) + "}".
        set str to str:Format(progName, progVer).
        
        print str at (0, g_Line).
        set str to "".
        for i in Range(0, Terminal:Width - 2, 1)
        {
            set str to str + "=".
        }
        print str at (0, g_Line).
        print "MISSION: {1}":Format(Ship:Name)                  at (0, cr()).
        print "STATUS : {1}":Format(Ship:Status)                at (0, cr()).
        print "MET    : {1}":Format(TimeSpan(MissionTime):Full) at (0, cr()).
        print "PROGRAM: {1}":Format(_scriptPath)                at (0, cr()).
        cr().
        return g_Line.
    }

    // #endregion
// #endregion