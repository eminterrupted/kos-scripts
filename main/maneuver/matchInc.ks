@lazyGlobal off.
clearScreen.

parameter param is list().

runOncePath("0:/lib/disp").
runOncePath("0:/lib/burnCalc").
runOncePath("0:/lib/mnv").
runOncePath("0:/lib/nav").
runOncePath("0:/lib/util").
runOncePath("0:/lib/vessel").

DispMain(scriptPath(), false).

local tgt to choose target if hasTarget else "".
local soonestNode to false.

if param:length > 0
{
    set tgt to GetOrbitable(param[0]).
    if param:length > 1 set soonestNode to param[1].
}

until not hasNode
{
    remove nextNode.
    wait 0.01.
}

local mnvNode to IncMatchBurn(ship, ship:orbit, tgt:orbit, soonestNode)[2].
add mnvNode.
ExecNodeBurn(mnvNode).

OutHUD("Match Inclination Burn Complete").