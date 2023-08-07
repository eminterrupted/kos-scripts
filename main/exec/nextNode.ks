@LazyGlobal off.
ClearScreen.

RunOncePath("0:/lib/libLoader.ks").

DispMain(ScriptPath()).

if HasNode
{
    ExecNodeBurn(NextNode).
}