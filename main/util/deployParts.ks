@lazyGlobal off.
clearScreen.

parameter params to list().
          
runOncePath("0:/lib/disp").
runOncePath("0:/lib/util").
runOncePath("0:/lib/vessel").

DispMain(scriptPath()).

local deployStr to "".
local deployType to "".

if params:length > 0
{
    set deployType to params[0].
}

lock steering to ship:facing.

if deployType = "" 
{
    // When called with no param, it deploys the untagged parts
    OutMsg("Deploying untagged parts").
    DeployPartSet().
}
else
{
    set deployStr to deployType + "Deploy.*".

    local partsToDeploy to ship:partstaggedpattern(deployStr).
    if partsToDeploy:length > 0
    {
        OutMsg("Deploying parts tagged: " + deployType).
        DeployPartSet(deployType + "Deploy", "deploy").
    }
    OutInfo().
}

wait 1. 
OutInfo().
OutMsg("Deployment completed").