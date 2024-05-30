@LazyGlobal off.
ClearScreen.

parameter _params is list().

// Dependencies
RunOncePath("0:/lib/depLoader").
RunOncePath("0:/lib/mnv").

// Declare Variables
local nodeToExec to choose NextNode if HasNode else node(0, 0, 0, 0).

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
    if nodeToExec:DeltaV < 0.1 and nodeToExec:DeltaV > -0.1
    {
        ExecNodeBurn(nodeToExec).
    }
    wait 1.
}

OutMsg("Node burn complete", cr()).