@LazyGlobal off.
ClearScreen.

Parameter params is list().

RunOncePath("0:/lib/disp").
RunOncePath("0:/lib/sci").
RunOncePath("0:/lib/util").
RunOncePath("0:/lib/vessel").

DispMain(ScriptPath(), false).

local sciAction to "transmit".

if params:length > 0 
{
    set sciAction to params[0].
}

if ship:partsTaggedPattern("srfSciDeploy."):length > 0 
{
    DeployPartSet("srfSciDeploy", "deploy").
}

local sciList to GetSciModules().
ClearSciList(sciList).
DeploySciList(sciList).
RecoverSciList(sciList, sciAction).

OutMsg("Science collection completed from " + Ship:Body:Name + "'s " + AddOns:Scansat:GetBiome(Ship:Body, Ship:GeoPosition)).
wait 1.