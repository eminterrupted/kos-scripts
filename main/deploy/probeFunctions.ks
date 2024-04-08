@LazyGlobal off.
ClearScreen.

parameter _params is list().

// Dependencies
RunOncePath("0:/lib/depLoader.ks").
RunOncePath("0:/lib/sci.ks").

// Declare Variables
local antennaModules  to Ship:ModulesNamed("ModuleDeployableAntenna").
local deployAntenna   to antennaModules:Length > 0.
local antennaDelegate to { for m in antennaModules {DoEvent(m, "extend antenna").}}.

local solarModules to Ship:ModulesNamed("ModuleROSolar").
local deploySolar   to solarModules:Length > 0.
local antennaDelegate to { for m in antennaModules {DoEvent(m, "extend antenna").}}.

local deployList to choose _params if _params:length > 0 else list("solar", "antenna").

for depType in deployList
{
    
}

if deployAntenna
{
}
