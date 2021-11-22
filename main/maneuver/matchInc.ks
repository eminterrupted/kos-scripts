@lazyGlobal off.
clearScreen.

parameter tgt is target.

runOncePath("0:/lib/disp").
runOncePath("0:/lib/burnCalc").
runOncePath("0:/lib/mnv").
runOncePath("0:/lib/nav").
runOncePath("0:/lib/util").
runOncePath("0:/lib/vessel").

DispMain(scriptPath(), false).

local mnvNode to IncMatchBurn(ship, ship:orbit, tgt:orbit, true)[2].
add mnvNode.
ExecNodeBurn(mnvNode).

OutHUD("Match Inclination Burn Complete").