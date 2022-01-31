@lazyGlobal off.
clearScreen.

parameter params to list().
          
runOncePath("0:/lib/disp").
runOncePath("0:/lib/util").
runOncePath("0:/lib/vessel").

DispMain(scriptPath()).

local autoStage to true.
local payloadStage to 0.

if ship:rootPart:tag:split("|"):length > 1 
{
    set payloadStage to ship:rootpart:tag:split("|")[1].
}

if params:length > 0
{
    set autoStage to params[0].
    if params:length > 1 set payloadStage to params[1].
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

local partsToDeploy to ship:partstaggedpattern("payloadDeploy.*").
if partsToDeploy:length > 0
{
    DeployPartSet("payloadDeploy", "deploy").
}
OutInfo().

// When called with no param, it deploys the untagged parts
DeployPartSet().

wait 2.5. 
OutInfo().
OutMsg("Deployment completed").