// Library for parsing and working with core tags and parameters based on mission plans

// #include "0:/lib/libLoader.ks"
@lazyGlobal off.

// *~ Dependencies ~* //
// Required libraries not loaded by libLoader by default go here
// #region
runOncePath("0:/lib/util.ks").
// #endregion


// *~ Variables ~* //
// Local and global variables used in this library
// #region
    // *- Local
    // #region
    // #endregion

    // *- Global
    // #region
    global g_PlanParamMap to lexicon(   // Parameters and type validation delegates in order of most to least used...
        "ParamMap", lexicon(
            "Launch Angle",         { parameter _param. return _param <= 90.}
            ,"Target Apoapsis",     { parameter _param. return _param > 2.}
            ,"Target Eccentricity", { parameter _param. return _param > -2 and _param < 2.}
            ,"Target Heading",      { parameter _param. return _param >= -360 and _param <= 360.}
            ,"Target Inclination",  { parameter _param. return _param > -180 and _param < 180.}
            ,"Target Periapsis",    { parameter _param. return _param >= -2 or _param <= 2. }
            ,"Target Period",       { parameter _param. return _param:MatchesPattern("(^\d*)[dhmsDHMS]+").}
            ,"VarParam",            list("Target Periapsis", "Target Eccentricity", "Target Period")
        ),
        "PlanMap", lexicon(
            "(^(PID)?Orbit(al)?)+.*",     list("Target Inclination", "Target Apoapsis", "VarParam")
            ,"(^S.OUT)+.*",               list("Target Inclination", "Target Apoapsis", "VarParam")
            ,"MaxAlt",                    list("Target Heading", "Launch Angle")
            ,"Sounder",                   list()
            ,"SSO",                       list()
            ,"(^(PID)?SubOrbit(al)?)+.*", list("Inclination", "Target Apoapsis", "Target Periapsis")
        )
    ).
    // #endregion
// #endregion


