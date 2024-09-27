@LazyGlobal off.
ClearScreen.

parameter _params is list().

// Dependencies
RunOncePath("0:/lib/depLoader").
RunOncePath("0:/lib/deploy").

DispMain(ScriptPath()).

// Declare Variables
local payloadStage to 0.
local tagStr to "OnPayload".

// Parse Params
if _params:length > 0 
{
  set payloadStage to _params[0].
  if _params:length > 1 set tagStr to _params[1].
}

OutInfo("[{0}]: Waiting for payload stage ({1})":Format(tagStr, payloadStage)).
until Stage:Number = payloadStage
{
    OutInfo("Current Stage: [{0}] ":Format(Stage:Number)).
    wait 1.
}

OutMsg("Executing [{0}] deployment":Format(tagStr)).
RunDeployRoutine(tagStr).
