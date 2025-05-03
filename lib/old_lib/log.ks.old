// #include "0:/lib/libLoader.ks"
@LazyGlobal off.

// ***~~~ Dependencies ~~~*** //
// #region
// #endregion


// ***~~~ Variables ~~~*** //
// #region
    
    // *- Local
    // #region
    local l_logInit to False.
    local l_defaultLogPath to "0:/log/AEA/{0}-{1}.log":Format(Round(MissionTime), Ship:Name:Replace(" ","_"):Replace("*","_")).
    local l_sysLog to Path(l_defaultLogPath).
    // #endregion

    // *- Global
    // #region
    global g_DataLog to "0:/data/logs/{0}.csv":Format(Ship:Name:Replace(" ","-")).
    global g_LogOut to False.
    // #endregion
// #endregion

// ***~~~ Delegate Objects ~~~*** //
    // *- Local Anonymous Delegates
    // #region
    // #endregion

    // *- Global Anonymous Delegates
    // #region
    // #endregion
// #endregion


// Any common code needed to run as part of setup, run here
if g_LogOut
{
    if exists(g_DataLog) DeletePath(g_DataLog).
    log "MET,effPitAng,adjPitLim,curAltPres,tgtAltPitAng,curAlt,curAltErr,curApoErr,curEffErr,curTurnAltErr,curProPit,obtProPit,obtProPitAdj,srfProPit,srfProPitAdj" to g_DataLog.
}


// ***~~~ Functions ~~~*** //
// #region

//  *- Log Initialization
// #region

    // InitLog :: _logPath<String>, [_resetLog<Bool>] -> logReady<bool> 
    global function InitLog
    {
        parameter _logPath is l_Log,
                    _resetLog is 0. // 0: Append or Create, 1:Reset:Archive old, 2:Reset:Delete old

        local logPtr to "".
        local newLog to True.

        if exists(_logPath)
        {
            if _resetLog > 0
            {
                if _resetLog > 1
                {
                    DeletePath(_logPath).
                }
                else
                {
                    local logArchivePath to "0:/log/mission/archive/{0}/logArchive_{0}_{1}.log":Format(Ship:Name:Replace(" ","_"), Ship:Name:Replace(" ","_"), Round(MissionTime)).
                    if exists(logArchivePath) MovePath(logArchivePath, logArchivePath:Replace(".log", "_1.log")).
                    MovePath(_logPath, logArchivePath).
                }
            }
            else
            {
                set newLog to False.
            }
        }

        if newLog
        {
            set logPtr to Create(_logPath).
            logPtr:WriteLn("==================================").
            logPtr:WriteLn("*** MISSION LOG INITIALIZATION ***").
            logPtr:WriteLn("*** VESSEL: {0} ***":Format(Ship:Name)).
            logPtr:WriteLn("*** MET   : {0} ***":Format(Round(MissionTime))).
            logPtr:WriteLn("*** UT    : {0} ***":Format(Round(Time:Seconds))).
            logPtr:WriteLn("==================================").
            logPtr:WriteLn("").
        }
        else
        {
            set logPtr to Open(_logPath).
            logPtr:WriteLn("").
            logPtr:WriteLn("==================================").
            logPtr:WriteLn("** MISSION LOG REINITIALIZATION **").
            logPtr:WriteLn("*** MET   : {0} ***":Format(Round(MissionTime))).
            logPtr:WriteLn("*** UT    : {0} ***":Format(Round(Time:Seconds))).
            logPtr:WriteLn("==================================").
            logPtr:WriteLn("").
        }

        set l_logInit to Exists(_logPath).
        return l_logInit.
    }

        


    // InitLog_Old :: (logPath)<Path> -> (result)<bool>
    // Initializes the log
    global function InitLog_Old
    {
        parameter _logPath is l_sysLog.

        local initType to choose "Initialization" if MissionTime = 0 else "Reinitialization".
        set l_sysLog to choose _logPath if _logPath:IsType("Path") else Path(_logPath).

        if exists(l_sysLog) 
        {
            if MissionTime = 0
            {
                DeletePath(l_sysLog).
                Create(l_sysLog).
            }
        }
        else
        {
            Create(l_sysLog).
        }
        set l_sysLog to Open(l_sysLog).
        
        local headerLine to "********************************************************************************".
        l_sysLog:WriteLn(headerLine).
        l_sysLog:WriteLn(" ").
        local str to "{0} SYSTEM LOG":Format(Ship:Name).
        local strPad to Floor((80 - str:Length) / 2).
        l_sysLog:WriteLn(str:PadLeft(strPad):PadRight(strPad)).
        l_sysLog:WriteLn(" ").
        l_sysLog:WriteLn(headerLine).
        l_sysLog:WriteLn(" ").
        l_sysLog:WriteLn("{0} at MET: {1} (UT: {2} | {3})":Format(initType, Round(MissionTime,3), Round(Time:Seconds, 5), TimeSpan(Time:Seconds):Full)).
        l_sysLog:WriteLn(" ").
        l_sysLog:WriteLn(" ").

        return exists(l_sysLog).
    }
    
