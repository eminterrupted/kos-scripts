@LazyGlobal off.
ClearScreen.

parameter _params is list().

RunOncePath("0:/lib/libLoader.ks").

set g_MainProc to ScriptPath().
DispMain().

set g_MissionTag to ParseCoreTag(Core:Tag).

local stageLimit to 0.
local execOnDeploy to false.

if _params:Length > 0
{
    set stageLimit to ParseStringScalar(_params[0], stageLimit).
    if _params:length > 1 set execOnDeploy to _params[1].
}
SAS off.
RCS on.

SetupOnDeployHandler(Ship:PartsTaggedPattern("OnDeploy")).

until not execOnDeploy
{
    from { local i to Stage:Number.} until i < stageLimit step { set i to i - 1.} do
    {
        if g_LoopDelegates:Events:Keys:Contains("OnDeploy_{0}":Format(i))
        {
            ExecGLoopEvents().
        }
        else
        {
            set execOnDeploy to false.
        }
    }
    wait 0.01.
}

set g_StageLimit to stageLimit.
if HasNode
{
        ExecNodeBurn_NextNext(NextNode, stageLimit).
}