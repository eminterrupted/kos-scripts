@LazyGlobal off.
ClearScreen.

RunOncePath("0:/lib/deploy.ks").

parameter _params is list().

if Career():CanMakeNodes
{
    RunPath("0:/main/launch/insertOrbitMnv", _params).
}
else
{
    RunPath("0:/main/launch/circAtApo", _params).
}

local deployParts to Ship:PartsTaggedPattern("OnDeploy").
RunDeployRoutine(deployParts).