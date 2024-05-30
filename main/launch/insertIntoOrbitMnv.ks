@LazyGlobal off.
ClearScreen.

RunOncePath("0:/lib/deploy.ks").

parameter _params is list().

if Career():CanMakeNodes
{
    RunPath("0:/main/launch/mnvIntoOrbit", _params).
}
else
{
    RunPath("0:/main/launch/insertIntoOrbit", _params).
}

local deployParts to Ship:PartsTaggedPattern("OnDeploy").
RunDeployRoutine(deployParts).

// DoExperiment
global function DoExperiment
{
    parameter _part,
              _actionIdx is 1,
              _experimentType is "all".

    local _actionStr to choose "stop" if _actionIdx = 0 else choose "start" if _actionIdx = 1 else "".
    if _experimentType <> "all"
    {
        set _actionStr to "{0}: {1}":format(_actionStr, _experimentType).
    }

    if _actionStr:Length > 0
    {
        from { local mIdx to 0.} until mIdx = _part:Modules:Length step { set mIdx to mIdx + 1.} do
        {
            local m to _part:GetModuleByIndex(mIdx).
            if m:Name = "Experiment"
            {
                for a in m:AllActionNames
                {
                    if a:Contains(_actionStr)
                    {
                        DoAction(m, a).
                        wait 0.25.
                    }
                }
            }
        }
    }
}