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
        "wt", GetDeployWaitTime@
        ,"rot", GetIRDeployPosition@
        ,"r"  , GetIRDeployPosition@
        ,"tgt", GetIRDeployPosition@
        ,"t"  , GetIRDeployPosition@
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
                  _operator is "p+".

        local cachedLock to False.
        if _m:HasField("lock")
        {
            set cachedLock to _m:GetField("lock").
            _m:SetField("lock", False).
        }
        wait 0.01.

        if _operator:StartsWith("sv:") set _operator to _operator:Replace("sv:","").

        if _operator:Contains("p+")
        {
            return DoAction(_m, "Move To Next Preset", True).
        }
        else if _operator:Contains("p-")
        {
            return DoAction(_m, "Move To Previous Preset", True).
        }
        else if _operator:Contains("c")
        {
            return DoAction(_m, "Move Center", True).
        }
        else if _operator:MatchesPattern("t(gt)?:\d+")
        {
            return _m:SetField("Target Position", _operator:ToNumber(0)).
        }
        else if _operator:MatchesPattern("r(ot)?:\d*")
        {
            return _m:SetField("Set Rotation", _operator:ToNumber(0)).
        }

        until _m:GetField("Current Position") = _m:GetField("Target Position")
        {
            OutInfo("Moving Servo [{0}/{1}]   ":Format(Round(_m:GetField("Current Position"), 3), _m:GetField("Target Position"))).
        }

        wait 0.01.
        if _m:HasField("lock")
        {
            _m:GetField("lock", cachedLock).
        }
    }

    // GetIRDeployPosition :: <tag fragment>_waitTag -> <scalar>position
    local function GetIRDeployPosition
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

    // RunOnDeployRoutine :: (input params)<type> -> (output params)<type>
    // Description
    global function RunDeployRoutine
    {
        parameter _deployTag is "OnDeploy".

        OutInfo("RunDeployRoutine: _deployTag {0}":Format(_deployTag)).

        if Ship:PartsTaggedPattern(_deployTag + ".*"):Length > 0
        {
            OutInfo("Parts found for tag", 1).
            wait 1.
            from { local i to 0. local doneFlag to False.} until doneFlag step { set i to i + 1.} do
            {
                OutInfo("Processing Tag Number {0}":Format(i), 1).
                local partList to Ship:PartsTaggedPattern("{0}\|(.*\|)*{1}":Format(_deployTag, i)).

                if partList:Length = 0
                {
                    OutInfo("Parts Remaining for {0}: 0":Format(i), 1).
                    set doneFlag to True.
                }
                else
                {
                    local actionLex to lexicon("wt", 0.5).
                    
                    for p in partList
                    {
                        OutInfo("Processing {0} parts for {1}":Format(partList:Length, i), 1).
                        local tagSplit to p:Tag:Replace(_deployTag + "|",""):Split("|").
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
                            for tagLine in tagSplit
                            {
                                local tagFrags to tagLine:Split(";").
                                from { local _i to 0. } until _i = tagFrags:Length step { set _i to _i + 1.} do 
                                {
                                    local tagFragment to tagFrags[_i].
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
                                    else
                                    {
                                        if deployDelegates:HasKey(tagFragment)
                                        {
                                            if actionLex:HasKey(tagFragment)
                                            {
                                                deployDelegates[tagFragment]:Call(actionLex, tagFragment).
                                            }
                                            else
                                            {
                                                actionLex:Add(tagFragment, deployDelegates[tagFragment]:Call(tagFragment)).
                                            }
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
                            DoAction(p:GetModule("ModuleROSolar"), "extend solar panel", True).
                        }
                        if p:HasModule("ModuleIRServo_v3")
                        {
                            local functionTag to "p+".
                            // local tagParts to p:Tag:Split("|").
                            // local functionTagList to tagParts:Split(";").
                            local functionTagList to tagSplit[0]:Split(";").
                            for frag in functionTagList 
                            {
                                if frag:MatchesPattern("sv:.*") 
                                {
                                    set functionTag to frag:replace("sv:","").
                                }
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
            //             DoAction(p:GetModule("ModuleROSolar"), "extend solar panel", True).
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