// #endregion

//  *- Log Writing
// #region

    // OutLog :: _str<String>, [_level<Scalar>], [_tee<Boolean>] -> <none>
    global function OutLog
    {
        parameter _str,
                    _level is 0,
                    _tee   is False.

        if not l_logInit InitLog().

        local ut to TimeSpan(Time:Seconds).
        local mt to TimeSpan(MissionTime).

        local logUTimeStr to "{0}-{1}-{2}T{3}:{4}:{5}":Format(ct:Year + 1951, g_CalLookup:GetMonth:Call(ut:Day), ut:Day, ut:Hour, ut:Minute, Round(Mod(ut:Seconds, 60), 3)).
        local logMTimeStr to "{0}-{1}-{2}T{3}:{4}:{5}":Format(mt:Year, g_Cal:Convert:DaysToMonths:Call(mt:Day), mt:Day, mt:Hour, mt:Minute, Round(Mod(mt:Seconds, 60), 3)).
        l_log:WriteLn().
    }

    global g_Cal to lexicon(
        "Convert", lexicon(
            "DaysToMonths", ConvertDaysToMonths@
        )
    ).

    local function ConvertDaysToMonths
    {
        parameter _days.

        local isLeapYear to g_Cal:Reference:LeapYear:Contains(1951 + TimeSpan(Time:Seconds):Year).
        
        if      _days < 30 return 0.
        else 
        {

        }
    }

    // OutLog_Old :: (logPath)<Path> -> (result)<bool>
    // Initializes the log
    global function OutLog_Old
    {
        parameter _str,
                  _msgType is 0.

        if HomeConnection:IsConnected
        {
            if not exists(l_sysLog)
            {
                InitLog().
            }

            if not l_sysLog:IsType("VolumeFile")
            {
                if l_sysLog:IsType("String")
                {
                    set l_sysLog to Open(Path(l_sysLog)).
                }
                else if l_sysLog:IsType("Path")
                {
                    set l_sysLog to Open(l_sysLog).
                }
            }

            local mtSpan to TimeSpan(MissionTime).
            // local utSpan to TimeSpan(Time:Seconds).

            local typeStr to choose "" if _msgType = 0 else choose "[INFO]: " if _msgType = 1 else choose "[WARN]: " if _msgType = 2 else "[*ERR]".

            local formattedStr to "[Y{0}-D{1,0}T{2,2}:{3,2}:{4,-8}|M_{5,-8}] {6}{7}":Format(mtSpan:Year, mtSpan:Day, mtSpan:Hour, mtSpan:Minute, Round(Mod(mtSpan:Seconds, 60), 3), Round(MissionTime, 3), typeStr, _str).
            l_sysLog:WriteLn(formattedStr).
        }
    }
    
// #endregion
// #endregion