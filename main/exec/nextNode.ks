@LazyGlobal off.
ClearScreen.

RunOncePath("0:/lib/libLoader.ks").

if HasNode
{
    ExecNodeBurn(NextNode).
}