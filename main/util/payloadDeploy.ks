@lazyGlobal off.
clearScreen.

parameter params to list().
          
runOncePath("0:/lib/disp").
runOncePath("0:/lib/util").
runOncePath("0:/lib/vessel").

DispMain(scriptPath()).

local autoDeploy to true.
local payloadStage to 0.

if params:length > 0
{
    set autoDeploy to params[0].
    if params:length > 1 set payloadStage to params[1].
}

lock steering to ship:facing.

if ship:rootPart:tag:split("|"):length > 1 
{
    set payloadStage to ship:rootpart:tag:split("|")[1].
}

if not autoDeploy 
{
    OutTee("payloadDeploy: No-op").
    wait 0.25.
}
{
    OutWait("Preparing for payload deployment", 5).

    ag9 off.
    // Payload deployment
    OutMsg("Deploying payload").
    until stage:number = payloadStage 
    {
        if stage:ready stage.
        wait 0.5.
    }

    from { local idx to 0.} until idx = ship:rootpart:tag:split("|")[1]:tonumber - 1 step { set idx to idx + 1.} do {
        deployPayloadId(ship:partsTaggedPattern("payloadDeploy." + idx), idx).
        wait 2.
    }

    OutInfo().
    OutInfo("Deploying all remaining").
    deployPayloadId(ship:parts, "*").
    OutMsg("Deployment completed").
}


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
