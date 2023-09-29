@LazyGlobal Off.
ClearScreen.

parameter params is list().

RunOncePath("0:/lib/libLoader.ks").

DispMain(ScriptPath(), false).

local minTimeToTransfer to 0.
local tgtAlt to 100000.

if params:Length > 0
{
    set minTimeToTransfer to ParseStringScalar(params[0]).
    if params:Length > 1 set tgtAlt to ParseStringScalar(params[1]).
}

until not HasNode
{
    Remove NextNode.
    wait 0.01.
}

OutMsg("Adding node").
local myNode to AddLunarTransferNode(minTimeToTransfer, tgtAlt).

Breakpoint().