// #include "0:/lib/depLoader.ks"
@LazyGlobal off.

// ***~~~ Dependencies ~~~*** //
// #region
// #endregion


// ***~~~ Variables ~~~*** //
// #region
    
    // *- Local
    // #region
    // #endregion

    // *- Global
    // #region
    // #endregion
// #endregion

// ***~~~ Delegate Objects ~~~*** //
    // *- Local Anonymous Delegates
    // #region
    // #endregion

    // *- Global Anonymous Delegates
    // #region
    // #endregion
// #endregion


// ***~~~ Functions ~~~*** //
// #region

//  *- Deployment handlers
// #region

    // RunOnDeployRoutine :: (input params)<type> -> (output params)<type>
    // Description
    global function RunDeployRoutine
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
                    if p:HasModule("ModuleROSolar")
                    {
                        DoAction(p:GetModule("ModuleROSolar"), "extend solar panel", true).
                    }
                }
            }
        }
    }
    
// #endregion
// #endregion