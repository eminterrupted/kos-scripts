@lazyGlobal off.
clearScreen.

parameter params to list().
          
runOncePath("0:/lib/disp").
runOncePath("0:/lib/util").
runOncePath("0:/lib/vessel").

DispMain(scriptPath()).

local partList to list().

if params:length > 0
{
    set partList to params[0].
}

lock steering to ship:facing.

if partsToDeploy:length = 0 
{
    OutMsg("ERROR: No parts in list!").
}
else
{
    OutMsg("Deploying " + partList:length + " parts").
    DeployPartList(partList).
}

wait 1. 
OutInfo().
OutMsg("Deployment completed").