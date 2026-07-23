@LazyGlobal off.
ClearScreen.

parameter _params is list().

// Dependencies
RunOncePath("0:/lib/depLoader").

DispMain().

// Declare Variables
local holdTS to 0.
local leadTimeSecs to 15.
local tgt to Ship:Body.
local tgtInc to Ship:Orbit:Inclination.
local launchWindow to Time:Seconds.
local etaToTA is launchWindow - Time:Seconds.
local warpTS to launchWindow - leadTimeSecs - 2.

// Parse Params
if _params:length > 0 
{
  set tgt to choose _params[0] if _params[0]:IsType("Orbitable") else tgt.
  if _params:length > 1 set tgtInc to ParseStringScalar(_params[1], tgtInc).
  if _params:length > 2 set launchWindow to ParseStringScalar(_params[2], launchWindow).
  if _params:length > 3 set etaToTA to ParseStringScalar(_params[3], etaToTA).
}

if not hasTarget
{
  OutMsg("Select Target").
  wait until hasTarget.
}

if etaToTA <= 15
{
  set etaToTA to Round(GetTimeToAscendingNode(tgt), 1).
  set launchWindow to Time:Seconds + etaToTA.
}
else
{
  set launchWindow to Time:Seconds + 15.
}

OutMsg("ETA to Ascending Node"). 
OutInfo("Countdown: T-{0} ":Format(TimeSpan(etaToTA):Full)).
OutInfo("LEFT/RIGHT: -/+ lead time: {0}s ":Format(leadTimeSecs), 1).
OutDebug("Press Anything Yo").

local doneFlag to false.
set g_TermChar to "".

until doneFlag
{
    set warpTS to launchWindow - leadTimeSecs - 2.
    OutInfo("Countdown: T-{0} ":Format(TimeSpan(etaToTA):Full)).
    OutInfo("ENTER: Warp to T-{0} | END: End countdown hold":Format(Round(leadTimeSecs + 2, 1)), 2).
    wait 5.
    set doneFlag to true.
    // set g_TermChar to GetTermChar().
    // if g_TermChar:Length > 0 
    // {
    //   if g_TermChar = Terminal:Input:Enter
    //   {
    //       OutInfo("Warp started", 1). 
    //       OutInfo("", 2).
    //       warpTo(warpTS).
    //   }
    //   else if g_TermChar = Terminal:Input:EndCursor
    //   {
    //       set doneFlag to True.
    //   }
    //   else if g_TermChar = Terminal:Input:LeftCursorOne
    //   {
    //     set leadTimeSecs to max(0, leadTimeSecs - 5).
    //   }
    //   else if g_TermChar = Terminal:Input:RightCursorOne
    //   {
    //     set leadTimeSecs to max(0, leadTimeSecs + 5).
    //   }
    //   else if g_TermChar = Terminal:Input:UpCursorOne.
    //   {
    //     set etaToTA to ParseStringTime(UpdateTermString(etaToTA, g_DateTimeRegex), etaToTA).
    //   }
    //   set g_TermChar to "".
    //   set launchWindow to Round(Time:Seconds + etaToTA, 1).

    //   if Time:Seconds >= launchWindow - leadTimeSecs - 2
    //   {
    //     set holdTS to Time:Seconds + 2.
    //     set doneFlag to true.
    //   }
    //   set g_TermChar to "".
    // }
}
OutMsg("Hold enabled, resuming in {0}   ":Format(Timespan(Round(holdTS - Time:Seconds, 2)))).
OutInfo("",2).
wait until holdTS.
OutMsg("Hold Released at T-{0} ":Format(Round(launchWindow - Time:Seconds, 1)), 1).