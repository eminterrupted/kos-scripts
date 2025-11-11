@LazyGlobal off.
ClearScreen.

parameter _params is list().

// Dependencies
RunOncePath("0:/lib/depLoader").

// Declare Variables
local tgt to Ship:Body.

// Parse Params
if _params:length > 0 
{
  set tgt to choose _params[0] if _params[0]:IsType("Orbitable") else tgt.
}

if not hasTarget
{
  OutMsg("Select Target").
  wait until hasTarget.
}

local etaToTA is GetTimeToAscendingNode(tgt, Ship).

local epoch to Time:Seconds.
local tsTA to epoch + etaToTA.
local doneFlag to false.
local leadTimeSecs to 0.
OutMsg("ETA to Ascending Node"). 
OutInfo("PreCalc: {0} ":Format(TimeSpan(etaToTA):Full)).
OutInfo("+/- to add extra lead time: {0}s ":Format(leadTimeSecs), 1).

until doneFlag
{
    set tsTA to epoch + GetTimeToAscendingNode(tgt, Ship).
    set g_TermChar to GetTermChar().

    if g_TermChar = Terminal:Input:EndCursor
    {
        set doneFlag to True.
        OutMsg("Okay, fine").
        OutInfo("...jerkface").
        OutInfo(" >:|",1).
    }
    else if g_TermChar = "-"
    {
      set leadTimeSecs to max(0, leadTimeSecs - 5).
    }
    else if g_TermChar = "+"
    {
      set leadTimeSecs to max(0, leadTimeSecs + 5).
    }
    set tsTA to tsTA - leadTimeSecs.
    
    OutMsg("ETA to Ascending Node"). 
    OutInfo("PreCalc: {0} ":Format(TimeSpan(etaToTA):Full)).
    OutInfo("NewCalc: {0} ":Format(TimeSpan(tsTA):Full),1).

    if Time:Seconds >= tsTA 
    {
      set doneFlag to true.
      OutMsg("Done, bozo").
      OutInfo().
      OutInfo("",1).
    }
}