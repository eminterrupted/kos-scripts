@LazyGlobal off.
ClearScreen.

parameter _params is list().

// Dependencies
RunOncePath("0:/lib/depLoader.ks").
RunOncePath("0:/lib/sci.ks").

local deployParams to choose _params if _params:length > 0 else list("antenna", "solar").
local antennaModName to "ModuleDeployableAntenna".
local solarModName to "ModuleROSolar".

if deployParams[0]:MatchesPattern("onDeploy|onPayload")
{
    local OnDeployParts to Ship:PartsTaggedPattern("(OnDeploy|OnPayload)\|\d*").

    if OnDeployParts:Length > 0
    {
        from { local dStep to 0. local DoneFlag to False.} until dStep >= OnDeployParts:Length or DoneFlag step { set dStep to dStep + 1.} do
        {
            local stepParts to Ship:PartsTaggedPattern("(OnDeploy|OnPayload)\|" + dStep).
            for p in stepParts
            {
                if p:HasModule(antennaModName)
                {
                    local m to p:GetModule(antennaModName).
                    DoEvent(m, "extend antenna").
                }
                if p:HasModule(solarModName) 
                {
                    local m to p:GetModule(solarModName).
                    DoEvent(m, "extend solar panel").
                }
            }
            wait 1.25.
        }
    }
}
else
{
    // Declare Variables
    local antennaModules  to Ship:ModulesNamed(antennaModName).
    local doAntenna       to antennaModules:Length > 0.

    local solarModules    to Ship:ModulesNamed(solarModName).
    local doSolar         to solarModules:Length > 0.

    if solarModules:Length > 0
    {
        for m in solarModules
        {
            DoEvent(m, "extend solar panel").
        }
        wait 1.25.
        for m in antennaModules
        {
            DoEvent(m, "extend solar panel").
            
        }
    }
}
