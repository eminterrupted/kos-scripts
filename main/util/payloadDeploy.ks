@lazyGlobal off.
clearScreen.

parameter params to list().
          
runOncePath("0:/lib/disp").
runOncePath("0:/lib/util").
runOncePath("0:/lib/vessel").

DispMain(scriptPath()).

local autoStage to true.
local deployType to "payloadDeploy".
local payloadStage to 0.

if ship:rootPart:tag:split("|"):length > 1 
{
    set payloadStage to ship:rootpart:tag:split("|")[1].
}

if params:length > 0
{
    set autoStage to params[0].
    if params:length > 1 set deployType to params[1].
    if params:length > 2 set payloadStage to params[2].
}

lock steering to ship:facing.

if autoStage
{
    OutWait("Preparing for payload deployment", 5).

    ag9 off.
    // Payload deployment
    OutMsg("Staging payload").
    until stage:number = payloadStage 
    {
        if stage:ready stage.
        wait 0.5.
    }
} 
else
{
    OutTee("payloadDeploy: No staging").
    wait 0.25.
}

local partsToDeploy to ship:partstaggedpattern(deployType + ".*").
if partsToDeploy:length > 0
{
    OutMsg("Deploying parts tagged: " + deployType).
    DeployPartSet(deployType, "deploy").
}
OutInfo().

// When called with no param, it deploys the untagged parts
OutMsg("Deploying untagged parts").
DeployPartSet().

wait 1. 
OutInfo().
OutMsg("Deployment completed").