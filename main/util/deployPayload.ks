@lazyGlobal off.
clearScreen.

parameter params to list().
          
runOncePath("0:/lib/disp").
runOncePath("0:/lib/util").
runOncePath("0:/lib/vessel").

DispMain(scriptPath()).

// Declare params
local payloadStage to 0.
local deployParts to false.
local deployType to "".


if ship:rootPart:tag:split("|"):length > 1 
{
    set payloadStage to ship:rootpart:tag:split("|")[1].
}

if params:length > 0
{
    set payloadStage to params[0].
    if params:length > 1 set deployType to params[1].
}

if deployType:length > 0 set deployParts to true.

lock steering to ship:facing.

OutWait("Preparing for payload deployment", 3).

ag9 off.
// Payload deployment
OutMsg("Staging payload").
until stage:number = payloadStage 
{
    if stage:ready stage.
    wait 0.5.
}

if deployParts
{
    OutMsg("Part deployment in progress").
    if Ship:PartsTaggedPattern(deployType + ".*\.\d*"):length > 0
    {
        OutMsg("Deploying parts tagged: " + deployType).
        DeployPartSet(deployType, "deploy").
    }
    OutInfo().
}

wait 1. 
OutInfo().
OutMsg("Deployment completed").