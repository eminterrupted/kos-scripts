@LazyGlobal off.
ClearScreen.

parameter _params is list().

RunOncePath("0:/lib/libLoader.ks").

set g_MainProcess to ScriptPath().
DispMain().

local stageLimit to 0.

if _params:Length > 0
{
    set stageLimit to ParseStringScalar(_params[0], stageLimit).
}
SAS off.
RCS on.

SetupOnDeployHandler(Ship:PartsTaggedPattern("OnDeploy")).

local doneFlag to False.
until doneFlag
{
    set doneFlag to True.
    from { local i to Stage:Number.} until i < 0 step { set i to i - 1.} do
    {
        if g_LoopDelegates:Events:Keys:Contains("OnDeploy_{0}":Format(i))
        {
            ExecGLoopEvents().
            set doneFlag to False.
        }
    }
    wait 0.01.
}

set g_StageLimit to stageLimit.
if HasNode
{
    ExecNodeBurn_Next(NextNode, stageLimit).
}