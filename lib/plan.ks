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
        parameter _tag is core:tag.

        local newStopStage      to 0.
        local parsedMission     to "".
        local parsedParams      to list().
        local parsedStageStop   to 0.
        local parsedTag         to list(_tag).
        local prmResult         to "".
        local prmSplit          to list().
        local prmSet            to list().
        local stageExitGate     to "".
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

                for stageID in tempStopSplit
                {
                    parsedTagObject:StgStopSet:Add(stageID).
                }
                set parsedStageStop to parsedTagObject:StgStopSet[0]:ToNumber(-1).
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
                        local prm to prmSplit[i].
                        prmSet:Add(ParseStringScalar(prm)).
                    }
                }
            }
            else
            {
            }

            set parsedTagObject["PARAMS"] to prmSet.
            set g_MissionTag:Params to prmSet.
        }

        return parsedTagObject.
    }
    // #endregion

    // *- Parameter parsing
    // #region

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
// #endregion