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
  set nodeToExec to choose _params[0] if _params[0]:TypeName = "Node" else nodeToExec.
}

set g_ShipEngines to GetShipEnginesSpecs(Ship).

SAS off.

set g_StageLimit to 0.
ExecNodeBurn(nodeToExec).

OutMsg("Node burn complete", cr()).