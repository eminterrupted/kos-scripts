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

local maxDeployStep to 0.
local partsToDeploy to ship:partstaggedpattern("payloadDeploy.*").
if partsToDeploy:length > 0
{
    for p in partsToDeploy
    {
        if p:tag:split(".")[1]:toNumber(0) > maxDeployStep set maxDeployStep to p:tag:split(".")[1].
    }
    OutMsg("Deploying orbital apparatus.").
    from { local idx to 0.} until idx > maxDeployStep step { set idx to idx + 1.} do {
        OutInfo("Step: " + idx).
        DeployPayloadParts(ship:partsTaggedPattern("payloadDeploy." + idx)).
        wait 2.
    }
    wait 2.5.
}
OutInfo().
local unTaggedParts to list().
for p in ship:parts { 
    if p:tag = "" untaggedParts:add(p).
}
OutInfo("Untagged").
DeployPayloadParts(untaggedParts).
wait 2.5. 
OutInfo().
OutMsg("Deployment completed").