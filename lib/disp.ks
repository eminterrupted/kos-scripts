// #include "0:/lib/libLoader.ks"
@lazyGlobal off.

// *~ Dependencies ~* //
// #region
// #endregion


// *~ Variables ~* //
// #region
    // *- Global
    // #region
    global g_GridAssignments to lexicon().
    global g_MsgInfoLoopActive to False.
    global g_TermHeight to 64.
    global g_TermWidth  to 72.
    global g_TermSize to g_TermHeight + g_TermWidth.

    // #endregion

    // *- Local
    // #region
    local  l_OutQueue to lexicon(
        "MSG", lexicon(
            "QUEUE", list()
            ,"TIMEOUT", -1
            ,"PARAMS", list()
        ),
        "INFO", lexicon(
            "QUEUE", list()
            ,"TIMEOUT", -1
            ,"PARAMS", list()
        )
    ).
    local  l_OutDefTimeout to 3.
    local  l_GridSpaceIdx to 0.
    local  l_GridSpaceLex to lexicon().
    local  l_LastAssignedBlock to 0.
    local  l_MaxAvailGridIdx to 0.
    local  l_Col0Size to list(68, 4).
    local  l_Col1Size to list(Floor(l_Col0Size[0] / 2), 16).

    local l_InputMappings_D_Idx to 0.
    local l_InputMappings_D_Vals to list(
         { return "l_GridSpaceLex_Keys: [{0}]    ":Format(l_GridSpaceLex:Keys:Join(";")).   }
        ,{ return "l_GridSpaceLex_Vals: [{0}]    ":Format(l_GridSpaceLex:Values:Join(";")). }
        ,{ return "g_GridAssignments_Keys: [{0}] ":Format(g_GridAssignments:Keys:Join(";")).}
    ).
    
    // #endregion

    // *- Local Anonymous Delegates
    local l_GridRowLine to { 
        parameter _width , _char.  

        local str is "". 
        from { local i to 0.} until i = _width or i = Terminal:Width step { set i to i + 1.} do
        {
            set str to str + _char.
        }
        return str. 
    }.

    local l_GridColLine to {
        parameter _colWidth is 16, _char is "|".

        local colIdx to 0.
        local colCount to Floor(Terminal:Width / (_colWidth + 2)).  // Adding 2 to colWidth to account for grid lines
        local str to "|".
        until colIdx = colCount
        {
            from { local i to 1.} until i = _colWidth step { set i to i + 1.} do
            {
                set str to str + " ".
            }
            set colIdx to colIdx + 1.
            set str to str + _char.
        }
        return str.
    }.
    // #endregion

    // *- Global variable modifiers
    // #region
    
    // TODO: Continue building on contextual input mappings idea
    local l_InputMappings to lexicon(
        "D", { OutDebug(l_InputMappings_D_Vals[l_InputMappings_D_Idx]). }
    ).
    g_InputMappings:Context:Add("Disp", l_InputMappings).
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

    // crDbg :: (_lineOffset<scalar>) -> [newOffset]<scalar>
    // Sets or increments the debug offset value
    global function crDbg 
    {
        parameter _lineOffset is g_DbgOffset.

        if _lineOffset <> g_DbgOffset
        {
            set g_DbgOffset to Max(-18, Min(_lineOffset, 15)).
        }
        else if g_DbgOffset >= 15
        {
            set g_DbgOffset to 0.
        }
        else
        {
            set g_DbgOffset to Max(-15, Min(g_DbgOffset + 1, 15)).
        }

        return g_DbgOffset.
    }
    // #endregion

    // *- Message Display Functions
    // #region
    
    global function MsgInfoLoop
    {
        from { local i to 0.} until i = l_OutQueue:Keys:Length step { set i to i + 1.} do
        {
            local outVal to l_OutQueue:Values[i].
            local outType to l_OutQueue:Keys[i].
            local msgParam to outVal:Params[0].

            if outVal:QUEUE:Length > 0
            {
                if Time:Seconds > outVal:TIMEOUT and outVal:Timeout > 0
                {
                    outVal:QUEUE:Remove(0).
                    local outStr to choose outVal:QUEUE[0] if outVal:QUEUE:Length > 0 else "".
                    local msgTimer to choose Time:Seconds + l_OutDefTimeout if outStr:Length > 0 else 0.
                    
                    if outType = "MSG"
                    {
                        OutMsg(outStr, msgParam).
                    }
                    else
                    {
                        OutInfo(outStr, msgParam).
                        set outVal:TIMEOUT to msgTimer.
                    }
                }
            }
            else
            {
                set g_MsgInfoLoopActive to False.
            }
        }
    }

    // MsgInfoString :: _string, _type, [_param] -> (none)
    // Adds a string to the automated information display queue
    global function MsgInfoString
    {
        parameter _type,
                  _string,
                  _param is -99.

        l_OutQueue[_type]:QUEUE:Add(_string).
        set l_OutQueue[_type]:TIMEOUT to Time:Seconds + l_OutDefTimeout.
        local paramVal to choose 0 if _param = -99 else _param.
        l_OutQueue[_type]:PARAMS:Add(paramVal).
        set g_MsgInfoLoopActive to True.
    }

    // OutMsg :: (Message)<string>, [(ErrorLevel)<Scalar>], [(TeeHUD)<bool>] -> (none)
    // Writes a message at line 5. 
    // TODO: If the ErrorLevel is 2 or higher, color codes the string for visibility
    global function OutMsg
    {
        parameter _str is "",
                  _errLvl is 0.
                  //_teeHUD is False. TODO: implement TeeHud function

        local msg_line to 8.
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
                  //_teeHUD is False. TODO: implement TeeHud function

        local line to 11.
        if _str:length > 0
        {
            print "[{0}] {1} ":Format("INFO", _str):PadRight(Terminal:Width - 2) at (2, line + _lineIdx).
        }
        else
        {
            if _lineIdx >= 0
            {
                print _str:PadRight(Terminal:Width - 2) at (2, line + _lineIdx).
            }
            else
            {
                for idx in list(0, 1, 2)
                {
                    print _str:PadRight(Terminal:Width - 2) at (2, line + idx).
                }
            }
        }
    }



    // OutDebug :: (Message)<string>, (LineIndex)<scalar> -> (none)
    // Writes a non-critical message at lines 6-8 depending on the line provided. 
    global function OutDebug
    {
        parameter _str is "",
                  _lineIdx is 0,
                  _color is "White".
                  //_teeHUD is False. TODO: implement TeeHud function
        
        local anchor to g_TermHeight - 20.
        local line to anchor.
        
        if _lineIdx < 0 
        {
            set line to anchor + Max(-5, abs(_lineIdx)).
        }
        else if _lineIdx > 0
        {
            set line to anchor + Min(g_TermHeight - 2 - _lineIdx, _lineIdx).
        }

        if _str:length > 0
        {
            // local newStr to "<color={0}>[`0~]</color> `1~ ":Format(_color).
            // set newStr to newStr:Replace("`","{"):Replace("~","}").
            // set newStr to newStr:Format("*DBG", _str).
            // print newStr:PadRight(Terminal:Width - 2) at (1, line).
            print "<color={2}>[{0}]</color> {1}     ":Format("*DBG", _str, _color) at (0, line).//:PadRight(Max(0, (Terminal:Width - 1) - (_str:Length + 8))) at (0, line).
        }
        else
        {
            print _str:PadRight(Terminal:Width - 2) at (1, line).
        }
        if g_Slowbug wait 0.325. // Debug induces a small wait to ensure messages can be seen
    }

    // *~ Display Components

    // DispAscentAngleStats :: (_statLex)<lexicon>, [(_line)<scalar>]
    // Does what it says. Since most of the vars in the ascentangle function are local,
    // it requires passing them all in via a telemetry-formatted lex
    global function DispAscentAngleStats
    {
        parameter _dispBlockIdx is -1,
                  _statLex is lexicon().

        if Terminal:Height + Terminal:Width <> g_TermSize
        {
            DispMain(ScriptPath(), True, Terminal:Width, Terminal:Height).
        }

        if _dispBlockIdx < 0
        {
            set _dispBlockIdx to NextOrAssignedTermBlock("ASCENT_ANGLE_STATS").
        }
        
        DispPrintBlock(_dispBlockIdx, _statLex).
    }

    // Mnv details
        global function DispBurnNodeData
        {
            parameter _dvToGo is 0, 
                      _burnETA is 0, 
                      _burnDur is 0,
                      _dispBlockIdx is -1.

            if Terminal:Height + Terminal:Width <> g_TermSize
            {
                DispMain(ScriptPath(), True, Terminal:Width, Terminal:Height).
            }
            
            if _dispBlockIdx < 0
            {
                set _dispBlockIdx to NextOrAssignedTermBlock("BURN_NODE_DATA").
            }
            
            if _burnETA >= 60 
            {

                set _burnETA to TimeSpan(_burnETA):full.
            }
            else
            {
                set _burnETA to round(_burnETA, 2).
            }
            
            // local burnDurStr to "BURN DURATION : {0}":Format(Round(_burnDur, 2)).
            // local burnETAStr to choose "BURN ETA      : {0}":Format(_burnETA) if _burnETA <> 0 else " ".
            // local dvToGoStr  to "DV REMAINING  : {0}":Format(Round(_dvToGo, 2)).
            
            // local dispList to list(
            //     "BURN NODE DATA"
            //     ,dvToGoStr:PadRight(l_GridSpaceLex[_dispBlockIdx][1] - dvToGoStr:Length)
            //     ,burnDurStr
            // ).
            local durSpan to TimeSpan(_burnDur).
            local durStr to "".
            if durSpan:Hour > 0 
            {
                local durHour to durSpan:Hour:ToString().
                if durHour:Length = 1 set durHour to "0" + durHour.
                set durStr to durStr + "{0}h":Format(durHour).
            }
            if durSpan:Minutes > 0
            {
                local durMin to durSpan:Minute:ToString().
                if durMin:Length = 1 set durMin to "0" + durMin.
                set durStr to durStr + " {0}m":Format(durMin).
            }
            if durSpan:Seconds > 0
            {
                local durSec to Round(durSpan:Minute, 2):ToString().
                if durSec:Split(".")[0]:Length = 1 set durSec to "0" + durSec.
                set durStr to durStr + " {0}s":Format(durSec).
            }
            local dispList to choose list(
                "BURN NODE DATA"
                ,"BURN ETA      : {0}":Format(_burnETA)
                ,"DV REMAINING  : {0}":Format(round(_dvToGo, 2))
                ,"BURN DURATION : {0}":Format(Round(_burnDur, 2))
                ,"                {0}":Format(durStr)
            ) if _burnETA > 0 else list(
                "BURN DATA"
                ,"DV REMAINING  : {0}":Format(round(_dvToGo, 2))
                ,"BURN DURATION : {0}":Format(Round(_burnDur, 2))
                ,"                {0}":Format(durStr)
                ," "
            ).
            
            DispPrintBlock(_dispBlockIdx, dispList).
        }

        // Displays active burn data
        global function DispBurnPerfData
        {
            parameter _dispBlockIdx is -1.

            DispEngineTelemetry(_dispBlockIdx).
            // if Terminal:Height + Terminal:Width <> g_TermSize
            // {
            //     DispMain(ScriptPath(), True, Terminal:Width, Terminal:Height).
            // }

            // if _dispBlockIdx < 0
            // {
            //     set _dispBlockIdx to NextOrAssignedTermBlock("BURN_PERF_DATA").
            // }

            // // local engList to GetActiveEngines().
            // // local perfObj to GetEnginesPerformanceData(engList).

            // local dispList to choose list(
            //     "ENGINE BURN PERF"
            //     ,"ENGINE COUNT   : {0}":Format(g_ActiveEngines:length)
            //     ,"THRUST         : {0}":Format(round(g_ActiveEngines_Data["Thrust"], 2))
            //     ,"THRUST (AVAIL) : {0}":Format(round(g_ActiveEngines_Data["ThrustAvailPres"], 2))
            //     ,"THRUST (PCT)   : {0}":Format(round(g_ActiveEngines_Data["ThrustPct"], 2))
            //     ,"MASS FLOW      : {0}":format(round(g_ActiveEngines_Data["MassFlow"], 4))
            //     ,"MASS FLOW (MAX): {0}":Format(round(g_ActiveEngines_Data["MassFlowMax"], 4))
            //     ,"MASS FLOW (PCT): {0}":Format(round(g_ActiveEngines_Data["MassFlowPct"] * 100, 1), 2)
            // ) if g_ActiveEngines_Data:HasKey("Thrust") 
            // else list(
            //     "ENGINE BURN PERF"
            //     ,"ENGINE COUNT   : {0}":Format(g_ActiveEngines:length)
            //     ,"THRUST         : {0}":Format("NUL")
            //     ,"THRUST (AVAIL) : {0}":Format("NUL")
            //     ,"THRUST (PCT)   : {0}":Format("NUL")
            //     ,"MASS FLOW      : {0}":format("NUL")
            //     ,"MASS FLOW (MAX): {0}":Format("NUL")
            //     ,"MASS FLOW (PCT): {0}":Format("NUL")
            // ).

            // DispPrintBlock(_dispBlockIdx, dispList).
        }

    global function DispEngineTelemetry
    {
        parameter _dispBlockIdx is -1,
                  _statLex is g_ActiveEngines_Data.

        if Terminal:Height + Terminal:Width <> g_TermSize
        {
            DispMain(ScriptPath(), True, Terminal:Width, Terminal:Height).
        }

        if _dispBlockIdx < 0
        {
            set _dispBlockIdx to NextOrAssignedTermBlock("ENGINE_TELEMETRY").
        }

        if Time:Seconds > g_LastUpdate
        { 
            set g_ActiveEngines_Data to GetEnginesPerformanceData(g_ActiveEngines). 
            set g_LastUpdate to Time:Seconds.
        }

        local timeRemaining to choose TimeSpan(_statLex:BurnTimeRemaining) if _statLex:HasKey("BurnTimeRemaining") else TimeSpan(0).
        local trStr to choose "{0}m {1}":Format(Floor(timeRemaining:Minutes), Round(Mod(timeRemaining:Seconds, 60), 1)) if Floor(timeRemaining:Minutes) > 0 else "{0}":Format(Round(Mod(timeRemaining:Seconds, 60), 1)).
        // local dispList to list(
        //     "ENGINE TELEMETRY"
        //     ,"THRUST    : {0}  ":Format(Round(_statLex:Thrust, 2))
        //     ,"AVL THRUST: {0}  ":Format(Round(_statLex:ThrustAvailPres, 2))
        //     ,"THRUST PCT: {0}% ":Format(Round(_statLex:ThrustPct * 100, 2))
        //     ,"ISP       : {0}s ":Format(Round(_statLex:ISPAt, 2))
        //     ,"BURN TIME : {0}":Format(trStr)
        // ).
        local dispList to choose list(
            "ENGINE PERFORMANCE"
            ,"ENGINES ACTIVE : {0,9}  ":format(g_ActiveEngines:length)
            ,"MASS FLOW      : {0,9}  ":format(round(_statLex["MassFlow"], 4))
            ,"MASS FLOW (MAX): {0,9}  ":format(round(_statLex["MassFlowMax"], 4))
            ,"MASS FLOW (PCT): {0,9}% ":format(round(_statLex["MassFlowPct"] * 100, 1))
            ,"THRUST         : {0,9}kn":format(round(_statLex["Thrust"], 2))
            ,"THRUST (AVAIL) : {0,9}kn":format(round(_statLex["ThrustAvailPres"], 2))
            ,"THRUST (PCT)   : {0,9}% ":format(round(_statLex["ThrustPct"] * 100, 2))
            ,"BURN TIME (EST): {0,9}s ":format(trStr)
        ) if g_ActiveEngines_Data:HasKey("Thrust") 
        else list(
            "ENGINE BURN PERF"
            ,"ENGINES ACTIVE : {0}":format(g_ActiveEngines:length)
            ,"MASS FLOW      : {0}":format("NUL")
            ,"MASS FLOW (MAX): {0}":format("NUL")
            ,"MASS FLOW (PCT): {0}":format("NUL")
            ,"THRUST         : {0}":format("NUL")
            ,"THRUST (AVAIL) : {0}":format("NUL")
            ,"THRUST (PCT)   : {0}":format("NUL")
            ,"BURN TIME (EST): {0}":format(trStr)
        ).

        DispPrintBlock(_dispBlockIdx, dispList).
    }

    // DispLaunchTelemetry :: [(_dispBlockIdx)<none>] -> <none>
    // Displays launch telemetry in the terminal grid. 
    // Defaults to next available grid space, can be pointed to a specific one
    global function DispLaunchTelemetry
    {
        parameter _dispBlockIdx is -1.

        if Terminal:Height + Terminal:Width <> g_TermSize
        {
            DispMain(ScriptPath(), True, Terminal:Width, Terminal:Height).
        }

        if _dispBlockIdx < 0
        {
            set _dispBlockIdx to NextOrAssignedTermBlock("LAUNCH_TELEMETRY").
        }

        local dispList to list(
            "TELEMETRY"
            ,"ALTITUDE : {0} ":Format(Round(Ship:Altitude))
            ,"APOAPSIS : {0} ":Format(Round(Ship:Apoapsis))
            ,"PERIAPSIS: {0} ":Format(Round(Ship:Periapsis))
            ,"VELOCITY"
            ,"  SURFACE : {0} ":Format(Round(Ship:Velocity:Surface:Mag, 1))
            ,"  ORBIT   : {0} ":Format(Round(Ship:Velocity:Orbit:Mag, 1))
        ).

        DispPrintBlock(_dispBlockIdx, dispList).
    }


    // DispMain :: (_scriptPath)<Path> -> (nextLine)<scalar>
    // Prints the main terminal header, and returns the next available line for printing
    global function DispMain
    {
        parameter _currentProcess is g_MainProcess,
                  _initTerm is True,
                  _termWidth is g_TermWidth,
                  _termHeight is g_TermHeight.

        if _currentProcess:IsType("Path") 
        {
            set _currentProcess to _currentProcess:ToString.
        }
        set _currentProcess to _currentProcess:Replace("0:/main", "").
        
        if _initTerm
        {
            set Terminal:Width to Max(l_Col0Size[0] + 4, _termWidth).
            set Terminal:Height to Max(48, _termHeight).
            DoEvent(Core, "Open Terminal").
        }

        ClearScreen.

        set g_Line to 0.
        local progName      to "KASA MISSION CONTROL".
        local progVer       to "v0.01 {0} ({1})":Format(Char(5679), "Omega").
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
        print "PROGRAM: {0}":Format(_currentProcess)                at (0, cr()).
        cr().
        
        DispTermGrid(10, l_Col0Size[0], l_Col0Size[1], 1, True).
        set g_GridAssignments[0] to "MAIN".
        DispTermGrid(g_Line, l_Col1Size[0], l_Col1Size[1], 2, False).

        return g_Line.
    }

    // DispPIDLoopValues :: _PID<PIDLoop> -> <none>
    global function DispPIDLoopValues
    {
        parameter _PID,
                  _dispBlockIdx is -1.

        if Terminal:Height + Terminal:Width <> g_TermSize
        {
            DispMain(ScriptPath(), True, Terminal:Width, Terminal:Height).
        }

        if _dispBlockIdx < 0
        {
            set _dispBlockIdx to NextOrAssignedTermBlock("REENTRY_TELEMETRY").
        }

        local dispList to list(
            "PID VALUES"
            ,"KP | KI | KD", "{0} | {1} | {2}":Format(_PID:KP, _PID:KI, _PID:KD)
            ,"MIN | MAX", "{0} | {1}":Format(_PID:MinOutput, _PID:MaxOutput)
            ,"SETPOINT", _PID:Setpoint
            ,"LAST OUTPUT", _PID:Output
            ,"LAST ERROR", _PID:Error
            ,"ERROR SUM", _PID:ErrorSum
            ,"TERM [P | I | D]", "{0} | {1} | {2}":format(_PID:PTerm,  _PID:ITerm, _PID:DTerm)
            ,"CHANGE RATE", Round(_PID:ChangeRate, 3) 
        ).

        DispPrintBlock(_dispBlockIdx, dispList).
    }

    // DispReetryTelemetry :: [(_dispBlockIdx)<scalar>] -> <none>
    // Displays reentry telemetry in the terminal grid. 
    // Defaults to next available grid space, can be pointed to a specific one
    global function DispReentryTelemetry
    {
        parameter _dispBlockIdx is -1.

        if Terminal:Height + Terminal:Width <> g_TermSize
        {
            DispMain(ScriptPath(), True, Terminal:Width, Terminal:Height).
        }

        if _dispBlockIdx < 0
        {
            set _dispBlockIdx to NextOrAssignedTermBlock("REENTRY_TELEMETRY").
        }

        local dispList to list(
            "TELEMETRY"
            ,"ALTITUDE : {0} ":Format(Round(Ship:Altitude))
            ,"APOAPSIS : {0} ":Format(Round(Ship:Apoapsis))
            ,"PERIAPSIS: {0} ":Format(Round(Ship:Periapsis))
            ,"VELOCITY"
            ,"  SURFACE : {0} ":Format(Round(Ship:Velocity:Surface:Mag, 1))
            ,"  ORBIT   : {0} ":Format(Round(Ship:Velocity:Orbit:Mag, 1))
        ).

        DispPrintBlock(_dispBlockIdx, dispList).
    }

    // DispStateFlags :: [(dispBlockIdx)<scalar>}] -> <none>
    // Displays the current value of all state flags currently active
    global function DispStateFlags
    {
        parameter _dispBlockIdx is -1.

        if Terminal:Height + Terminal:Width <> g_TermSize
        {
            DispMain(ScriptPath(), True, Terminal:Width, Terminal:Height).
        }

        if _dispBlockIdx < 0
        {
            set _dispBlockIdx to NextOrAssignedTermBlock("ARMED_SYS_STATE").
        }

        local dispList to list(
            "ARMED SYSTEMS"
            ,"AutoStage (HS): {0,-5} ({1})":Format(g_AutoStageArmed, g_HotStagingArmed)
            ,"Boosters (AS) : {0,-5} ({1})":Format(g_BoostersArmed, g_BoosterAirStart)
            ,"Decouplers    : {0,-5}":Format(g_DecouplerEventArmed)
            ,"Fairings      : {0,-5}":Format(g_FairingsArmed)
            ,"AutoMECO      : {0,-5}":Format(g_MECOArmed)
            ,"LES           : {0,-5}":Format(g_LESArmed)
            ,"RCS           : {0,-5}":Format(g_RCSArmed)
            ,"SpinStab      : {0,-5}":Format(g_SpinArmed)
            ,"UIDUpdater    : {0,-5}":Format(g_UIDUpdaterArmed)
        ).

        DispPrintBlock(_dispBlockIdx, dispList).
    }

    // #endregion

    // *- Full Display
    // #region

    // DispTermGrid :: <scalar>_columnWidth, <scalar>_rowHeight -> <none>
    // Draws a grid on the terminal screen. Takes width of columns and height of rows as parameters.
    // Note: the function reserves one px on each side of the column for the grid lines
    // Example: On a 72col screen, a _columnWidth of 16 will result in 4 columns, with grid lines in between
    global function DispTermGrid
    {
        parameter _startAt      is 10,
                  _colWidth     is 34, 
                  _rowHeight    is 20,
                  _rowCount     is 0, //-1,
                  _refreshRef   is False.

        set g_Line to _startAt.

        set Terminal:Width to Max(Terminal:Width, _colWidth + 4).
        set Terminal:Height to Max(Terminal:Height, _StartAt + _rowHeight + 10).

        local colWidthFloor to _colWidth - 2.
        local colCount      to Floor((Terminal:Width) / (colWidthFloor + 2)).
        local colStr        to l_GridColLine:Call(_colWidth, "|").
        local colIdxList    to list(2). // Prepopulated with 2 because that's where the safe column space always starts
        
        local rowLineWidth  to (_colWidth) * colCount.
        local headerStr     to l_GridRowLine:Call(rowLineWidth, "=").
        local rowStr        to l_GridRowLine:Call(rowLineWidth, "_").

        local rowCount      to choose _rowCount if _rowCount > 0 else Floor((Terminal:Height - g_Line - 10) / _rowHeight).
        local rowInnerIdx   to 0.
        local rowTotalIdx   to 0.

        if _refreshRef
        {
            set l_GridSpaceIdx to 0.
            l_GridSpaceLex:Clear().
            g_GridAssignments:Clear().
            ClearDispBlock().
        }

        // if g_Debug
        // {
        //     // if g_Debug { OutDebug("DispTermGrid|colCount/rowCount: [{0}/{1}]":Format(colCount, rowCount), -4).}
        // }

        // This bit adds the column position for each possible column beyond the start.
        from { local i to 1.} until i > colCount step { set i to i + 1.} do
        {
            colIdxList:Add(2 + (i * _colWidth)). 
        }

        from { local iRow to 0.} until iRow > rowCount step { set iRow to iRow + 1.} do
        {
            local rowLine to _startAt + 1 + Max(0, (iRow - 1) * _rowHeight).
            
            // if g_Debug
            // {
            //     if g_Debug { OutDebug("DispTermGrid|iRow/rowLine: [{0}/{1}]":Format(iRow, rowLine), -3).}
            // }

            from { local iCol to 0.} until iCol = colIdxList:Length step { set iCol to iCol + 1.} do
            {
                set l_GridSpaceIdx to iCol + iRow.

                // if g_Debug
                // {
                //     if g_Debug { OutDebug("DispTermGrid|iCol/iRow (l_GridSpaceIdx): [{0}/{1}] ({2})":Format(iRow, rowLine, l_GridSpaceIdx), -2).}
                // }

                if g_GridAssignments:HasKey(l_GridSpaceIdx)
                {
                    if g_GridAssignments[l_GridSpaceIdx] = ""
                    {
                        set l_GridSpaceLex[l_GridSpaceIdx] to list(colIdxList[iCol], _colWidth, rowLine, _rowHeight).
                    }
                }
                else
                {
                    set l_GridSpaceLex[l_GridSpaceIdx] to list(colIdxList[iCol], _colWidth, rowLine, _rowHeight).
                    set g_GridAssignments[l_GridSpaceIdx] to "".
                }
                set l_MaxAvailGridIdx to Max(l_MaxAvailGridIdx, l_GridSpaceIdx).
            }
        }
    
        // print the header line
        print headerStr at (0, g_Line).
        
        // Print the grid for this row
        until rowTotalIdx = rowCount
        {
            set rowInnerIdx to 0.
            until rowInnerIdx >= _rowHeight - 1 or g_Line >= Terminal:Height - 6
            {
                print colStr at (0, cr()).
                set rowInnerIdx to rowInnerIdx + 1.
            }
            set rowTotalIdx to rowTotalIdx + 1.
            if rowTotalIdx < rowCount print rowStr at (0, cr()).
        }
        print headerStr at (0, cr()).

        // if g_Debug
        // {
        //     if g_Debug { OutDebug("DispTermGrid|l_GridSpaceLex: [{0}]":Format(l_GridSpaceLex:Keys:Join(";")), -1).}
        //     wait 0.25.
        // }

        set g_TermSize to Terminal:Height + Terminal:Width.
        // Neat
    }

    // NextOrAssignedTermBlock :: [_dispId<string>] -> (_outIdx)<scalar>
    // Returns the index of the next available block for display readouts
    // when using the grid system, or the idx of the assignment if the provided
    // disp component name is already assigned
    global function NextOrAssignedTermBlock
    {
        parameter _dispId.

        local blockIdx to 0.

        if g_GridAssignments:Values:Length = 0
        {
            // if g_Debug OutDebug("[NextOrAssignedTermBlock] l_GridAssignments error [Length: {0}]":Format(l_GridAssignments:Values:Length)).
            set l_LastAssignedBlock to blockIdx.
            // return l_LastAssignedBlock.
        }
        else if g_GridAssignments:Values:Contains(_dispId)
        {
            set blockIdx to g_GridAssignments:Keys[g_GridAssignments:Values:find(_dispId)].
            // if g_Debug OutDebug("[NextOrAssignedTermBlock] l_GridAssignments _dispId cache hit [{0}]":Format(blockIdx)).
            // return blockIdx.
        }
        else
        {
            // if g_Debug OutDebug("[NextOrAssignedTermBlock] l_GridAssignments _dispId cache miss [{0}]":Format(blockIdx)).
            
            from { local i to blockIdx. local doneFlag to False. } until i > l_MaxAvailGridIdx or doneFlag step { set i to i + 1.} do
            {
                local processFlag   to False.
                if g_GridAssignments:HasKey(i)
                {
                    if g_GridAssignments[i]:Length = 0
                    {
                        set processFlag to True.
                    }
                }
                else if i <= l_MaxAvailGridIdx
                {
                    set processFlag to True.
                }

                if processFlag 
                {
                    set g_GridAssignments[i] to _dispId.
                    set blockIdx to i.
                    set doneFlag to True.
                }
            }
        }
        
        return blockIdx.
    }

    global function ClearDispBlock
    {
        parameter _dispId is "ALL".

        local blockAnchor    to list().
        local blockClearList to list().
        local doneFlag       to False.

        if _dispId = "ALL"
        {
            set blockClearList to g_GridAssignments:Values.
        }
        else
        {   
            local blockIdx to 0.
            for blockID in g_GridAssignments:Values
            {
                if blockID = _dispId
                {
                    blockClearList:Add(blockIdx).
                    set doneFlag to True.
                }
                
                if doneFlag
                {
                    break.
                }
                else
                {
                    set blockIdx to blockIdx + 1.
                }
            }
        }
        
        for blockID in blockClearList
        {
            if l_GridSpaceLex:HasKey(blockID)
            {
                set blockAnchor to l_GridSpaceLex[blockID].

                local colStop to blockAnchor[0] + blockAnchor[1].
                local rowStop to blockAnchor[2] + blockAnchor[3].

                local col to blockAnchor[0].
                set g_Line to blockAnchor[2].
                until g_line > rowStop 
                {
                    print " ":PadRight(colStop) at (col, cr()).
                }
                // if g_Debug OutDebug("[DispClearBlock] Completed for Block [ID:{0}]":Format(blockID)).
                set g_GridAssignments[blockID] to "".
            }
            else
            {
                // if g_Debug OutDebug("[DispClearBlock] Missing blockID in l_GridSpaceLex [{0}]":Format(blockID)).
            }
        }
    }

    // DispPrintBlock :: (_blockIdx)<scalar>, (_dispData)[String<list>], [_numColumns<Scalar>] -> <none>
    // Does what's on the tin
    local function DispPrintBlock
    {
        parameter _blockIdx,
                  _dispData,
                  _numColumns is 1.

        local blockAnchor to list().

        if g_Debug 
        {
            if g_Debug { OutDebug("DispPrintBlock|Params: [{0}][{1}][{2}]":Format(_blockIdx, _dispData, _numColumns)).}
        }

        if _blockIdx:IsType("String")
        {
            set _blockIdx to _blockIdx:ToNumber(1).
        }

        // if _blockIdx:IsType("Scalar")
        // {
        if l_GridSpaceLex:HasKey(_blockIdx)
        {
            set blockAnchor to l_GridSpaceLex[_blockIdx].
        }

        if g_Debug
        {
            if g_Debug { OutDebug("DispPrintBlock|l_GridSpaceLex:HasKey({0}): [{1}]":Format(_blockIdx, l_GridSpaceLex:HasKey(_blockIdx)), 1).}
            if g_Debug { OutDebug("DispPrintBlock|l_GridSpaceLex:Keys: [{0}]":Format(l_GridSpaceLex:Keys:Join(";")), 2).}
        }
            // else
            // {
            //     // if g_Debug OutDebug("[DispPrintBlock] Missing _blockIdx in l_GridSpaceLex [{0}]":Format(_blockIdx)).
            //     // set blockAnchor to l_GridSpaceLex[1].
            // }
        // }
        // else if _blockIdx:IsType("String")
        // {
        //     if g_GridAssignments:Values:Contains(_blockIdx)
        //     {
        //         set blockAnchor to l_GridSpaceLex[g_GridAssignments:Values:Find(_blockIdx)].
        //     }
        //     else
        //     {
        //         set blockAnchor to l_GridSpaceLex[NextOrAssignedTermBlock(_blockIdx)].
        //     }
        // }

        set g_Col to blockAnchor[0] + 1.
        local g_ColLim to blockAnchor[1] - 1. 
        set g_line to blockAnchor[2].
       
        from { local i to 0.} until i = _dispData:Length step { set i to i + _numColumns.} do
        {
            local bulletStr to choose "{0} ":Format(Char(9500)) if i > 0 else "".
            local str to _dispData[i].
            if not str:IsType("String") set str to str:ToString.

            if str:Length > g_ColLim
            {
                set str to str:SubString(0, g_ColLim).
            }
            else
            {
                set str to str:PadRight(Max(0, g_ColLim - str:Length)).
            }

            if i > 0
            {
                print "{0}{1,-16}":Format(bulletStr, _dispData[i]) at (g_Col, cr()).
                set g_Col to g_Col + 18.
                from { local _i to i + 1.} until _i >= i + _numColumns step { set _i to _i + 1.} do
                {
                    local _str to choose ": {0}" if _i = i + 1 else " | {0}".
                    set _str to _str:Format(_dispData[_i]).
                    print _str at (g_Col, g_Line).
                    set g_Col to min(Terminal:Width - 8, g_Col + _str:Length + 2).
                }
            }
            else
            {
                print "{0}{1,-16}":Format(bulletStr, _dispData[i]) at (g_Col, cr()).
                print str:ToUpper at (g_Col, cr()).
                for colFoo in Range(0, str:Length, 1)
                {
                    print "-" at (g_Col + colFoo, g_Line).
                }
            }
        
            set g_Col to blockAnchor[0] + 1.
        }
        // for line in _dispData
        // {
        //     if lineIdx > 0
        //     {
        //         print "{0} {1}":Format(Char(9500),line) at (g_Col, cr()).
        //     }
        //     else 
        //     {
        //         print line:ToUpper at (g_Col, g_line).
        //         cr().
        //         for colFoo in Range(0, line:Length - 1, 1)
        //         {
        //             print "-" at (g_Col + colFoo, g_line).
        //         }
        //         set lineIdx to lineIdx + 1.
        //     }
        // }
    }
    // #endregion
// #endregion