// #include "0:/lib/libLoader.ks"
@lazyGlobal off.

// *~ Dependencies ~* //
// Required libraries go here
// #region
    // #include "0:/lib/globals"
    // #include "0:/lib/util"
    // #include "0:/lib/engines"
    // #include "0:/lib/launch"
// #endregion


// *~ Variables ~* //
// Local and global variables used in this library
// #region
    // *- Local
    // #region
    local dispTermWidth to 72.
    local dispTermHeight to 50.
    local defLine to 10.
    // #endregion

    // *- Global
    // #region
    global g_DispBuffer to list().
    global g_Line to defLine.
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
            print "[{0}] {1} ":Format("INFO", _str):PadRight(Terminal:Width - 2) at (2, line).
        }
        else
        {
            print _str:PadRight(Terminal:Width - 2) at (2, line).
        }
    }


    // VBlank :: <none> -> <none>
    // Resets g_Line to default
    global function VBlank
    {
        set g_Line to defLine.
        g_DispBuffer:Clear().
        wait 0.01.
    }
    // #endregion

    // *- Displays
    // #region

    // DispMain :: (_scriptPath)<Path> -> (nextLine)<scalar>
    // Prints the main terminal header, and returns the next available line for printing
    global function DispMain
    {
        parameter _scriptPath is g_Context,
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

    // DispEngineTelemetry
    // Displays Engine Telemetry, woo
    global function DispEngineTelemetry
    {
        parameter _inDataObj to GetEnginesPerformanceData(g_ActiveEngines). 
        
        local timeRemaining to choose TimeSpan(_inDataObj:BurnTimeRemaining) if _inDataObj:HasKey("BurnTimeRemaining") else TimeSpan(0).
        local trStr to "{0}m {1}s  ":Format(Floor(timeRemaining:Minutes), Round(Mod(timeRemaining:Seconds, 60), 3)).
        local dispBlock to list(
            "ENGINE TELEMETRY"
            ,"---------------"
            ,"THRUST    : {0}   ":Format(Round(_inDataObj:Thrust, 2))
            ,"AVL THRUST: {0}   ":Format(Round(_inDataObj:ThrustAvailPres, 2))
            ,"THRUST PCT: {0}%  ":Format(Round(_inDataObj:ThrustPct * 100, 2))
            ,"ISP       : {0}s  ":Format(Round(_inDataObj:ISPAt, 2))
            ,"BURN TIME : {0}s  ":Format(trStr)
        ).

        g_DispBuffer:Add(dispBlock).
    }

    // DispLaunchTelemetry :: <none> -> <none>
    // Displays launch telemetry in terminal 
    global function DispLaunchTelemetry
    {
        local dispBlock to list(
            "LAUNCH TELEMETRY"
            ,"----------------"
            ,"{0,-10}: {1}  ":Format("ALTITUDE", Round(Ship:Altitude))
            ,"{0,-10}: {1}  ":Format("APOAPSIS", Round(Ship:Apoapsis))
            ,"{0,-10}: {1}  ":Format("PERIAPSIS", Round(Ship:Periapsis))
            ,"{0,-10}":Format("VELOCITY")
            ,"{0,-8}: {1}  ":Format("SURFACE", Round(Ship:Velocity:Surface:Mag, 1)):PadLeft(2)
            ,"{0,-8}: {1}  ":Format("ORBIT", Round(Ship:Velocity:Orbit:Mag, 1)):PadLeft(2)
        ).

        g_DispBuffer:Add(dispBlock).
    }

    // PrintDisp: (_dispBlock)<List> -> <none>
    // Given a list of things to print, prints them
    global function PrintDisp
    {
        parameter _bufferData is g_DispBuffer,
                  _line to defLine.

        set g_Line to _line.

        for dispBlock in _bufferData
        {
            for str in dispBlock
            {
                print str at (2, cr()).
            }
            cr().
            cr().
        }
        g_DispBuffer:Clear.
        set g_Line to defLine.
    }

    // ResetDisp
    // FunctionName :: (param)<type> [(optionalParam)<type>] -> (output)<type>
    // Function Description
    global function ResetDisp
    {
        ClearScreen.
        DispMain().
    }

    // #endregion
// #endregion