@lazyGlobal off.
clearScreen.

parameter params to list().
          
runOncePath("0:/lib/disp").
runOncePath("0:/lib/util").
runOncePath("0:/lib/vessel").

DispMain(scriptPath()).

// Declare params
local payloadStage to 0.
local deployParts to true.
local deployType to "payload".
local rcsOn to false.

if ship:rootPart:tag:split("|"):length > 1 
{
    set payloadStage to ship:rootpart:tag:split("|")[1].
}

if params:length > 0
{
    set payloadStage to params[0].
    if params:length > 1 set deployParts to params[1].
    if params:length > 2 set deployType to params[2].
    if params:length > 3 set rcsOn to params[3].
}

if deployType:length > 0 set deployParts to true.
if rcsOn 
{
    for m in ship:ModulesNamed("ModuleRCSFX")
    {
        m:SetField("rcs", true).
    }
    rcs on.
}
else
{
    rcs off.
}

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