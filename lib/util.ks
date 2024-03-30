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
    global g_NulCheckDel to { return true.}.
    global g_NulActionDel to { return list(false, { return true.}, { return false.}).}.
    // #endregion

    // *- Local Anonymous Delegates
    // #region
    // #endregion

    // *- Reference Objects
    // #region
    global g_Conditions to lexicon(
        "MINTHR",  { parameter __checkVal. return Ship:AvailableThrust < __checkVal and throttle > 0.}
        ,"MECOTS", { parameter __checkVal. return MissionTime >= __checkVal         and throttle > 0.}
        ,"MET",    { parameter __checkVal. return MissionTime >= __checkVal.}
        ,"TS",     { parameter __checkVal. return Time:Seconds >= __checkVal.}
    ).
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


// ## Stock code that needs to run everywhere
set g_MissionPlans to ListMissionPlans().



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

    // NoOp - just passes the existing value back. Not very useful except when it is.
    global function NoOp
    {
        parameter _p is false.

        return _p.
    }

// #endregion

// *- File handling functions
// #region

    // 
    global function GetFileTimeRT
    {
        parameter _realtimeSecs is Kuniverse:Realtime.

        // local _2024TS to 1704067200.
        local   dateSpan to Timespan(_realtimeSecs - 1704067200).

        return "{0}-{1}_{2}{3}{4}":Format((2024 + dateSpan:Year) - 2000, dateSpan:Day, dateSpan:Hour, dateSpan:Minute, dateSpan:Second).
    }

// #endregion

