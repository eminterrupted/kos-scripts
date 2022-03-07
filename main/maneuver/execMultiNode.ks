@lazyGlobal off.
clearScreen.

Parameter param is list().

runOncePath("0:/lib/burnCalc").
runOncePath("0:/lib/disp").
runOncePath("0:/lib/mnv").
runOncePath("0:/lib/util").
runOncePath("0:/lib/vessel").
runOncePath("0:/lib/globals").

DispMain(ScriptPath()).

local execCount to 2.

if param:Length > 0 
{
    set execCount to param[0].
}

local localScript to "1:/execNode".

copyPath("0:/main/maneuver/execNode", localScript).

from { local execId to 1.} until execId = execCount step { set execId to execId + 1.} do 
{
    OutMsg("Executing node: " + execId).
    runpath(localScript).
    OutMsg("Executing next node in sequence").
    wait 2.
}