// *~ Functions ~* //
// #region
    
    // *- Plan Execution Helpers
    // #region

    // SetNextStageLimit :: (_setStage<int>) -> cTag<string>
    // If the core tag has multiple staging components, selects the next one
    global function SetNextStageLimit
    {
        parameter _setStage is -1.
        
        local cTag to core:tag.
        local lastStgLim to g_StageLimit.
        if _setStage < 0
        {
            if g_StageLimitSet:Length > 1
            {
                set cTag to cTag:replace("|{0};":Format(g_StageLimit:ToString), "|").
                local tagSplit to cTag:Split("|").
                set g_StageLimit to tagSplit[tagSplit:Length - 1]:Split(";")[0]:ToNumber(Stage:Number).
                set g_MissionTag:STGSTP to g_StageLimit.
                g_StageLimitSet:Remove(0).
            }
            else
            {
                set g_StageLimit to 0.
                set cTag to cTag:Replace(cTag:Substring(cTag:FindLast("|") + 1, cTag:Length - cTag:FindLast("|") - 1), g_StageLimit:ToString).
                g_StageLimitSet:Clear().
                g_StageLimitSet:Add(g_StageLimit).
                set g_MissionTag:STGSTP to g_StageLimit.
            }
        }
        else
        {
            set g_StageLimit to _setStage.
            set cTag to cTag:Replace(cTag:Substring(cTag:FindLast("|") + 1, cTag:Length - cTag:FindLast("|") - 1), g_StageLimit:ToString).
            g_StageLimitSet:Clear().
            g_StageLimitSet:Add(g_StageLimit).
            set g_MissionTag:STGSTP to g_StageLimit.
        }

        if g_StageLimit <> lastStgLim
        {
            set core:tag to cTag.
            if g_Debug { OutDebug("g_StageLimit updated to {0}":Format(g_StageLimit)).}
        }
        return cTag.
    }
    // #endregion

    // *- Plan Parsers
    // #region

    // ParseCoreTag :: (_tag)<String> -> (parsedTagObject)<Lexicon>
    // Parses a core tag, including launch params and stop stage
    // Format: (missionName)<string>|param1;param2;param3;param4|(stageStop)<scalar>
    global function ParseCoreTag
    {
        parameter _tag is core:tag,
                  _updatePartTag is false.

        local dirtyTag          to false.
        local newStopStage      to 0.
        local parsedMission     to "".
        local parsedParams      to list().
        local parsedStageStop   to 0.
        local parsedTag         to list(_tag).
        local prmResult         to "".
        local prmSplit          to list().
        local prmSet            to list().
        local stageExitGate     to "".
        local stageID           to 0.
        local tempStageStop     to "".
        local tempStopSplit     to list().

        local parsedTagObject   to lexicon(
            "MISSION", _tag:Split("|")[0]
            ,"PARAMS", list()
            ,"STGSTOP", 0
            ,"STAGESTOP", 0
            ,"STGSTOPSET", list()
        ).

        if _tag:Contains("|")
        {
            set parsedTag       to _tag:Split("|").
            set tempStageStop to parsedTag[parsedTag:Length - 1].
            if tempStageStop:Contains(";")
            {
                // local stopIdx to 0.
                set tempStopSplit to tempStageStop:Split(";").

                if tempStopSplit:Length > 0
                {
                    for stageIDStr in tempStopSplit
                    {
                        set stageID to stageIDStr:ToNumber(-1).
                        if stageID >= 0
                        {
                            parsedTagObject:StgStopSet:Add(stageID).
                        }
                    }
                }
                else
                {
                    parsedTagObject:StgStopSet:Add(stageID).
                }
                set parsedStageStop to parsedTagObject:StgStopSet[0].
            }
            else
            {
                set parsedStageStop to tempStageStop:ToNumber(-1).
            }

            set parsedTagObject["MISSION"] to parsedTag[0].

            if parsedStageStop <> -1
            {
                set parsedTagObject["STGSTOP"] to parsedStageStop.
                set g_StageLimit to parsedStageStop.
                set g_StageLimitSet to parsedTagObject:StgStopSet.
            }
            else
            {
                set parsedTagObject["STGSTOP"] to 0.
                set g_StageLimit to parsedStageStop.
                set g_StageLimitSet to list(g_StageLimit).
            }

            if parsedTag:Length > 2 // Params
            {
                set prmSplit to parsedTag[1]:Split(";"). 
                if prmSplit:Length > 0
                {               
                    set prmSet to list().
                    from { local i to 0.} until i >= prmSplit:Length step { set i to i + 1.} do
                    {
                        local tagPrm to prmSplit[i].

                        if i = 0
                        {
                            prmSet:Add(ParseInclinationTagParameter(tagPrm)).
                            set dirtyTag to true.
                        }
                        else
                        {
                            prmSet:Add(ParseStringScalar(tagPrm)).
                            set dirtyTag to true.
                        }
                    }
                }
            }
            else
            {
            }

            set parsedTagObject["PARAMS"] to prmSet.
            set g_MissionTag:Params to prmSet.
        }

        if _updatePartTag and dirtyTag
        {
            set Core:Tag to "{0}|{1}|{2}":Format(parsedTagObject:MISSION, parsedTagObject:PARAMS:Join(";"), parsedTagObject:STGSTOPSET:Join(";")).
        }

        return parsedTagObject.
    }
    // #endregion

    // *- Parameter parsing
    // #region

    // ParseInclinationTagParameter
    local function ParseInclinationTagParameter
    {
        parameter _incTag.

        local parsedInc to 0.

        if _incTag:MatchesPattern("TGT(:\w*)*")
        {
            set parsedInc to SetInclinationTagFromTarget(_incTag).
        }
        else if _incTag:ToNumber(808) = 808
        {
            // #TODO: Add invalid launch param catch
            // set parsedInc to SetInclinationTagFromTerm(_incTag).
            
            // Temporary - launch at min inclination
            set parsedInc to Round(Ship:Orbit:Inclination, 3).
        }
        else
        {
            set parsedInc to ParseStringScalar(_incTag).
        }
        return parsedInc. 
    }

    // ParsePlanTag :: (_inTagObject<lexicon>) -> _formattedParameters
    // Takes the result of ParseCoreTag and translates the tagged parameters into usable values using g_PlanParamMap as the guide
    global function ParsePlanTag
    {
        parameter _planTag is Core:Tag.

        local paramMap to list().
        local planObj to lexicon(
            "MissionPlan", ""
            ,"PlanParameters", lexicon()
            ,"StageParameters", list()
        ).

        local planComponents to _planTag:Split("|").

        from { local pcIdx to 0.} until pcIdx = planComponents:length step { set pcIdx to pcIdx + 1.} do
        {
            local pc to planComponents[pcIdx].

            if pcIdx = 0 // Mission parsing
            {
                from { local __i to 0. local doneFlag to False.} until __i = g_PlanParamMap:PlanMap:Keys:Length or doneFlag step { set __i to __i + 1.} do
                {
                    local regx to g_PlanParamMap:PlanMap[__i].
                    if pc:MatchesPattern(regx)
                    {
                        set planObj:MissionPlan to pc.
                        set paramMap to g_PlanParamMap:PlanMap[regx].
                        set doneFlag to True.
                    }
                }
            }
            else if pcIdx = 1 and planComponents:Length > 2 // Plan param parsing
            {
                local paramList to pc:Split(";").                
                from { local __i to 0.} until __i = paramMap:Length or __i = paramList:Length step { set __i to __i + 1.} do
                {
                    local __paramType         to paramMap[__i].

                    if g_PlanParamMap:ParamMap:Keys:Contains(__paramType)
                    {
                        local __paramVal          to paramList[__i].
                        local __parsedVal         to g_ErrorFallback. 
                        if __paramType = "VarParam"
                        {
                            from { local __n to 0. local doneFlag to False.} until __n = g_PlanParamMap:ParamsMap:VarParam:Length or doneFlag step { set __n to __n + 1.} do
                            {
                                local __nParamType to g_PlanParamMap:ParamsMap:VarParam[__n].
                                local __nWorking  to ParseParameterString(__nParamType, __paramVal).
                                if __nWorking = g_ErrorFallback
                                {
                                    OutInfo("ERR: Invalid Parameter at position for type. [{0}|{1}] {2} ":Format(__i, __paramType, __paramVal), 2).
                                }
                                else
                                {
                                    planObj:PlanParameters:Add(__nParamType, __parsedVal).
                                    set doneFlag to True.
                                }
                            }
                        }
                        else 
                        {
                            set __parsedVal to ParseParameterString(__paramType, __paramVal).
                            if __parsedVal = g_ErrorFallback
                            {
                                OutInfo("ERR: Invalid Parameter at position for type. [{0}|{1}] {2} ":Format(__i, __paramType, __paramVal), 2).
                            }
                            else
                            {
                                planObj:PlanParameters:Add(__paramType, ParseParameterString(__paramType, __paramVal)).
                            }
                        }

                    }
                }
            }
            else if pcIdx = planComponents:Length - 1 // Stage param parsing
            {
                local splitStageLimits to pc:Split(";").

                for stageID in splitStageLimits
                {
                    planObj:StageParameters:Add(stageID:ToNumber(-1)).
                }
            }
        }
    }

    // ParseParameterString :: _paramType<string>,_paramString<string> -> _parsedVal<Scalar>
    // Returns a validated and converted parameter value
    local function ParseParameterString
    {
        parameter _paramType, 
                  _paramString.

        local parsedVal to g_ErrorFallback.

        if _paramType = "Target Period"
        {
            if g_PlanParamMap:ParamMap[_paramType]:Call(_paramString)
            {
                set parsedVal to ParseStringScalar(_paramString, g_ErrorFallback).
            }
        }
        else
        {
            local workingVal to ParseStringScalar(_paramString, g_ErrorFallback).
            if g_PlanParamMap:ParamMap[_paramType]:Call(workingVal)
            {
                set parsedVal to workingVal.
            }
        }
        return parsedVal.
    }


    // #endregion

    // Parameter setters
    // #region 

    // SetInclinationTagFromTarget :: _incTag<string> 0> _parsedVal<Scalar>
    // Takes the core tag inclination parameter string and returns a validated and converted value
    local function SetInclinationTagFromTarget
    {
        parameter _incTagStr. 

        OutMsg("Mission tag inclination set to TARGET mode").

        // Build a list of all possible targets orbiting this body
        local tgtList to list().
        for tgt in BuildList("targets")
        {
            if tgt:Body:Name = Ship:Body:Name
            {
                tgtList:Add(tgt).
            }
        }
        for child in Body:OrbitingChildren
        {
            tgtList:Add(child).
        }

        // Determine if there is a target provided by the tag
        if _incTagStr:MatchesPattern("tgt:\w+")
        {
            local tgtTagStr to _incTagStr:Replace("tgt:","").
            if tgtTagStr = "Luna" set tgtTagStr to "Moon". // Because the game uses both Moon and Luna but not kOS, so I refer to it as luna sometimes
            for tgt in tgtList
            {
                 // NOTE: This short circuits on the first match. If multiple ships have the same name, (i.e., multiple debris from a launch), the first will 
                 // be set as the target. While vessels have internal guids to prevent naming collision issues, these are not exposed to kOS. If you need to 
                 // target a vessel that may not have a unique name (especially debris), give it a unique name in flight / from the tracking station.
                if tgt:Name = tgtTagStr
                {
                    set Target to tgt.
                    break.
                }
            }
        }

        // Initialize loop variables
        local tgtName to "N/A".
        local tgtInc to 0.
        local tgtPtr to Ship.
        local doneFlag to false.
        local incConfirmFlag to false.
        local tgtConfirmFlag to false.
        
        // Loop until we have a valid target and inclination parameter
        until doneFlag
        {

            // Clear waiting terminal keypresses to avoid accidental commands
            Terminal:Input:Clear.
            set g_TermChar to "".
            // Target confirmation
            until tgtConfirmFlag 
            {
                // Do we have a target? If so, set the name.
                if HasTarget 
                {
                    set tgtPtr to Target.
                    set tgtName to Target:Name.
                }
                else
                {
                    set tgtPtr to Ship.
                    set tgtName to "N/A".
                }
                OutInfo("Selected target: " + tgtName).
                OutInfo("ENTER: Confirm | DELETE: Clear | BACKSPACE: Skip", 1).

                // Check any waiting input against enabled commands
                if GetTermChar() <> ""
                {
                    if CheckTermChar(Terminal:Input:Enter)
                    {
                        if HasTarget
                        {
                            set tgtInc to Round(tgtPtr:Orbit:Inclination,3).            
                            set tgtConfirmFlag to true.
                            OutInfo("*** Target Confirmed *** ", 2).
                            wait 0.125.
                        }
                        else
                        {
                            OutInfo("[ERR]: No target selected! ", 2).
                            wait 0.25.
                        }
                    }
                    else if CheckTermChar(Terminal:Input:DeleteRight)
                    {
                        Unset Target.
                        set tgtName to "N/A".
                        set tgtPtr to Ship.
                        OutInfo("* Target cleared *", 2).
                        wait 0.125.
                    }
                    else if CheckTermChar(Terminal:Input:Backspace)
                    {
                        set tgtName to "N/A".
                        set tgtPtr to Ship.
                        set tgtConfirmFlag to true.
                        set incConfirmFlag to true.
                        set tgtInc to Round(Ship:Orbit:Inclination, 3).
                        OutInfo("* Skipping target selection * ", 2).
                        wait 0.25.
                    }
                    set g_TermChar to "".
                }
            }
            
            Terminal:Input:Clear.
            set g_TermChar to "".
            until incConfirmFlag
            {
                OutInfo("Selected inclination: " + tgtInc).
                OutInfo("ENTER: Confirm | UP: Asc | DOWN: Desc | BACKSPACE: Skip", 1).

                if GetTermChar() <> ""
                {
                    if CheckTermChar(Terminal:Input:Enter)
                    {
                        set incConfirmFlag to true.
                        OutInfo("*** Inclination Confirmed *** ", 2).
                        wait 0.125.
                    }
                    else if CheckTermChar(Terminal:Input:UpCursorOne)
                    {
                        set tgtInc to Abs(tgtInc).
                        OutInfo("* Target inclination set to ascending node *", 2).
                        wait 0.125.
                    }
                    else if CheckTermChar(Terminal:Input:DownCursorOne)
                    {
                        set tgtInc to tgtInc * -1.
                        OutInfo("* Target inclination set to descending node *", 2).
                        wait 0.125.
                    }
                    else if CheckTermChar(Terminal:Input:Backspace)
                    {
                        set tgtName to "N/A".
                        set tgtPtr to Ship.
                        set tgtConfirmFlag to true.
                        set incConfirmFlag to true.
                        set tgtInc to Round(Ship:Orbit:Inclination, 3).
                        OutInfo("* Skipping target selection * ", 2).
                        wait 0.25.
                    }
                    set g_TermChar to "".
                }
            }
            
            return tgtInc.
        }
    }   

    local function foo
    {

        local tgtIncConfirm to false.
        local tgtSelectConfirm to false. 

        local tgtInc to 0.
        until tgtIncConfirm
        {
            if HasTarget
            {
                set tgtInc to Target:Orbit:Inclination.
                OutInfo("Target: {0} | Inclination: {1} ":Format(Target:Name, Round(tgtInc, 3))).
                OutInfo("*** Use panel controls to adjust inclination ***", 1).
                OutInfo("ENTER: Confirm | BACKSPACE: Clear | END: Skip ", 2).
                
                Terminal:Input:Clear.
                set g_TermChar to "".
                until g_TermChar <> ""
                {
                    GetTermChar().
                    if CheckTermChar(Terminal:Input:Enter) 
                    {
                        OutInfo("* Target Confirmed! *", 2).
                        
                        set _incTag to Round(tgtInc, 3).
                        prmSet:Add(_incTag).

                        set dirtyTag to true.
                        set tgtSelectConfirm to true.
                        wait 0.5.
                    }
                    else if CheckTermChar(Terminal:Input:Backspace)
                    {
                        OutInfo("* Clearing Target *", 2).
                        wait 0.5.
                        Unset Target.
                    }
                }
                set g_TermChar to "".
            }
            else
            {
                OutInfo("Target selected: (Select a target) ").
                OutInfo("Inclination Val: {0}} ":Format(Round(tgtInc, 3)), 1).
                OutInfo("END: Skip ", 2).

                if g_TermChar <> ""
                {
                    GetTermChar().
                    if CheckTermChar(Terminal:Input:EndCursor)
                    {
                        OutInfo("Target selected: NONE      ").
                        OutInfo(" *** Skipping Target Selection *** ", 2).

                        set _incTag to Round(tgtInc, 3).
                        prmSet:Add(_incTag).

                        set dirtyTag to true.

                        wait 0.5.
                    }
                }
            }

            if g_TermChar <> ""
            {

            }
        }
    }


    // #endregion
// #endregion