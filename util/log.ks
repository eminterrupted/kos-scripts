@LazyGlobal off.
ClearScreen.

parameter params is list().

// Dependencies
RunOncePath("0:/lib/libLoader").

DispMain(ScriptPath():name).

// Declare Variables
local colNames      to list().
local dataDelegate  to "".
local dataObj       to lexicon().
local dataStr       to "".
local destFiles     to list().
local doneFlag      to false.
local fileExtension to "".
local idxNext       to -1.
local logFormat     to "Default".
local logPath       to "".
local logType       to "atm". // Atmosphere to start
local logName       to "log_{0}_{1}":Format(logType:ToUpper, Round(KUniverse:RealTime):ToString).
local teeOutput     to false.


// Parse Params
if params:length > 0 
{
    set logType to params[0].
    if params:length > 1 set logName   to params[1].
    if params:length > 2 set logFormat to params[2].
    if params:length > 3 set teeOutput to params[3].
}

if logName:MatchesPattern("[ \/\\\[\]\{\},\*&@;:]")
{
    for c in list(" ","\","/","[","]","{","}","*","&","@",";",":")
    {
        set logName to logName:Replace(c,"_").
    }
}

if logFormat = "Default" 
{
    set fileExtension to "log".
}
else if logFormat = "CSV"
{
    set fileExtension to "csv".
}
set destFiles   to Archive:Files:Data:Lexicon:Log:Lexicon:AdHoc:Lexicon:Keys.
for destFile in destFiles
{
    if destFile:MatchesPattern("{0}_{1}":Format(logName, "\d"))
    {
        local lastUnderscore to destFile:FindLast("_").
        local lastPeriod     to destFile:FindLast(".").
        local destFileIdx to destFile:Substring(lastUnderscore, lastPeriod - lastUnderscore):ToNumber(-1).
        set idxNext to max(idxNext, destFileIdx).
    }
}
set idxNext to idxNext + 1.

set logPath to Path("{0}/{1}_{2}.{3}":Format("0:/data/log/adhoc", logName, idxNext, fileExtension)).

if logType = "atm"
{
    // set logInitStr   to "ATMOSPHERIC PRESSURE".
    set colNames     to g_LogDelegates:ATM:Keys.
    // set colDelegates to g_LogDelegates:ATM:Values.
    set dataDelegate to GetAtmosphericData@.
}

if logFormat = "Default"
{
    local colNameStr    to "[MISSION_TIME]".
    from { local i to 1.} until i = colNames:Length step { set i to i + 1.} do
    {
        set colNameStr to colNameStr + " | {0, -12}":Format(colNames[i]).
    }
    log colNameStr to logPath.
    
    OutInfo("Waiting for launch...").
    until Ship:Status <> "PRELAUNCH"
    {
        wait 0.01.
    }
    until doneFlag
    {
        set dataStr to "[{0,12}]":Format(Round(MissionTime, 3)).
        set dataObj to dataDelegate:Call().
        for val in dataObj:Values
        {
            set dataStr to dataStr + " | {0,-12}":Format(val).
        }
        log dataStr to logPath.

        set doneFlag to CheckTermChar().
        wait 0.001.
    }
}
else if logFormat = "CSV"
{
    local colNameStr    to "MISSION_TIME".
    from { local i to 1.} until i = colNames:Length step { set i to i + 1.} do
    {
        set colNameStr to colNameStr + ",{0}":Format(colNames[i]:Replace(" ","_")).
    }
    log colNameStr to logPath.

    OutInfo("Waiting for launch...").
    until Ship:Status <> "PRELAUNCH"
    {
        wait 0.01.
    }

    until doneFlag
    {
        set dataStr to "{0}":Format(Round(MissionTime, 3)).
        set dataObj to dataDelegate:Call().
        for val in dataObj:Values
        {
            set dataStr to dataStr + ",{0}":Format(val).
        }
        log dataStr to logPath.

        if Ship:Altitude >= Body:ATM:Height or CheckTermChar(Terminal:Input:EndCursor)
        {
            set doneFlag to true.
        }
        wait 0.01.
    }
}
OutInfo().
OutMsg("Logging Terminated").