// #include "0:/lib/depLoader.ks"
@LazyGlobal off.

// *~ Dependencies ~* //
// #region
// #endregion


// *~ Variables ~* //
// #region
    // *- Global
    // #region
    global g_StateCache to "".
    // #endregion
    
    // *- Local
    // #region
    // #endregion

    // *- Global Anonymous Delegates
    // #region
    // #endregion

    // *- Local Anonymous Delegates
    // #region
    // #endregion
// #endregion


// *~ Functions ~* //
// #region

    // * Mission plan parsing / processing
    // #region

        // ListMissionPlans :: -> (_missionPlans)<List>
        global function ListMissionPlans
        {
            set g_MissionPlans to List(
                // "sounder"
                // ,"sounderReturn"
                // ,"downrange"
                // ,"suborbital"
                // ,"orbital"
            ).

            if Volume(0):Files:HasSuffix("_plan")
            {
                local planPath to Volume(0):Files:_plan.

                for plan in planPath:lex:keys
                {
                    for plan_l2 in planPath:Lex[plan]:Lex:Values
                    {
                        if plan_l2:Extension = "amp"
                        {
                            local planId to plan_l2:Name:Replace(".amp","").
                            if not g_MissionPlans:Contains(planId) 
                            {
                                g_MissionPlans:Add(planId).
                            }
                        }
                    }                  
                }
            }

            return g_MissionPlans.
        }

        // GetMissionPlan
        global function GetMissionPlan
        {
            parameter _planId.

            local planBase to _planId:Split("_")[0].
            // local planVer  to choose _planId:Split("_")[1] if _planId:Split("_"):Length > 1 else 0.
            local plan to lex("M", list(), "P", list()).

            if g_MissionPlans:Contains(_planId)
            {
                if _planId:Split("_"):Length > 1
                {
                    set planBase to _planId:Split("_")[0].
                    // set planVer  to _planId:Split("_")[1].
                }
            }

            local planFolder to Volume(0):Files:_plan:Lex[planBase].
            local planFileName to "{0}.amp":Format(_planId).
            if planFolder:List:Keys:Contains(planFileName)
            {
                local planFile to planFolder:List[planFileName].
                local planData to planFile:ReadAll:String:Split(char(10)). // Splits by newline 
                for mm in planData
                {
                    local mmSplit to mm:Split("|").
                    plan:M:Add(mmSplit[0]).
                    if mmSplit:length > 1
                    {
                        plan:P:Add(mmSplit[1]).
                    }
                    else
                    {
                        plan:P:Add("").
                    }
                }
            }
            else
            {

            }

            return plan.
        }



        // GetMissionPlanID :: [(_missionName)<String>] -> (_missionPlanID)
        // Returns a pointer to the mission plan of a vessel based on core tag and vessel name
        global function GetMissionPlanID 
        {
            local planId to "".
            local planPriorityList to list(
                core:tag
                ,Ship:Name:Replace(" ","_")
            ).

            from { local i to 0. local doneFlag to false. } until i = planPriorityList:Length or doneFlag step { set i to i + 1.} do 
            {
                if planPriorityList[i]:Length > 0
                {
                    set planId to planPriorityList[i].
                    if not planID:MatchesPattern("_")
                    {
                        set planID to planID + "_0".
                    }
                    print planId.
                    set doneFlag to true.
                }
            }
            
            if g_MissionPlans:Length = 0 ListMissionPlans().

            if g_MissionPlans:Contains(planID)
            {
                return planID.
            }
            else
            {
                return "-1".
            }
        }


    // #endregion


    // * State (Program / Runmode / Content) utilities
    // #region

    // CacheState
    global function CacheState
    {
        parameter _state is g_State.

        if g_StateCache:IsType("String") InitStateCache().

        g_StateCache:Clear.
        g_StateCache:Write(_state:join(",")).

        return Exists(g_StateCachePath).
    }

    // InitStateCache
    global function InitStateCache
    {
        parameter _resetState to false.

        local state to list(
            // 0    // Context (current running program module)
            // ,0    // Program
            // ,0    // Runmode
        ).

        if exists(g_StateCachePath) and not _resetState
        {
            for stateStr in Open(g_StateCachePath):ReadAll:String:Split(",")
            {
                state:Add(stateStr:ToNumber(0)).
            }
        }
        else
        {
            set state to list(0, 0, 0).
            log state:join(",") to g_StateCachePath.
        }
        set g_StateCache to Open(g_StateCachePath).
        set g_State to state.

        return Exists(g_StateCachePath).
    }

    // ReadStateCache
    global function ReadStateCache
    {
        if exists(g_StateCachePath)
        {
            return Open(g_StateCachePath):ReadAll:String:Split(",").
        }
        return list(-1,-1,-1).
    }



    // #endregion


    // * Terminal Input
    // #region

        // CheckTermChar :: (Char to check)<TerminalInput> -> (Match)<bool>
        // Returns the boolean result of a check of the provided value against g_TermChar. 
        // _updateGlobal will set g_TermChar to the next char in the queue for comparison if available
        // With _updateGlobal flag set, no need to call GetTermChar() first
        global function CheckTermChar
        {
            parameter _char,
                    _updateGlobal is False.

            if _updateGlobal
            {
                GetTermChar().
            }
            local result to _char = g_TermChar.
            return result.
        }

        // GetTermChar :: (none) -> (Was new char present)<bool>
        // Checks to see if a terminal character is present. 
        // If yes, set g_TermChar to it and return true.
        global function GetTermChar
        {
            if Terminal:Input:HasChar 
            { 
                until not Terminal:Input:HasChar
                {
                    set g_TermChar to Terminal:Input:GetChar.
                    g_TermQueue:Push(g_TermChar).
                }
                set g_TermHasChar to True.
                Terminal:Input:Clear().
            }
            // else
            // {
            //     set g_TermHasChar to False.
            // }
            return g_TermHasChar.
        }


    // #endregion

    // * Addon Wrappers
    // #region

    // *- Career
    // #region

        // TryRecoverVessel :: [_ves<Ship>], [_recoveryWindow<Scalar>] -> <None>
        global function TryRecoverVessel
        {
            parameter _ves is Ship,
                    _recoveryWindow is 30.

            if Addons:Available("Career")
            {
                local waitTimer to 3.
                set g_TS to Time:Seconds + waitTimer.
                // TODO local waitStr to "Waiting until {0,-5}s to begin recovery attempts".
                set g_TermChar to "".
                // TODO:  OutInfo("Press any key to abort").
                local abortFlag to false.
                until Time:Seconds > g_TS or abortFlag
                {
                    // TODO OutMsg(waitStr:Format(Round(g_TS - Time:Seconds, 2))).
                    GetTermChar().
                    if g_TermChar <> ""
                    {
                        set abortFlag to true.
                        // TODO OutInfo().
                    }
                    wait 0.01.
                }

                if abortFlag 
                {
                    // TODO OutMsg("Aborting recovery attempts!").
                    wait 0.25.
                }
                else
                {
                    local getRecoveryState to { parameter __ves is Ship. if Addons:Career:IsRecoverable(__ves) { return list(True, "++REC").} else { return list(False, "UNREC").}}.
                    // TODO local recoveryStr to "Attempting recovery (Status: {0})".
                    set g_TS to Time:Seconds + _recoveryWindow.
                    // TODO local abortStr to "Press any key to abort ({0,-5}s)".
                    until Time:Seconds >= g_TS or abortFlag
                    {
                        local recoveryState to getRecoveryState:Call(_ves).
                        if recoveryState[0]
                        {
                            Addons:Career:RecoverVessel(_ves).
                            // TODO OutMsg("Recovery in progress (Status: {0})":Format(recoveryState[1])).
                            // TODO OutInfo().
                            wait 0.01.
                            break.
                        }
                        else
                        {
                            // TODO OutMsg(recoveryStr:Format(recoveryState[1])).
                            // TODO OutInfo(abortStr:Format(g_TS - Time:Seconds, 2)).

                            GetTermChar().
                            if g_TermChar <> ""
                            {
                                set abortFlag to true.
                            }
                            wait 0.01.
                        }
                    }
                    
                    if abortFlag
                    {
                        // TODO OutMsg("Recovery aborted!").
                        // TODO OutInfo().
                    }
                    else
                    {
                        // TODO OutMsg("Recovery failed. :(").
                    }
                    // TODO OutInfo().
                }
            }
            else
            {
                // TODO OutMsg("No recovery firmware found!").
                // TODO OutInfo().
                wait 0.25.
            }
        }
        // #endregion
    // #endregion

// #endregion