// *- Mission plan parsing / processing
// #region

    // ListMissionPlans :: -> (_missionPlans)<List>
    global function ListMissionPlans
    {
        parameter _planParent to "ALL".

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

            if _planParent <> "ALL"
            {
                set planPath to planPath:Lex[_planParent].
            }

            for plan in planPath:Lex:Keys
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

        if g_MissionPlans:Length = 0 
        {
            set g_MissionPlans to ListMissionPlans().
        }

        if g_MissionPlans:Contains(_planId)
        {
            if _planId:Split("_"):Length > 1
            {
                set planBase to _planId:Split("_")[0].
                // set planVer  to _planId:Split("_")[1].
            }
        }

        local planFolder to Volume(0):Files:_plan.
        if planFolder:Lex:HasKey(planBase) 
        {
            set planFolder to planFolder:Lex[planBase].
        }

        local planFileName to "{0}.amp":Format(_planId).
        if planFolder:Lex:Keys:Contains(planFileName)
        {
            local planFile to planFolder:Lex[planFileName].
            local planData to planFile:ReadAll:String:Split(char(10)). // Splits by newline 
            for mm in planData
            {
                local mmSplit to mm:Split("|").
                plan:M:Add(mmSplit[0]).
                if mmSplit:length > 2
                {
                    plan:P:Add(mmSplit[1]).
                    plan:S:Add(mmSplit[2]).
                }
                else if mmSplit:Length > 1
                {
                    // plan:P:Add("").
                    plan:S:Add(mmSplit[1]).
                }
                else
                {
                    // plan:P:Add("").
                    plan:S:Add(g_StageLimit).
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
        local planPriorityList to list( core:tag, Ship:Name:Replace(" ","_")).
        local saniName to Ship:Name:Replace(" ","_").
        if saniName:Length > 1 set saniName to saniName:SubString(0, saniName:FindLast("_")).
        local saniTag to core:tag:split("_")[0].
        local saniPri to choose core:tag:split("_")[1] if core:tag:split("_"):Length > 1 else -1.
        local planId to "".

        local availablePlans to list().
        if Volume(0):Files:_PLAN:Lex:HasKey(saniTag)
        {
            set availablePlans to Volume(0):Files:_PLAN:Lex[saniTag]:Lex:Keys.
        }
        else if Volume(0):Files:_PLAN:Lex:HasKey(saniName)
        {
            set availablePlans to Volume(0):Files:_PLAN:Lex[saniName]:Lex:Keys.
        }
        if saniTag:Length > 0
        {

        }

        // if saniPri >= 0
        // {
        //     print "Rollin' with the homies, like {0}":Format(planID) at (0, cr()).
        // }
        // else 
        if availablePlans:Length = 1
        {
            set planId to availablePlans[0]:Replace(".amp","").
        }
        else
        {
            local doneFlag  to false.
            local doneFlag2 to false.
            local selectedIdx to 0.
            from { local i to 0. local dI to i + 1.} until i = availablePlans:Length step { set i to i + 1. set dI to dI + 1.} do
            {
                // print "i: {0}":Format(i) at (0, 30).
                // print "availablePlans: {0}":Format(availablePlans) at (0, 32).
                print "{0}: {1}  ":Format(dI, availablePlans[i]) at (0, cr()).
            }
            print "PRESS NUMBER FOR SELECTION " at (0, cr()).

            until doneFlag
            {
                GetTermChar().

                if g_TermChar <> ""
                {
                    if planId:Length = 0
                    {
                        local termCharScalar to g_TermChar:ToNumber(-1).
                        
                        if termCharScalar > 0
                        {
                            set selectedIdx to termCharScalar - 1.
                            set planID to choose availablePlans[selectedIdx]:Replace(".amp","") if availablePlans:Length >= termCharScalar else saniTag + "_0".
                            print "Selected PlanID: >> {0} <<           ":Format(planID) at (0, cr()).
                            print "Confirm via ENTER" at (0, cr()).
                            print "Cancel  via DELETE" at (0, cr()).

                            set doneFlag2 to false.
                            until doneFlag2
                            {
                                set g_TermChar to "".
                                GetTermChar().

                                if g_TermChar = Terminal:Input:Enter
                                {
                                    set doneFlag2 to true.
                                }
                                else if g_TermChar = Terminal:Input:DeleteRight
                                {
                                    break.
                                }
                            }
                            clr(g_Line - 2).
                            clr(g_Line - 1).
                            clr(g_Line).
                            set termCharScalar to -1.
                        }
                    }
                }
                else if doneFlag2
                {
                    set doneFlag to true.
                }

                set g_TermChar to "".
            }
        }

        if g_MissionPlans:Length = 0
        {
            set g_MissionPlans to ListMissionPlans().
        }

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



// *- String Parsing 
// #region

    // ParseStringScalar
    global function ParseStringScalar
    {
        parameter _inputString is "",
                  _fallbackValue is 0.

        local scalar_result to -1.
        
        if _inputString:IsType("Scalar") // if it's already a scalar, well...
        {
            set scalar_result to _inputString.
        }
        else
        {
            if _inputString:MatchesPattern("\d+(\.\d+)?((K|k)m$|(M|m)m$)+")
            {
                if _inputString:MatchesPattern("(^\d+(\.\d+)?((K|k)m$))")
                {
                    set scalar_result to _inputString:Replace("km", ""):Replace("Km", ""):ToNumber(_fallbackValue) * 1000.
                }
                else if _inputString:MatchesPattern("(^\d+(\.\d+)?((M|m)m$))")
                {
                    set scalar_result to _inputString:Replace("mm", ""):Replace("Mm", ""):ToNumber(_fallbackValue) * 1000000.
                }
            }
            // else if _inputString:MatchesPattern("(^\d*)[dhmsDHMS]+")
            // {
            //     set scalar_result to 0.
            //     local strSet to list(_inputString).
                
            //     for key in l_timeTable:Keys
            //     {
            //         if strSet[0]:MatchesPattern("(^\d*{0}})":Format(key))
            //         {
            //             set strSet to _inputString[0]:Split(key).
            //             set scalar_result to scalar_result + strSet[0]:ToNumber * l_timeTable[key].
            //             strSet:Remove(0).
            //         }
            //     }
            // }
            else if _inputString:MatchesPattern("(^\d*(\.\d{1,})?$)")
            {
                set scalar_result to _inputString:ToNumber(_fallbackValue).
                wait 0.01.
            }
            else
            {
                set scalar_result to _inputString:ToNumber(_fallbackValue).
            }
        }
        return scalar_result.
    }

    // ParseScalarShortString :: _inScalar<scalar> -> <String>
    // Converts a number to a shorthand string (i.e., 250000 to "250km")
    global function ParseScalarShortString
    {
        parameter _inScalar.
        
        if _inScalar < 10000
        {
            return _inScalar:ToString.
        }
        else if _inScalar < 10000000
        {
            return "{0}Km":Format(Round(_inScalar / 1000, 2)).
        }
        else if _inScalar < 1000000000
        {
            return "{0}Mm":Format(Round(_inScalar / 1000000, 2)).
        }
        else if _inScalar <  10000000000
        {
            return "{0}Gm":Format(Round(_inScalar / 1000000000, 2)).
        }
        else return _inScalar:ToString.
    }

// #endregion


// *- Part Module utilities
// #region

    // DoAction :: (_m)<Module>, (_action)<string>, [(_state)<bool>] -> (ResultCode)<scalar>
    // Given a part module and name of an action, performs if if present on the module.
    global function DoAction
    {
        parameter _m,
                    _action,
                    _state is true.

        local resultCode to 0.

        if _m:HasAction(_action)
        {
            _m:DoAction(_action, _state).
            set resultCode to 1.
        }
        else
        {
            set resultCode to 2.
        }

        return resultCode.
    }

    // DoAction :: (_m)<Module>, (_action)<string>, [(_state)<bool>] -> (ResultCode)<scalar>
    // Given a part module and name of an action, performs if if present on the module.
    global function DoEvent
    {
        parameter _m,
                    _event.

        local resultCode to 0.
        if _m:HasEvent(_event)
        {
            _m:DoEvent(_event).
            set resultCode to 1.
        }
        else
        {
            set resultCode to 2.
        }

        return resultCode.
    }

    // GetField :: <_module>, <_fieldName>, [<_fallbackValue>] -> <fieldValue>
    // Protected method of retrieving a field from a part module. 
    // Will fallback to a provided or default value if the field does not exist
    global function GetField
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

    // GetFormattedAction :: _m<PartModule>, _actionStr<String> -> <String>
    // Returns a properly formatted action name if present on the provided module.
    // If no action found, returns an empty string.
    global function GetFormattedAction
    {
        parameter _m,
                    _actionStr.

        for act in _m:AllActions
        {
            if act:Contains(_actionStr)
            {
                return act:Replace("(callable) _, ",""):Replace(" is KSPAction","").
            }
        }
        return "".
    }

    // GetFormattedEvent :: _m<PartModule>, _eventStr<String> -> <String>
    // Returns a properly formatted event name if present on the provided module.
    // If no event found, returns an empty string.
    global function GetFormattedEvent
    {
        parameter _m,
                    _eventStr.

        for ev in _m:AllEvents
        {
            if ev:Contains(_eventStr)
            {
                return ev:Replace("(callable) _, ",""):Replace(" is KSPEvent","").
            }
        }
        return "".
    }

    // SetField :: (_m)<Module>, (_field)<string>, (_value)<any> -> (ResultCode)<scalar>
    // Given a module and name of a field, set it to the provided value if the field is present on the module
    // Result codes:
    // -- 0: Nothing
    // -- 1: Success
    // -- 2: Warning (Field missing from module)
    // -- 3: Error (Field set action was unsuccessful)
    global function SetField
    {
        parameter _m,
                    _field,
                    _value.

        local resultCode to 0.

        if _m:HasField(_field)
        {
            _m:SetField(_field, _value).
            if _m:GetField(_field) = _value
            {
                set resultCode to 1.
            }
            else
            {
                set resultCode to 3.
            }
        }
        else
        {
            set resultCode to 2.
        }

        return _field.
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
            // "planID", // String plan id
            // ,0    // Context (current running program module)
            // ,0    // Program
            // ,0    // Runmode
            // ,0    // StageStop
        ).

        
        if exists(g_StateCachePath) and not _resetState
        {
            set g_StateCache to Open(g_StateCachePath).
            local stateCache to g_StateCache:ReadAll:String:Split(",").
            state:Add(stateCache[0]).

            from { local i to 1.} until i = stateCache:Length step { set i to i + 1.} do
            {
                 state:Add(stateCache[i]:ToNumber(0)).
            }
        }
        else
        {
            set state to list(g_MissionPlanID, 0, 0, 0, 0).
            log state:join(",") to g_StateCachePath.
            set g_StateCache to Open(g_StateCachePath).
        }
        
        set g_State         to state.

        set g_MissionPlanID to g_State[0]. // print g_MissionPlanID.
        set g_Context       to g_State[1]. // print g_Context.
        set g_Program       to g_State[2]. // print g_Program.
        set g_Runmode       to g_State[3]. // print g_RunMode.
        set g_StageLimit    to g_State[4]. // print g_StageLimit.
        
        return Exists(g_StateCachePath).
    }

    // ReadStateCache
    global function ReadStateCache
    {
        if exists(g_StateCachePath)
        {
            return Open(g_StateCachePath):ReadAll:String:Split(",").
        }
        return list("", -1,-1,-1,0).
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

    // SetContext
    global function SetMissionPlanId
    {
        parameter _planId is "NUL",
                  _update is false.

        set g_MissionPlanId to _planId.
        if _update UpdateState().
        return g_MissionPlanId.
    }


    // SetProgram
    global function SetProgram
    {
        parameter _prog is 0,
                  _update is false.

        set g_Program to _prog.
        set g_Runmode to 0.
        if _update UpdateState().
        ClearScreen.
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
    global function SetStageLimit
    {
        parameter _stgStop is Stage:Number,
                  _update is false.

        set g_StageLimit to _stgStop.
        if _update UpdateState().
        return g_StageLimit.
    }


    // UpdateState
    global function UpdateState
    {
        parameter _cacheEnable to false.

        set g_State to list (
            g_MissionPlanID,
            g_Context,
            g_Program,
            g_Runmode,
            g_StageLimit
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

        
    // #endregion
// #endregion

// #endregion