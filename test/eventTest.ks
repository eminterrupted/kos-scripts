@lazyGlobal off.
clearScreen.

parameter params is list().

runOncePath("0:/lib/loadDep").

DispMain(scriptPath(), false).

global stgDelegates to lex().
local pyldDepRoutine to { DeployPartSet("payload"). }.
local pyldStg to 0.
set stgDelegates[pyldStg] to pyldDepRoutine@.

if stgDelegates:keys:length > 0 
{
    OutMsg("Awaiting staging event...").
    on stage:number
    {
        OutMsg("Staging detected!").
        if stgDelegates:hasKey(stage:number)
        {
            OutInfo("Executing subroutine for stage: {0}":format(stage:number)).
            stgDelegates[stage:number]:call().
            stgDelegates:remove(stage:number).
        }

        if stage:number > 0 and stgDelegates:keys:length > 0
        {
            OutMsg("Awaiting staging event...").
            OutInfo("Preserving trigger").
            preserve.
        }
        else
        {
            OutMsg("Staging monitoring complete!").
            OutInfo().
        }
    }

    until stgDelegates:keys:length = 0
    {
        DispGeneric(list("staging status","<br>","CUR STAGE", stage:number, "DEL COUNT", stgDelegates:keys:length), 10).
        wait 0.01.
    }
}