@lazyGlobal off.
clearScreen.

parameter params to list().
          
runOncePath("0:/lib/disp").
runOncePath("0:/lib/util").
runOncePath("0:/lib/vessel").

DispMain(scriptPath()).

local deploySet to "".
local deployType to "deploy".

if params:length > 0
{
    set deploySet to params[0].
    if params:length > 1 set deployType to params[1].
}

lock steering to ship:facing.

if deploySet = "" 
{
    // When called with no param, it deploys the untagged parts
    OutMsg("Deploying untagged parts").
    DeployPartSet().
}
else
{
    local regEx to deploySet + ".*\.{1}\d+".
    if Ship:PartsTaggedPattern(regEx):Length > 0
    {
        OutMsg("Deploying '" + deploySet + "' partSet").
        DeployPartSet(deploySet, deployType).
    }
    OutInfo().
}

wait 1. 
OutInfo().
OutMsg("Deployment completed").