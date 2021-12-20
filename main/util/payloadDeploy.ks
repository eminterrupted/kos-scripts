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
for p in ship:partstaggedpattern("payloadDeploy.*")
{
    if p:tag:split(".")[1]:toNumber(0) > maxDeployStep set maxDeployStep to p:tag:split(".")[1].
}

from { local idx to 0.} until idx > maxDeployStep step { set idx to idx + 1.} do {
    deployPayloadId(ship:partsTaggedPattern("payloadDeploy." + idx), idx).
    wait 2.
}
wait 2.5.
OutInfo().
OutInfo("Deploying all remaining").
local unTaggedParts to list().
for p in ship:parts { 
    if p:tag = "" untaggedParts:add(p).
}
deployPayloadId(untaggedParts, "Untagged").
wait 5. 
OutMsg("Deployment completed").


// Local functions
// deployPayloadId :: <parts>, <int> | <none>
// Runs a step on the parts passed in
local function deployPayloadId
{
    parameter partsList,
            sequenceIdx.
    
    OutMsg("Deploying orbital apparatus.").
    OutInfo("Step: " + sequenceIdx).
    
    for p in partsList
    {
        if p:hasModule("ModuleAnimateGeneric")
        {
            local m to p:getModule("ModuleAnimateGeneric").
            DoEvent(m, "open").
        }
        
        if p:hasModule("ModuleRTAntenna")
        {
            local m to p:getModule("ModuleRTAntenna").
            DoEvent(m, "activate").
        }

        if p:hasModule("ModuleDeployableSolarPanel")
        {
            local m to p:getModule("ModuleDeployableSolarPanel").
            DoAction(m, "extend solar panel", true).
        }

        if p:hasModule("ModuleDeployablePart")
        {
            local m to p:getModule("ModuleDeployablePart").
            DoEvent(m, "extend").
        }
    }
}
