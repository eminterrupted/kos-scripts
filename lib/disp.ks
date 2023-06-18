// #include "0:/lib/libLoader.ks"
@lazyGlobal off.

// *~ Dependencies ~* //
// Required libraries go here
// #region
    // #include "0:/lib/globals"
    // #include "0:/lib/util"
// #endregion


// *~ Variables ~* //
// Local and global variables used in this library
// #region
    // *- Local
    // #region
    local dispTermWidth to 72.
    local dispTermHeight to 50.
    // #endregion

    // *- Global
    // #region
    local  d_Line to 10.
    global g_Line to 0.
    // #endregion
// #endregion


// *~ Functions ~* //
// #region
  
    // *- Utilities
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

    // OutMsg :: (Message)<string>, [(ErrorLevel)<Scalar>], [(TeeHUD)<bool>] -> (none)
    // Writes a message at line 5. 
    // TODO: If the ErrorLevel is 2 or higher, color codes the string for visibility
    global function OutMsg
    {
        parameter _str is "",
                  _errLvl is 0.
                  //_teeHUD is false. TODO: implement TeeHud function

        local msg_line to 7.
        local msg_str to "".
        if _str:length > 0
        {
            if _errLvl < 1
            {
                // set msgColot 
                set msg_str to "[MSG] {0}":Format(_str).
            }
            else if _errLvl > 1
            {
                set msg_str to "<color=red>[ERR] {0}</color>":Format(_str).
            }
            else
            {
                set msg_str to "<color=yellow>[WRN] {0}</color>":Format(_str).
            }
            // local errLabel to choose "MSG" if _errLvl < 1
            //              else choose "<yellow>WRN" if _errLvl < 2
            //              else        "<red>ERR".

            print msg_str:PadRight(Terminal:Width - 1) at (2, msg_line).
        }
        else
        {
            print _str:PadRight(Terminal:Width - 1) at (1, msg_line).
        }
    }

    // OutInfo :: (Message)<string>, (LineIndex)<scalar> -> (none)
    // Writes a non-critical message at lines 6-8 depending on the line provided. 
    global function OutInfo
    {
        parameter _str is "",
                  _lineIdx is 0.
                  //_teeHUD is false. TODO: implement TeeHud function

        local line to 8.
        if _str:length > 0
        {
            print "[{0}] {1} ":Format("INFO", _str):PadRight(Terminal:Width - 2) at (2, line + _lineIdx).
        }
        else
        {
            print _str:PadRight(Terminal:Width - 2) at (2, line + _lineIdx).
        }
    }

    // #endregion

    // *- Displays
    // #region

    // DispMain :: (_scriptPath)<Path> -> (nextLine)<scalar>
    // Prints the main terminal header, and returns the next available line for printing
    global function DispMain
    {
        parameter _scriptPath is ScriptPath(),
                  _termWidth is dispTermWidth,
                  _termHeight is dispTermHeight.

        set Terminal:Width to _termWidth.
        set Terminal:Height to _termHeight.
        DoEvent(Core, "Open Terminal").

        set g_Line to 0.
        local progName      to "KUSP MISSION CONTROL".
        local progVer       to "v0.01 {0} ({1})":Format(Char(916), "Delta").
        local safeWidth     to Terminal:Width - 2 - progName:Length.
        local str to "{0,20}{1," + safeWidth + "}".
        set str to str:Format(progName, progVer).
        
        print str at (0, g_Line).
        set str to "".
        for i in Range(0, Terminal:Width - 2, 1)
        {
            set str to str + "=".
        }
        print str at (0, cr()).
        print "MISSION: {0}":Format(Ship:Name)                  at (0, cr()).
        print "STATUS : {0}":Format(Ship:Status)                at (0, cr()).
        print "MET    : {0}":Format(TimeSpan(MissionTime):Full) at (0, cr()).
        print "PROGRAM: {0}":Format(_scriptPath)                at (0, cr()).
        cr().
        cr().

        return g_Line.
    }

    // DispLaunchTelemetry :: <none> -> <none>
    // Displays launch telemetry in terminal 
    global function DispLaunchTelemetry
    {
        local dispBlock to list(
            "TELEMETRY"
            ,"---------"
            ,"{0,-10}: {1}  ":Format("ALTITUDE", Round(Ship:Altitude))
            ,"{0,-10}: {1}  ":Format("APOAPSIS", Round(Ship:Apoapsis))
            ,"{0,-10}: {1}  ":Format("PERIAPSIS", Round(Ship:Periapsis))
            ,"{0,-10}":Format("VELOCITY")
            ,"{0, 10}: {1}  ":Format("SURFACE", Round(Ship:Velocity:Surface:Mag, 1))
            ,"{0, 10}: {1}  ":Format("ORBIT", Round(Ship:Velocity:Orbit:Mag, 1))
        ).

        PrintDisp(dispBlock).
    }

    // PrintDisp: (_dispBlock)<List> -> <none>
    // Given a list of things to print, prints them
    global function PrintDisp
    {
        parameter _dispBlock,
                  _line to g_Line.

        for str in _dispBlock
        {
            print str at (2, g_Line).
            cr().
        }
    }

    // #endregion
// #endregion