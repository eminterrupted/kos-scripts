@LazyGlobal off.
ClearScreen.

parameter _params is list().

// Dependencies
RunOncePath("0:/lib/depLoader").
RunOncePath("0:/lib/mnv").

// Parse Params
if _params:length > 0 
{
  SetStageLimit(ParseStringScalar(_params[0], 0)).
}
else
{
    SetStageLimit(0).
}

set g_ShipEngines to GetShipEnginesSpecs(Ship).

SAS off.

OutMsg("Executing all nodes in flight plan").
wait 0.1.
until not HasNode
{
    local nodeToExec to choose NextNode if HasNode else node(0, 0, 0, 0).
    if nodeToExec:DeltaV:Mag < 0.1 and nodeToExec:DeltaV:Mag > -0.1
    {
        OutMsg("Burn too small, try RCS").
    }
    else
    {
        ExecNodeBurn(nodeToExec).
    }
    wait 1.
}

OutMsg("Node burn complete", cr()).