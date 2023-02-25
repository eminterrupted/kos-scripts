@LazyGlobal off.
ClearScreen.

parameter params is list().

// Dependencies
RunOncePath("0:/lib/loadDep").

DispMain(ScriptPath():name).

// Declare Variables
local waitType to "AP".
local waitTS to Time:Seconds + ETA:Apoapsis.

// Parse Params
if params:length > 0 
{
  set waitType to params[0].
  if params:length > 1 set waitTS to params[1].
}

InitOnEventTrigger(ship:PartsTaggedPattern("OnEvent|ASC")).
lock steering to s_Val.

OutMsg("{0,-15}: {1}":Format("Wait Type", waitType)).
until Time:Seconds >= waitTS
{
    OutInfo("{0,-15}: {1}":Format("Time Remaining", TimeSpan(waitTS - Time:Seconds):Full:ToString:Replace("y","y "):Replace("d","d "):Replace("h","h "):Replace("m","m "):Replace("s","s "))).
    set s_Val to Ship:Prograde:Vector.
    wait 0.01.
}
OutInfo().
OutMsg("Wait over!").