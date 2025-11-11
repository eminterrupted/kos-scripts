@LazyGlobal off.
ClearScreen.

parameter _params is list().

if Ship:Altitude >= Ship:Body:Atm:Height
{
  // Dependencies
  RunOncePath("0:/lib/libLoader").
  RunOncePath("0:/lib/deploy").

  DispMain(ScriptPath(), false).

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
  OutInfo("Current Stage: [{0}] ":Format(Stage:Number), 1).
  if Stage:Number <= payloadStage + 1
  {
    until Stage:Number = payloadStage 
    {
      wait until Stage:Ready.
      stage.
      OutInfo("Current Stage: [{0}] ":Format(Stage:Number), 1).
      wait 1.
    }
    OutMsg("Executing [{0}] deployment":Format(tagStr)).
    RunDeployRoutine(tagStr).
  }
}