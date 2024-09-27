// #include "0:/lib/depLoader.ks"
// #include "0:/lib/sci.ks"
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
    local deployDelegates to lexicon(
        "w", GetDeployWaitTime@
    ).
    // #endregion

    // *- Global Anonymous Delegates
    // #region
    // #endregion
// #endregion


// ***~~~ Functions ~~~*** //
// #region

//  *- Deployment handlers
// #region

    // DeployAntenna
    global function DeployAntenna
    {
        parameter _m.

        return DoEvent(_m, "extend antenna").
    }

    // DeployAntennas (all in sequence)
    global function DeployAntennas
    {
        parameter _tagBranch to ".*",
                  _excludeBranch to "".

        if Ship:ModulesNamed("ModuleDeployableAntenna"):Length > 0
        {
            local commModules to Ship:ModulesNamed("ModuleDeployableAntenna").
            from { local i to commModules - 1. local doneFlag to False.} until doneFlag step { set i to i - 1.} do
            {
                local m to commModules[i].
                if m:Part:Tag:MatchesPattern(_tagBranch) and not m:Part:Tag:MatchesPattern(_excludeBranch)
                {
                    DoEvent(m, "extend antenna").
                }
            }
            return True.
        }
        else
        {
            return False.
        }
    }

    // DeployServo
    local function DeployServo
    {
        parameter _m,
                  _partTag is "p+".

        local cachedLock to False.
        if _m:HasField("lock")
        {
            set cachedLock to _m:GetField("lock").
            _m:GetField("lock").
        }

        if _partTag:StartsWith("sv:") set _partTag to _partTag:Replace("sv:","").

        if _partTag:Contains("p+")
        {
            return DoAction(_m, "Move To Next Preset", true).
        }
        else if _partTag:Contains("p-")
        {
            return DoAction(_m, "Move To Previous Preset", true).
        }
        else if _partTag:Contains("c")
        {
            return DoAction(_m, "Move Center", true).
        }
        else if _partTag:MatchesPattern("t\d+")
        {
            return _m:SetField("Target Position", _partTag:ToNumber(0)).
        }

        until _m:GetField("Current Position") = _m:GetField("Target Position")
        {
            OutInfo("Moving Servo [{0}/{1}]   ":Format(Round(_m:GetField("Current Position"), 3), _m:GetField("Target Position"))).
        }
        if _m:HasField("lock")
        {
            _m:GetField("lock", cachedLock).
        }
    }

    // RunOnDeployRoutine :: (input params)<type> -> (output params)<type>
    // Description
    global function RunDeployRoutine
    {
        parameter _deployTag is "OnDeploy".

        if Ship:PartsTaggedPattern(_deployTag):Length > 0
        {
            from { local i to 0. local doneFlag to false.} until doneFlag step { set i to i + 1.} do
            {
                local partList to Ship:PartsTaggedPattern("{0}(\|.*)*\|{1}":Format(_deployTag, i:ToString)).
                if partList:Length = 0
                {
                    set doneFlag to True.
                }
                else
                {
                    local actionLex to lexicon("wt", 0.5).
                    
                    for p in partList
                    {
                        local tagSplit    to p:Tag:Replace("OnDeploy|",""):Split("|").
                        if i = tagSplit:Length - 1
                        {
                            tagSplit:Remove(tagSplit:Length - 1).
                        }

                        // if partLex:HasKey(partSequence)
                        // {
                        //     partLex[partSequence]:Parts:Add(p).
                        // }
                        // else
                        // {
                        //     partLex:Add(partSequence, Lexicon("Parts", list(p))).
                        // }

                        if tagSplit:Length > 0
                        {
                            from { local _i to 0. } until _i = tagSplit:Length step { set _i to _i + 1.} do 
                            {
                                local tagFragment to tagSplit[_i].
                                if tagFragment:MatchesPattern("\w{1,3}:.+")
                                {
                                    local subTag to tagFragment:Split(":").
                                    if deployDelegates:HasKey(subTag[0])
                                    {
                                        if actionLex:HasKey(subTag[0])
                                        {
                                            deployDelegates[subTag[0]]:Call(actionLex, subTag[1]).
                                        }
                                        else
                                        {
                                            actionLex:Add(subTag[0], deployDelegates[subTag[0]]:Call(subTag[1])).
                                        }
                                    }
                                }
                            }
                        }

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
                        if p:HasModule("ModuleIRServo_v3")
                        {
                            local functionTag to "p+".
                            local functionTagList to p:Tag:Split("|").
                            for frag in functionTagList 
                            {
                                if frag:MatchesPattern("sv:.*") set functionTag to frag:replace("sv:","").
                            }
                            DeployServo(p:GetModule("ModuleIRServo_v3"), functionTag).
                        }

                    }
                    set g_TS to Time:Seconds + actionLex["wt"].
                    until Time:Seconds >= g_TS
                    {
                        OutInfo("Deployment sequence [{0}]: WAIT: {1}s  ":Format(i, Round(g_TS - Time:Seconds, 2))).
                    }
                }
            }

            // from { local i to 0.} until i = partLex:Keys:Length step { set i to i + 1.} do
            // {
            //     local partsInSequence to partLex:Values[i].
            //     for p in partsInSequence
            //     {
            //         if p:HasModule("Experiment")
            //         {
            //             DoExperiment(p, 1).
            //         }
            //         if p:HasModule("ModuleDeployableAntenna")
            //         {
            //             DeployAntenna(p:GetModule("ModuleDeployableAntenna")).
            //         }
            //         if p:HasModule("ModuleROSolar")
            //         {
            //             DoAction(p:GetModule("ModuleROSolar"), "extend solar panel", true).
            //         }
            //     }
            //     local waitTime to choose partLex:w if partLex:HasKey("w") else waitSecondsDefault.
                
            //     set g_TS to Time:Seconds + waitTime.
            //     until Time:Seconds >= g_TS
            //     {
            //         OutInfo("Deployment seuqence [{0}]: WAIT {1}s  ":Format(i, Round(g_TS - Time:Seconds, 2))).
            //     }
            //     OutInfo("Sequence deployment complete").
            // }
        }
    }

    // ProcessDeployWaitTime :: <tag fragment>_waitTag -> <scalar>waitSeconds
    local function GetDeployWaitTime
    {
        parameter _actionLex,
                  _tagValue.

        local waitSeconds to choose _tagValue if _tagValue:IsType("Scalar") else _tagValue:ToNumber(0).

        if _actionLex:HasKey("w")
        {
            if waitSeconds > _actionLex:w set _actionLex:w to waitSeconds.
        }
        else
        {
            _actionLex:Add("w", waitSeconds).
        }
        return _actionLex.
    }
    
// #endregion
// #endregion