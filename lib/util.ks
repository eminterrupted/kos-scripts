// #include "0:/lib/depLoader.ks"
@LazyGlobal off.

// *~ Dependencies ~* //
// #region
// #endregion


// *~ Variables ~* //
// #region
    // *- Global Variables
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

    // *- Reference Objects
    // #region
    global g_SpaceStr to lex(
         0, ""
        ,1, " "
        ,2, "  "
        ,3, "   "
        ,4, "    "
        ,5, "     "
        ,6, "      "
        ,7, "       "
        ,8, "        "
        ,9, "         "
        ,10,"          "
        ,11,"           "
        ,12,"            "
        ,13,"             "
        ,14,"              "
        ,15,"               "
        ,16,"                "
        ,17,"                 "
        ,18,"                  "
        ,19,"                   "
        ,20,"                    "
        ,21,"                     "
        ,22,"                      "
        ,23,"                       "
        ,24,"                        "
        ,25,"                         "
        ,26,"                          "
        ,27,"                           "
        ,28,"                            "
        ,29,"                             "
        ,30,"                              "
        ,31,"                               "
        ,32,"                                "
        ,33,"                                 "
        ,34,"                                  "
        ,35,"                                   "
        ,36,"                                    "
        ,37,"                                     "
        ,38,"                                      "
        ,39,"                                       "
        ,40,"                                        "
        ,41,"                                         "
        ,42,"                                          "
        ).
    // #endregion
    
// #endregion


// *~ Functions ~* //
// #region

// *- Basic utilities
// #region

    // Breakpoint :: <_msg>
    // Halts execution until any key is pressed
    global function Breakpoint
    {
        parameter _msg is "*** PRESS ANY KEY TO CONTINUE ***".

        local pad  to Floor((Terminal:Width - _msg:Length) / 2).
        local padStr to choose g_SpaceStr[pad] if pad <= g_SpaceStr:Keys:Length - 1 else NewBlankString(pad).


        local msgStr to "{0}{1}{0}".
        print msgStr:Format(padStr, _msg) at (0, Terminal:Height - 3).
        Terminal:Input:Clear.
        Terminal:Input:GetChar.

        local blankStr to NewBlankString(Terminal:Width).
        print msgStr:Format(padStr, blankStr) at (0, Terminal:Height - 3).
    }

// #endregion

// *- Mission plan parsing / processing
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
            local plan to lex("M", list(), "P", list(), "S", list()).

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
                    if mmSplit:length > 2
                    {
                        plan:S:Add(mmSplit[2]).
                    }
                    else
                    {
                        plan:S:Add(g_StageStop).
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


// *- Part Module utilities
// #region

    // PMDoAction :: TODO

    // PMDoEvent :: TODO

    // PMGetField :: <_module>, <_fieldName>, [<_fallbackValue>] -> <fieldValue>
    // Protected method of retrieving a field from a part module. 
    // Will fallback to a provided or default value if the field does not exist
    global function PMGetField
    {
        parameter _module,
                _fieldName,
                _fallbackValue is "FNA".

        if _module:HasField(_fieldName)
        {
            return _module:GetField(_fieldName).
        }
        else
        {
            return _fallbackValue.
        }
    }

// #endregion


// *- State (Program / Runmode / Content) utilities
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
            //  0    // Context (current running program module)
            // ,0    // Program
            // ,0    // Runmode
            // ,0    // StageStop
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
            set state to list(0, 0, 0, 0).
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
        return list(-1,-1,-1,0).
    }


    // SetContext
    global function SetContext
    {
        parameter _context is 0,
                  _update is false.

        set g_Context to _context.
        if _update UpdateState().
        return g_Context.
    }


    // SetProgram
    global function SetProgram
    {
        parameter _prog is 0,
                  _update is false.

        set g_Program to _prog.
        set g_Runmode to 0.
        if _update UpdateState().
        return g_Program.
    }

    // SetRunmode
    global function SetRunmode
    {
        parameter _rm is 0,
                  _update is false.

        set g_Runmode to _rm.
        if _update UpdateState().
        return g_Runmode.
    }

    // SetStageStop
    global function SetStageStop
    {
        parameter _stgStop is Stage:Number,
                  _update is false.

        set g_StageStop to _stgStop.
        if _update UpdateState().
        return g_StageStop.
    }


    // UpdateState
    global function UpdateState
    {
        parameter _cacheEnable to false.

        set g_State to list (
            g_Context,
            g_Program,
            g_Runmode,
            g_StageStop
        ).

        if _cacheEnable 
        {
            CacheState().
        }
    }



// #endregion


// *- Terminal Input
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


        // NewBlankString :: _chars<int> -> _newStr<string>
        local function NewBlankString
        {
            parameter _width to 0.

            local padRem to _width.
            local newStr to "". 
            until padRem <= g_SpaceStr:Keys:Length - 1 
            {
                set newStr to newStr + g_SpaceStr:Values[g_SpaceStr:Values:Length - 1].
                set padRem to padRem - g_SpaceStr:Keys[g_SpaceStr:Keys:Length - 1].
            }
            if padRem >= 0
            {
                set newStr to newStr + g_SpaceStr[padRem].
            }
            
            return newStr. 
        }

    // #endregion

// *- Addon Wrappers
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