// #include "0:/lib/depLoader.ks"
@LazyGlobal off.

// ***~~~ Dependencies ~~~*** //
// #region
// #endregion


// ***~~~ Variables ~~~*** //
// #region
    
    // *- Local
    // #region
    local l_defaultLogPath to "0:/log/AEA/{0}-{1}.log":Format(Round(MissionTime), Ship:Name:Replace(" ","_")).
    local l_sysLog to Path(l_defaultLogPath).
    // #endregion

    // *- Global
    // #region
    global g_DataLog to "0:/data/logs/{0}.csv":Format(Ship:Name:Replace(" ","-")).
    // set g_LogOut to true.
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

    // InitLog :: (logPath)<Path> -> (result)<bool>
    // Initializes the log
    global function InitLog
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

    // OutLog :: (logPath)<Path> -> (result)<bool>
    // Initializes the log
    global function OutLog
    {
        parameter _str,
                  _msgType is 0.

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
    
// #endregion
// #endregion