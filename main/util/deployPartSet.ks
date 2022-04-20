@lazyGlobal off.
clearScreen.

parameter params to list().
          
runOncePath("0:/lib/disp").
runOncePath("0:/lib/util").
runOncePath("0:/lib/vessel").

DispMain(scriptPath()).

local deployList to list().
local deployStr to "".
local partsToDeploy to list().

if params:length > 0
{
    set deployList to params[0].
}

lock steering to ship:facing.

for deployType in deployList
{
    if deployType = "" 
    {
        // When called with no param, it deploys the untagged parts
        OutMsg("Deploying untagged parts").
        DeployPartSet().
    }
    else
    {
        local regEx to deployType + ".*\.{1}\d+".
        if Ship:PartsTaggedPattern(regEx):Length > 0
        {
            OutMsg("Deploying '" + deployType + "' partSet").
            DeployPartSet(deployType, "deploy").
        }
        OutInfo().
    }
}

wait 1. 
OutInfo().
OutMsg("Deployment completed").