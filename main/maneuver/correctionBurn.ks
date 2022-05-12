@lazyGlobal off.
clearScreen.

parameter params is list().

runOncePath("0:/lib/burnCalc").
runOncePath("0:/lib/disp").
runOncePath("0:/lib/mnv").
runOncePath("0:/lib/util").
runOncePath("0:/lib/vessel").
runOncePath("0:/lib/globals").

DispMain(scriptPath(), false).

if hasNode 
{
    ExecNodeBurn(nextNode).
}
else
{
    OutTee("No maneuver node present!", 2).
}