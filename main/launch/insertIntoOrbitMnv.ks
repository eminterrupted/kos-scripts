@LazyGlobal off.
ClearScreen.

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
RunOnDeploySubroutine(deployParts).

// RunOnDeploySubroutine
global function RunOnDeploySubroutine
{
    parameter _parts is Ship:PartsTaggedPattern("OnDeploy").

    if _parts:Length > 0
    {
        local partLex to lexicon().
        for p in _parts
        {
            local tagSplit to p:Tag:Split("|").
            local partSequence to choose tagSplit[tagSplit:Length - 1] if tagSplit:Length > 1 else 0.
            if not partLex:HasKey(partSequence)
            {
                partLex:Add(partSequence, list(p)).
            }
            else
            {
                partLex[partSequence]:Add(p).
            }
        }

        from { local i to 0.} until i = partLex:Keys:Length step { set i to i + 1.} do
        {
            local partsInSequence to partLex:Values[i].
            for p in partsInSequence
            {
                if p:HasModule("Experiment")
                {
                    DoExperiment(p, 1).
                }
                if p:HasModule("ModuleDeployableAntenna")
                {
                    DeployAntenna(p:GetModule("ModuleDeployableAntenna")).
                }
            }
        }
    }
}

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