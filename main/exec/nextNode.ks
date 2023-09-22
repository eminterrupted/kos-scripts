@LazyGlobal off.
ClearScreen.

RunOncePath("0:/lib/libLoader.ks").

DispMain(ScriptPath()).

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

if HasNode
{
    ExecNodeBurn(NextNode).
}