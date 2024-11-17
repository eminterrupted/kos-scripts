@LazyGlobal off.
ClearScreen.

parameter _deployTag is "OnDeploy".

// Dependencies
RunOncePath("0:/lib/depLoader").
RunOncePath("0:/lib/deploy").

// Declare Variables

DispMain(ScriptPath(), False).

OutMsg("Running Deploy Routine").
wait 1.

RunDeployRoutine(_deployTag).

wait 1.

OutMsg("Deploy Routine Complete").
wait 5.