@lazyGlobal off.
clearScreen.

parameter numNodes to -1.

runOncePath("0:/lib/burnCalc").
runOncePath("0:/lib/disp").
runOncePath("0:/lib/mnv").
runOncePath("0:/lib/util").
runOncePath("0:/lib/vessel").

runOncePath("0:/lib/globals").

DispMain(scriptPath(), false).

if hasNode 
{
    if numNodes = -1
    {
        OutTee("Executing all maneuvers in flight plan").
        until not HasNode
        {
            OutTee("Executing next node").
            ExecNodeBurn(nextNode).
        }
    }
    else
    {
        OutTee("Executing next " + numNodes + " maneuvers in flight plan").
        local nodeCount to 1.
        until nodeCount >= numNodes
        {
            OutTee("Executing next node (" + nodeCount + "/" + numNodes +")").
            ExecNodeBurn(nextNode).
        }
    }

    OutTee("execMultiNode complete!").
}
else
{
    OutTee("No maneuver node present!", 2).
}