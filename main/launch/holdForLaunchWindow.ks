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

local etaToTA is GetTimeToAscendingNode(tgt, Ship).

local doneFlag to false.

until doneFlag
{
    local updt to GetTimeToAscendingNode(tgt, Ship).
    OutMsg("ETA to Ascending Node"). 
    OutInfo("PreCalc: {0} ":Format(TimeSpan(etaToTA):Full)).
    OutInfo("NewCalc: {0} ":Format(TimeSpan(updt):Full),1).
    

    if Terminal:Input:HasChar
    {
        set doneFlag to True.
    }
    wait 0.01.
}

wait 1.
