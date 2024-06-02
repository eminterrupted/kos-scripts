// #include "0:/lib/depLoader.ks"
@LazyGlobal off.

// *~ Dependencies ~* //
// #region
SetupTerminal().
// #endregion


// *~ Variables ~* //
// #region
    // *- Global Variables
    // #region
    global g_AvailablePlans to list().
    global g_StateCache to "".
    global g_SanitizedTag to core:tag.
    // #endregion

    // *- Local
    // #region
    // #endregion

    // *- Global Anonymous Delegates
    // #region
    global g_NulCheckDel to { return True.}.
    global g_NulActionDel to { return list(False, { return True.}, { return False.}).}.
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
        parameter _msg is "PRESS ANY KEY TO CONTINUE".

        local decoratedMsg to "*~^~* {0} *~^~*":Format(_msg:ToUpper).
        local pad  to Floor((Terminal:Width - decoratedMsg:Length) / 2).
        local padStr to choose g_SpaceStr[pad] if pad <= g_SpaceStr:Keys:Length - 1 else NewBlankString(pad).


        local msgStr to "{0}{1}{0}".
        OutStr(msgStr:Format(padStr, decoratedMsg), Terminal:Height - 3).
        Terminal:Input:Clear.
        Terminal:Input:GetChar.

        local blankStr to NewBlankString(Terminal:Width).
        OutStr(msgStr:Format(padStr, blankStr), Terminal:Height - 3).
    }

    // NoOp - just passes the existing value back. Not very useful except when it is.
    global function NoOp
    {
        parameter _p is False.

        return _p.
    }

    // Basic function that moves terminal setup out of the library header and into a proper function
    global function SetupTerminal
    {
        parameter _width is 72,
                  _height is 45. 

        global g_TermHeight to _height.
        set Terminal:Height to g_TermHeight.
        global g_TermWidth  to _width.
        set Terminal:Width to g_TermWidth.
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

    // ModifyMissionPlan :: _missionPlanId<string> -> _planData<list>
    // Returns updated plan data based on an initial missionPlanId. 
    // User can modify any of the primary values
    global function ModifyMissionPlan
    {
        parameter _missionPlanId is g_MissionPlanID.

        local cancelFlag to False. 
        local doneFlag to False.
        local missionPlan to GetMissionPlan(_missionPlanId).
        local modifiedPlan to missionPlan:Copy.
        local planIdx to -1.
        local rerollFlag to True.

        clearScreen.
        set g_line to 5.
        OutStr("Plan Modification Routine", cr()).
        cr().
        local line to cr().

        set g_TermChar to "".

        set doneFlag to False.
        until False
        {
            set g_line to line.
            
            set planIdx to PlanModMissionSelect(missionPlan).
    
            local planPhaseParams to list(missionPlan:M[planIdx], missionPlan:P[planIdx], missionPlan:S[planIdx]).
            set g_line to line.
            set planPhaseParams to PlanModParamsSelect(planPhaseParams).
            
            set doneFlag to False.

            until doneFlag or cancelFlag or rerollflag
            {
                GetTermChar().
                
                if g_TermChar = ""
                {
                    OutStr("[ENTER]    : Confirm modifications", g_line).
                    OutStr("[HOME]     : Modify another value", cr()).
                    OutStr("[BACKSPACE]: Cancel modifications", cr()).
                    wait 0.1.
                }
                else
                {
                    if g_TermChar = Terminal:Input:Enter
                    {
                        set doneFlag to True.
                    }
                    else if g_TermChar = char(8)
                    {
                        set cancelFlag to True.
                    }
                    else if g_TermChar = Terminal:Input:HomeCursor
                    {
                        set rerollFlag to True.
                    }
                    else 
                    {
                        OutStr("Invalid selection, try again", g_line).
                        clr(cr()).
                        wait 0.5.
                    }
                }

                set g_TermChar to "".
            }

            if doneFlag
            {
                return modifiedPlan.
            }
            else if cancelFlag 
            {
                return missionPlan.
            }
            else if rerollFlag
            {
                for i in Range(line, g_TermHeight, 1)
                {
                    clr(i).
                }
            }
        }
    }

    // PlanModMissionSelect
    // Helper for ModifyMissionPlan()
    local function PlanModMissionSelect
    {
        parameter _missionPlan.

        local line to g_Line.
        
        local __cancelFlag to False.
        local __planIdx to -1.
        local __rerollFlag to True.

        set g_TermChar to "".
        until False
        {   
            set __planIdx to -1.
            set g_line to line.
            if __rerollFlag
            {
                OutStr("Choose plan phase to modify", g_line).
                cr().
                OutStr("[ENTER]: Confirm selection", cr()).
                OutStr("[BACKSPACE]: Cancel", cr()).
                cr().
                for m in _missionPlan:M
                {
                    set __planIdx to __planIdx + 1.
                    OutStr("{0}: {1}":Format(__planIdx, m), cr()).
                }
                cr().
                set __rerollFlag to False.
            }

            local __doneFlag to False.
            
            until __doneFlag
            {
                GetTermChar().
                

                if g_TermChar = Terminal:Input:Enter
                {
                    set __doneFlag to True.
                }
                else if g_TermChar = char(8)
                {
                    set __cancelFlag to True.
                    set __doneFlag to True.
                }
                else 
                {
                    local termCharNumber to g_TermChar:ToNumber(-1).
                    if termCharNumber < 0 or termCharNumber > __planIdx
                    {
                        OutStr("Invalid selection! Try again", cr()).
                        wait 0.5.
                        set __doneFlag to True.
                        set __rerollFlag to True.
                    } 
                    else
                    {
                        OutStr("Selected plan: {0}":Format(_missionPlan:M[__planIdx]), cr()).
                        OutStr("Press ENTER to confirm").
                        wait 0.5.
                        set __planIdx to termCharNumber.
                        set __doneFlag to True.
                    }
                }
                set g_TermChar to "".
            }

            if __rerollFlag
            {
            }
            else if __cancelFlag
            {
                return -1.
            }
            else
            {
                return __planIdx.
            }
        }
    }

    // PlanModParamsSelect
    // Helper for ModifyMissionPlan()
    local function PlanModParamsSelect
    {
        parameter __missionPhaseVals.

        local _ogLine to g_Line.
        local _line to _ogLine.
        
        local _splitMissionPhaseVals to __missionPhaseVals[1]:Split(";").

        local _cancelFlag to False.
        local _confirmFlag to False.
        local _doneFlag to False.
        local _modifiedPhaseVals to __missionPhaseVals:Copy.
        local _rerollFlag to True.
        local _returnPhaseVals to list().

        local _descriptList to list(
            list(
                 "[{0}] Inclination       : {1}"
                ,"[{0}] Shape Factor      : {1}"
                ,"[{0}] Tgt Transfer Alt  : {1}"
                ,"[{0}] Tgt Insertion Alt : {1}"
            )
            ,list(
                "[1] {0}"
            )
        ).

        set g_TermChar to "".

        local descriptors    to list().
        local _modLoopActive to False.
        local _paramIdx      to 0.
        local _selectedParam to list().
        until _doneFlag
        {   
            GetTermChar().

            set g_line to _ogLine.
            
            if _modLoopActive
            {
                OutStr("{0}":Format(_selectedParam[0]:Format("SELECTED PARAM", _selectedParam[1])), cr()).
                cr().

                OutStr("[ENTER]     Confirm", cr()).
                OutStr("[BACKSPACE] Back", cr()).

                if g_TermChar = Terminal:Input:Backspace
                {
                    OutStr("Cancelling...", g_line - 2).
                    clr(g_line - 1).
                    clr(g_line).
                    set _cancelFlag to True.
                }
                else if g_TermChar = Terminal:Input:Enter
                {
                    clr(g_line - 2).
                    clr(g_line - 1).
                    local _newVal to "".
                    
                    set g_TermChar to "".

                    until _confirmFlag or _cancelFlag
                    {
                        GetTermChar().

                        if g_TermChar <> ""
                        {
                            if g_TermChar = Terminal:Input:Enter
                            {
                                if _newVal = ""
                                {
                                    set _newVal to _selectedParam[1].
                                    OutStr("No input! ", g_Line + 2).
                                    wait 0.25.
                                    clr(g_line + 2).
                                }
                                else
                                {
                                    _modifiedPhaseVals:Remove(_paramIdx).
                                    _modifiedPhaseVals:Insert(_paramIdx, _newVal).
                                    OutStr("New value set  : [{0}] ":Format(_newVal), g_Line).
                                    wait 0.25.
                                    // cr().
                                    set _confirmFlag to True.
                                    set _modLoopActive to False.
                                }
                            }
                            else if g_TermChar = Terminal:Input:Backspace
                            {
                                set _newVal to _newVal:substring(0, Max(0, _newVal:Length - 1)).
                                OutStr("Enter new value: [{0}] ":Format(_newVal), g_Line).
                            }
                            else if g_TermChar = Terminal:Input:DeleteRight
                            {
                                OutStr("Cancelling... ", g_Line - 2).
                                clr(g_line - 1).
                                clr(g_line).
                                clr(g_line + 2).
                                set _cancelFlag to True.
                            }
                            else if g_TermChar:MatchesPattern("(\w|\d|\.)")
                            {
                                set _newVal to _newVal + g_TermChar.
                                OutStr("Enter new value: [{0}] ":Format(_newVal), g_Line).
                            }
                            else
                            {
                                OutStr("Invalid input!", g_line + 1).
                                wait 0.5.
                                clr(g_line + 1).
                            }
                            set g_TermChar to "".
                        }
                        else
                        {
                            wait 0.02.
                        }
                    }
                    set _cancelFlag to False.
                    set _confirmFlag to False.
                }
            }
            else if g_TermChar = Terminal:Input:DeleteRight
            {
                set _rerollFlag to True.
            }
            else if g_TermChar = Terminal:Input:Backspace
            {
                set _cancelFlag to True.
                set _doneFlag to True.
            }
            else if g_TermChar = Terminal:Input:Enter
            {
                set _confirmFlag to True.
                set _doneFlag to True.
            } 
            else if g_TermChar:Length > 0
            {
                local termCharNumber to g_TermChar:ToNumber(-1).
                if termCharNumber < 0 or termCharNumber > _splitMissionPhaseVals:Length - 1
                {
                    OutStr("Invalid selection! Try again", cr()).
                    wait 0.5.
                    set _selectedParam to list().
                    set _rerollFlag to True.
                } 
                else
                {
                    set _paramIdx to termCharNumber.
                    set _selectedParam to list(descriptors[_paramIdx], _splitMissionPhaseVals[_paramIdx]).
                    set _modLoopActive to _selectedParam:Length > 0.

                    for i in Range(0, 12, 1)
                    {
                        clr(_ogLine + i).
                    }
                }
            }
            
            if _rerollFlag
            {
                OutStr("Modifying mission: {0}":Format(_modifiedPhaseVals[0]), g_line).
                cr().
                OutStr("Choose plan parameter to modify ([BACKSPACE] to cancel)", cr()).
                set descriptors to choose _descriptList[0] if __missionPhaseVals[0]:Contains("launchAscent") else _descriptList[1].
                from { local i to 0. } until i = _splitMissionPhaseVals:Length step { set i to i + 1.} do
                {
                    OutStr(descriptors[i]:Format(i, _splitMissionPhaseVals[i]), cr()).
                }
                OutStr("Stage Limit: {0}":Format(__missionPhaseVals[2]), cr()).
                cr().
                set _rerollFlag to False.
            }
            else
            {
                set g_line to _line.
                if _cancelFlag
                {
                    set _returnPhaseVals to __missionPhaseVals.
                }
                else if _confirmFlag
                {
                    set _returnPhaseVals to _modifiedPhaseVals.
                }
            }

            set g_TermChar to "".
        }
        set g_line to _ogLine.

        return _returnPhaseVals.
    }

    // GetMissionPlanID :: [(_missionName)<String>] -> (_missionPlanID)
    // Returns a pointer to the mission plan of a vessel based on core tag and vessel name
    global function SelectMissionPlanID 
    {
        // local planPriorityList to list(core:tag, Ship:Name:Replace(" ","_")).
        local planIdx to -1.
        local saniName to Ship:Name.
        if Ship:Name:Contains(" ")
        {
            set saniName to saniName:Replace(" ", "_").
            if saniName:Length > 1 set saniName to saniName:SubString(0, saniName:FindLast("_")).
        }

        local saniTag to core:tag:split("_")[0].
        // local saniPri to choose core:tag:split("_")[1] if core:tag:split("_"):Length > 1 else -1.
        local planId to "".

        set g_AvailablePlans to list().

        if saniTag:Length > 0 
        {
            if Volume(0):Files:_PLAN:Lex:HasKey(saniTag)
            {
                set g_AvailablePlans to Volume(0):Files:_PLAN:Lex[saniTag]:Lex:Keys.
            }
        }
        else if Volume(0):Files:_PLAN:Lex:HasKey(saniName)
        {
            set g_AvailablePlans to Volume(0):Files:_PLAN:Lex[saniName]:Lex:Keys.
        }
        
        if g_AvailablePlans:Length = 1
        {
            set planId to g_AvailablePlans[0]:Replace(".amp","").
        }
        else
        {
            set planIdx to SelectPlanFromList(g_AvailablePlans, planIdx, True).
            if planIdx < 0
            {
                
            }
            else if planIdx >= 0 and planIdx <= g_AvailablePlans:Length
            {
                set planId to g_AvailablePlans[planIdx]:Replace(".amp","").
            }
            else
            {

            }
        }



        // else
        // {
        //     local cancelFlag to False.
        //     local doneFlag  to False.
        //     local doneFlag2 to False.
        //     local selectedIdx to 0.
        //     local pageIdx to 0.

        //     local _line to g_line.

        //     until doneFlag
        //     {
        //         set g_Line to _line.

        //         DispPlans(pageIdx).

        //         GetTermChar().

        //         if g_TermChar <> ""
        //         {
        //             if planId:Length = 0
        //             {
        //                 local termCharScalar to g_TermChar:ToNumber(-1).
                        
        //                 if g_TermChar:MatchesPattern("[-_]")
        //                 {
        //                     set pageIdx to Max(0, pageIdx - 1).
        //                 }
        //                 else if g_TermChar:MatchesPattern("[\+=]")
        //                 {
        //                     set pageIdx to Max(0, pageIdx + 1).
        //                 }
        //                 else if termCharScalar >= 0
        //                 {
        //                     if Mod(termCharScalar, 10) = 0 
        //                     {
        //                         set termCharScalar to termCharScalar + 10.
        //                     }

        //                     set selectedIdx to Max(0, Min(g_AvailablePlans:Length - 1, termCharScalar - 1)).
        //                     set planID to choose g_AvailablePlans[selectedIdx]:Replace(".amp","") if g_AvailablePlans:Length >= termCharScalar else saniTag + "_0".

        //                     OutStr("Selected PlanID: >> {0} << ":Format(planID), cr()).
        //                     OutStr("Confirm via ENTER", cr()).
        //                     OutStr("Cancel  via DELETE", cr()).

        //                     set doneFlag2 to False.
        //                     until doneFlag2
        //                     {
        //                         set g_TermChar to "".
        //                         GetTermChar().

        //                         if g_TermChar = Terminal:Input:Enter
        //                         {
        //                             set doneFlag2 to True.
        //                         }
        //                         else if g_TermChar = Terminal:Input:DeleteRight
        //                         {
        //                             set cancelFlag to True.
        //                             break.
        //                         }
        //                         else if g_TermChar = "-"
        //                         {
        //                             set pageIdx to Max(0, pageIdx - 1).
        //                             break.
        //                         }
        //                         else if g_TermChar = "+"
        //                         {
        //                             set pageIdx to Max(0, pageIdx + 1).
        //                             break.
        //                         }
        //                     }
        //                     clr(g_Line - 2).
        //                     clr(g_Line - 1).
        //                     clr(g_Line).
        //                     set termCharScalar to -1.
        //                 }
        //                 else
        //                 {
                            
        //                 }
        //             }
        //             OutMsg("Selected PlanID: >> {0} <<           ":Format(planID), cr()).
        //         }
        //         else if doneFlag2
        //         {
        //             set doneFlag to True.
        //         }
        //         else if cancelFlag
        //         {
        //             OutMsg("Cancelling...").
        //         }
        //         set g_TermChar to "".

        //     }
        // }

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

// *- Selection
// #region

    // SelectFromList
    global function SelectPlanFromList
    {
        parameter _inList,
                  _selectIdx is 0,
                  _confirm is True.

        local cancelFlag to False.
        local doneFlag  to False.
        local doneFlag2 to False.
        local _selectIdx to 0.
        local selectedItem to "".
        local pageIdx to 0.

        local _line to g_line.

        until doneFlag
        {
            set g_Line to _line.

            DispPlans(_inList, pageIdx, g_line).

            GetTermChar().

            if g_TermChar <> ""
            {
                local termCharScalar to g_TermChar:ToNumber(-1).
                    
                if g_TermChar:MatchesPattern("[-_]")
                {
                    set pageIdx to Max(0, pageIdx - 1).
                }
                else if g_TermChar:MatchesPattern("[\+=]")
                {
                    set pageIdx to Max(0, pageIdx + 1).
                }
                else if termCharScalar >= 0
                {
                    if Mod(termCharScalar, 10) = 0 
                    {
                        set termCharScalar to termCharScalar + 10.
                    }

                    if termCharScalar >= 0 and termCharScalar <= 9 
                    {
                        set _selectIdx to Max(0, Min(_inList:Length - 1, termCharScalar - 1)).
                        
                        OutStr("Selected Item: >> {0} << ":Format(_inList[_selectIdx])).
                        cr().
                        if _confirm
                        {
                            OutStr("[ENTER]: Confirm").
                            OutStr("[BACKSPACE]: Cancel").

                            set doneFlag2 to False.
                            until doneFlag2
                            {
                                set g_TermChar to "".
                                GetTermChar().

                                if g_TermChar = Terminal:Input:Enter
                                {
                                    set doneFlag2 to True.
                                }
                                else if g_TermChar = char(8)
                                {
                                    set cancelFlag to True.
                                    break.
                                }
                            }
                            clr(g_Line - 2).
                            clr(g_Line - 1).
                            clr(g_Line).
                        }
                        // set termCharScalar to -1.
                    }
                    else
                    {
                        OutStr("Invalid selection, out of range. Try again.").
                        wait 1.
                    }
                }
                else
                {
                    OutStr("Invalid selection, unrecognized input. Try again.").
                    wait 1.
                }
                set g_TermChar to "".
            }
            
            if doneFlag2
            {
                set doneFlag to True.
            }
            else if cancelFlag
            {
                OutMsg("Cancelling...").
                return -1.
            }
        }
        return _selectIdx.
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
                    _state is True.

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
        parameter _resetState to False.

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
                  _update is False.

        set g_Context to _context.
        if _update UpdateState().
        return g_Context.
    }

    // SetContext
    global function SetMissionPlanId
    {
        parameter _planId is "NUL",
                  _update is False.

        set g_MissionPlanId to _planId.
        if _update UpdateState().
        return g_MissionPlanId.
    }


    // SetProgram
    global function SetProgram
    {
        parameter _prog is 0,
                  _update is False.

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
                  _update is False.

        set g_Runmode to _rm.
        if _update UpdateState().
        return g_Runmode.
    }

    // SetStageStop
    global function SetStageLimit
    {
        parameter _stgStop is Stage:Number,
                  _update is False.

        set g_StageLimit to _stgStop.
        if _update UpdateState().
        return g_StageLimit.
    }


    // UpdateState
    global function UpdateState
    {
        parameter _cacheEnable to False.

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
        // If yes, set g_TermChar to it and return True.
        global function GetTermChar
        {
            if Terminal:Input:HasChar 
            { 
                until not Terminal:Input:HasChar
                {
                    set g_TermChar to Terminal:Input:GetChar.
                    g_TermQueue:Push(g_TermChar).
                }
                set g_TermHeightasChar to True.
                Terminal:Input:Clear().
            }
            // else
            // {
            //     set g_TermHeightasChar to False.
            // }
            return g_TermHeightasChar.
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