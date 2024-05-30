// #include "0:/lib/depLoader.ks"
@LazyGlobal off.

// *~ Dependencies ~* //
// #region
// #endregion


// *~ Variables ~* //
// #region
    // *- Local
    // #region
    local l_boosterMaxIdx to 0.
    local l_HotStage_Init to lex("ARMED", false, "ENGS", list(),"SPOOL", 0, "STG", -1).
    local l_currentStgEngs to list().
    
    // #endregion

    // *- Global
    // #region
    global g_AS_Armed   to false.
    global g_AS_Running to false.

    global g_BSTR_Armed to false.

    global g_BoosterActionDel to { return false.}.
    global g_BoosterArmed to false.
    global g_BoosterCheckDel to { return false.}.
    global g_BoosterResult to 0.

    global g_FairingsActionDel to { return false.}.
    global g_FairingsArmed to false.
    global g_FairingsCheckDel to { return false.}.
    global g_FairingsResult to 0.

    global g_HotStage   to l_HotStage_Init.
    global g_HS_Active  to false.
    global g_HS_Armed   to false.
    global g_HS_TS      to 0.

    global g_RCS_Armed to false.
    global g_RCS_Stage to -2.

    global g_ME_Stage to -2.
    global g_MECO_Armed to false.

    global g_SE_Stage to -2.
    global g_SECO_Armed to false.
    // #endregion
    // 

    // *- Local Anonymous Delegates
    // #region
    local l_ECODelegates to Lexicon(
        "MECO", { parameter _chkVal. return (not g_MECO_Armed).},
        "MET",  { parameter _chkVal. return MissionTime >= _chkVal.},
        "PE",   { parameter _chkVal. return Ship:Periapsis >= _chkVal.},
        "SECO", { parameter _chkVal. return (not g_SECO_Armed).}
    ).
    // #endregion

    // *- Global Anonymous Delegates
    // #region
    global g_AS_Action   to { return false.}.
    global g_AS_Check to { return false.}.

    global g_HS_Action   to { return false.}.
    global g_HS_Check to { return false.}.

    global g_BSTR_Act to { return false.}.
    global g_BSTR_Check to { return false.}.
    // #endregion
// #endregion


// *~ Functions ~* //
// #region

//  *- Autostaging helpers
    // #region

    // ArmAutoStaging :: (_stgLimit)<type> -> (ResultCode)<scalar>
    // Arms automatic staging based on current thrust levels. if they fall below 0.1, we stage
    global function ArmAutoStaging
    {
        parameter _stgLimit is g_StageLimit,
                  _conditionType is "MINTHR",
                  _conditionThresh is 0.01.

        local resultCode to 0.
        set g_StageLimit to _stgLimit.
        if Stage:Number <= g_StageLimit 
        {
            set resultCode to 2.
        }
        else
        {
            set g_AS_Check to { 
                if Stage:Number > g_StageLimit 
                {
                    return g_Conditions[_conditionType]:Call(_conditionThresh).
                }
                else
                {
                    DisableAutoStaging().
                }
                return false.
            }.
            set g_AS_Action   to { 
                if g_AS_Running
                {
                    if SafeStageWithUllage()
                    {
                        set g_ShipEngines to GetShipEnginesSpecs().
                        if Stage:Number <= g_StageLimit 
                        { 
                            set g_AS_Armed to false.
                        }
                        else
                        {
                            set g_NextEngines to GetNextEngines("1010").
                            if Ship:ModulesNamed("ModuleRCSFX"):Length > 0 RCS on. 
                        }
                        set g_AS_Running to false.
                        ClearScreen.
                        // OutInfo("UPDATING G_SHIPENGINES").
                        // else if g_ShipEngines:IGNSTG:HasKey(Stage:Number)
                        // {
                        //     if g_ShipEngines:IGNSTG[Stage:Number]:SEPSTG
                        //     {
                        //         wait 0.5. // Wait for the sep motors to do their thing
                        //         stage.
                        //     }
                        // }

                    }
                }
                else
                {
                    for m in Ship:ModulesNamed("ModuleRCSFX")
                    {
                        if m:Part:DecoupledIn >= Stage:Number - 1
                        {
                            m:SetField("RCS", False).
                        }
                    }
                    set g_AS_Running to true.
                }
                
                // wait until Stage:Ready.
                // stage.
                // wait 0.01. // Waiting for the engine state to update

                // if Stage:Number <= g_StageLimit { set g_AS_Armed to false.}
                // else if g_ShipEngines:IGNSTG:HasKey(Stage:Number)
                // {
                //     if g_ShipEngines:IGNSTG[Stage:Number]:SEPSTG
                //     {
                //         wait 0.5. // Wait for the sep motors to do their thing
                //         stage.
                //     }
                // }

                // set g_NextEngines to GetNextEngines("1000").
                // if Ship:ModulesNamed("ModuleRCSFX"):Length > 0 RCS on. 
            }.
            
            set g_AS_Armed to true.
            set resultCode to 1.
        }
        return resultCode.
    }

    global function DisableAutoStaging
    {
        set g_AS_Armed to false.
        set g_AS_Check to NoOp@.
        set g_AS_Action   to NoOp@.
        OutMsg("Autostaging disarmed!", cr()).
    }
    // #endregion


// *- Booster Staging
    // #region

    // ArmBoosterStaging
    //
    global function ArmBoosterStaging
    {
        parameter _boosterTag.

        local boosterObj to lex().
        local minIdx to 9.
        local regStr to _boosterTag + "\|Booster\|(AS\|)?\d".
        for dc in Ship:PartsTaggedPattern(regStr)
        {
            if dc:Stage >= g_StageLimit
            {
                local tagSpl to dc:Tag:Replace(" ",""):Split("|").
                local boosterIdx to tagSpl[tagSpl:Length - 1]:ToNumber().
                set l_boosterMaxIdx to Max(l_boosterMaxIdx, boosterIdx).
                set minIdx to Min(minIdx, boosterIdx).

                if boosterObj:HasKey(boosterIdx)
                {
                    boosterObj[boosterIdx]:DC:Add(dc).
                }
                else
                {
                    boosterObj:Add(boosterIdx, lex("DC", list(dc), "ENG", list(), "AS", tagSpl:Contains("AS"))).
                    
                }

                for eng in dc:PartsTagged("")
                {
                    if eng:IsType("Engine") and not g_EngRef:SEP:Contains(eng:Name)
                    {
                        boosterObj[boosterIdx]:ENG:Add(eng).
                    }
                }
            }
        }

        if boosterObj:Keys:Length > 0 
        {
            return list(true, CheckBoosterStagingConditions@:Bind(boosterObj):Bind(minIdx), StageBoosters@:Bind(boosterObj):Bind(minIdx)).
        }
        else
        {
            return list(false, g_NulCheckDel@, g_NulActionDel@).
        }
    }


    // CheckBoosterStagingConditions
    //
    local function CheckBoosterStagingConditions
    {
        parameter _boostObj,
                  _boostIdx is 0.

        local flameoutCount to 0.
        for eng in _boostObj[_boostIdx]:ENG 
        {
            if eng:Flameout set flameoutCount to flameoutCount + 1.
            OutStr("[{0} {1}]: {2} / {3}":Format(eng:Name, eng:UID, eng:Flameout, Round(eng:Thrust, 2))).
        }
        return flameoutCount = _boostObj[_boostIdx]:ENG:Length.
    }

    // StageBoosters
    //
    local function StageBoosters
    {
        parameter _boostObj,
                  _boostIdx is 0.

        for eng in _boostObj[_boostIdx]:ENG
        { 
            if eng:AllowShutdown
            {
                eng:Shutdown.
            }
        } 
        for dc in _boostObj[_boostIdx]:DC { 
            for p in dc:PartsNamedPattern("sep|spin")
            {
                if p:IsType("Engine") p:Activate.
            }
            DoEvent(dc:GetModule("ModuleAnchoredDecoupler"), "Decouple").
        }
        _boostObj:Remove(_boostIdx).
        
        local bstCheckDel  to g_NulCheckDel.
        local bstActionDel to g_NulActionDel.

        ClearScreen.
        if _boostObj:Keys:Length > 0
        {
            from { local i to _boostIdx + 1. local doneFlag to false.} until doneFlag or i > l_boosterMaxIdx step { set i to i + 1.} do
            {
                if _boostObj:HasKey(i)
                {
                    set bstCheckDel to CheckBoosterStagingConditions@:Bind(_boostObj):Bind(i).
                    set bstActionDel to StageBoosters@:Bind(_boostObj):Bind(i).
                    if _boostObj[i]:AS
                    {
                        for eng in _boostObj[i]:ENG
                        {
                            eng:Activate.
                        }
                    }
                    set doneFlag to true.
                }
            }
        }

        // OutInfo("UPDATING G_SHIPENGINES").
        set g_ShipEngines to GetShipEnginesSpecs().

        return list(_boostObj:Keys:Length > 0, bstCheckDel@, bstActionDel@).
}

    // #endregion


//  *- Hotstaging
    // #region

    // ArmHotStaging :: (input params)<type> -> (output params)<type>
    // Description
    global function ArmHotStaging
    {
        parameter _stgLim is g_StageLimit,
                  _checkVal  is -1.

        OutMsg("Arming hot stage").
        set g_HotStage to GetNextHotStage(_stgLim).
        local spoolTime to 0.
        if _checkVal < 0
        {
            if g_ShipEngines:IGNSTG:HasKey(g_HotStage:STG)
            {
                if g_ShipEngines:IGNSTG[g_HotStage:STG]:HasKey("STGMAXSPOOL") 
                {
                    set spoolTime to g_ShipEngines:IGNSTG[g_HotStage:STG]:STGMAXSPOOL.
                }
                else
                {
                    set spoolTime to 0.66.
                }
                set _checkVal to spoolTime * 1.25.
            }
            else
            {
                set _checkVal to 1.
            }
        }
        
        set g_HS_Check to {
            parameter __checkVal,
                      __curVal.

            if Stage:Number = g_HotStage:STG + 1
            {
                OutStr("_checkVal:  {0}":Format(__checkVal), g_TermHeight - 10).
                OutStr("HS ETA  : T{0}":Format(Round(__curVal - __checkVal, 2)), g_TermHeight - 9).
                return __curVal <= __checkVal.
            }
            return false.
        }.
        set g_HS_Check to g_HS_Check@:Bind(_checkVal).
        
        set g_HS_Action to DoHotStaging@.

        set g_HotStage:ARMED to true.
        set g_HotStage to g_HotStage.
        set g_HS_Armed to true.
    }

    global function RunHotStageSubroutine
    {
        parameter _btRem is GetActiveBurnTimeRemaining(GetActiveEngines(Ship, False)).

        if g_HS_Check:Call(_btrem)
        {
            if g_RCS_Armed
            {
                if Stage:Number - 1 = g_RCS_Stage
                {
                    RCS on.
                    set g_RCS_Armed to false.
                }
            }
            set g_HS_Active to g_HS_Action:Call().
            
            local hsEngs to Ship:PartsTaggedPattern("HotStage").
            local hsKeepAlive to false.
            from {local i to 0.} until i = hsEngs:Length or hsKeepAlive step { set i to i + 1.} do
            {
                local eng to hsEngs[i].
                if eng:Stage <= Stage:Number - 1
                {
                    set hsKeepAlive to true.
                }
            }

            return hsKeepAlive.
        }
        return true.
    }

    global function DisableHotStaging
    {
        set g_HS_Armed to false.
        set g_HS_Action   to NoOp@.
        set g_HS_Active   to false.
        set g_HS_Check to NoOp@.
    }

    // DoHotStaging
    global function DoHotStaging
    {
        local curLine to g_Line.
        set g_Line to Terminal:Height - 8.
        
        OutMsg("DoHotStaging").

        if ship:ModulesNamed("ModuleRCSFX"):Length > 0
        {
            OutMsg("RCS Found     ").
            RCS on.
        }
        set l_currentStgEngs to g_ActiveEngines:Copy.
        
        for eng in g_HotStage:ENGS
        {
            eng:Activate.
        }
        set g_HS_TS to Time:Seconds + g_HotStage:SPOOL.
        OutMsg("HOT STAGING START ").
        
        local hsEngThr  to -1.
        local curEngThr to 0.

        until Time:Seconds >= g_HS_TS or hsEngThr > curEngThr
        {
            set hsEngThr  to GetEngsThrust(g_HotStage:ENGS).
            set curEngThr to GetEngsThrust(l_currentStgEngs).
            OutMsg("HOT STAGING IGNITION  ", cr()).
            OutInfo("HSTHR / CURTHR: {0} / {1}   ":Format(Round(hsEngThr, 2), Round(curEngThr, 2)), cr()).
            OutInfo("TIMEOUT: {0} ":Format(Round(Time:Seconds - g_HS_TS, 2)), cr()).
        }

        OutMsg("HOT STAGING SEPERATION  ", cr()).
        wait until Stage:Ready.
        stage.
        set g_HS_Active to false.
        set g_HS_Armed  to false.
        clearScreen.

        OutInfo("UPDATING G_SHIPENGINES").
        set g_ShipEngines to GetShipEnginesSpecs().
        
        set g_NextEngines to GetNextEngines("1010").
        set g_Line to curLine.
        return false.
    }

    // GetHotStages
    global function GetHotStages
    {
        parameter _stgLim.

        OutMsg("GetHotStages", Terminal:Height - 5).
        local hotstageObj to lexicon().

        for eng in Ship:PartsTaggedPattern("HS|HotStage")
        {
            if eng:IsType("Engine") and eng:Stage >= _stgLim
            {
                local engStgId to eng:Stage:ToString.

                if not hotstageObj:HasKey(engStgId)
                {
                    hotStageObj:Add(engStgId, l_HotStage_Init).
                }
                hotstageObj[engStgId]:ENGS:Add(eng).
                set hotstageObj[engStgId]:ARMED to false.
                set hotstageObj[engStgId]:SPOOL to Max(hotstageObj[engStgId]:SPOOL, GetEngineSpoolTime(eng) * 1.325).
                set hotstageObj[engStgId]:STG   to eng:Stage.
            }
        }

        return hotstageObj.
    }

    // GetNextHotStage
    global function GetNextHotStage
    {
        parameter _stgLim.

        OutMsg("GetNextHotStage", Terminal:Height - 5).

        local hotstageObj to GetHotStages(_stgLim).
        local nextHotStage to lex("ARMED", false, "STG", -1).
        
        from { local stg to Stage:Number - 1.} until stg < _stgLim step { set stg to stg - 1.} do
        {
            if hotStageObj:HasKey(stg:ToString)
            {
                set nextHotStage to hotstageObj[stg:ToString].
                set nextHotStage:ARMED to stg = Stage:Number - 1.
                set nextHotStage:STG   to stg.
                break.
            }
        }
        return nextHotStage.
    }
    
    // #endregion

//  *- Engine Cutoff Routines
// #region

    // ArmMECO
    //
    global function ArmMECO
    {
        parameter _MEList is Ship:PartsTaggedPattern("Ascent\|MECO.*").

        local MECOArmed to false.
        local chkDel to { return true. }.
        local actDel to { return false. }.

        if _MEList:Length > 0
        {
            set g_ME_Stage to _MEList[0]:Stage.
            local chkSec to 999.
            local tagParts to _MEList[0]:Tag:Split("|").
            
            if tagParts:length > 2
            {
                set chkSec to ParseStringScalar(tagParts[2], chkSec).
            }

            set chkDel to { return MissionTime >= chkSec.}.
            set actDel to { 
                parameter __MEList.

                for eng in __MEList
                {
                    if eng:Ignition and not eng:Flameout
                    {
                        eng:Shutdown.
                    }
                }

                for p in Ship:PartsTaggedPattern("AS\|MECO")
                {
                    if p:IsType("Engine")
                    {
                        p:Activate.
                    }
                }

                for p in Ship:PartsTaggedPattern("DC\|MECO")
                {
                    if p:HasModule("ProceduralFairingDecoupler")
                    {
                        local m to p:GetModule("ProceduralFairingDecoupler").
                        DoEvent(m, "jettison fairing").
                    }
                    else if p:HasModule("ModuleDecouple")
                    {
                        local m to p:GetModule("ModuleDecouple").
                        DoEvent(m, "decouple").
                    }
                }
                set g_ActiveEngines to GetActiveEngines().

                return False.
            }.
            set actDel to actDel@:Bind(_MEList).

            set MECOArmed to true.
        }

        return list(MECOArmed, chkDel, actDel).
    }

    // ArmSECO
    //
    global function ArmSECO
    {
        parameter _SEList is Ship:PartsTaggedPattern("Ascent\|SECO.*").

        local SECOArmed to false.
        local chkVal to -1.
        local chkType to "".
        local chkDel to { return true. }.
        local actDel to { return false. }.

        if _SEList:Length > 0
        {
            set g_SE_Stage to _SEList[0]:Stage.

            local tagParts to _SEList[0]:Tag:Split("|").
            
            local processNextFlag to false.
            local stepCount to 0.

            for tPart in tagParts
            {
                print tPart.
                if tPart = "SECO"
                {
                    set processNextFlag to True.
                }
                else if processNextFlag
                {
                    if stepCount = 0
                    {
                        set chkType to tPart.
                        set stepCount to stepCount + 1.
                    }
                    else
                    {
                        set chkVal to ParseStringScalar(tPart, 0).
                        set chkDel to l_ECODelegates[chkType].
                        set chkDel to chkDel@:Bind(chkVal).
                        break.
                    }
                }
            }

            set actDel to { 
                parameter __SEList.

                OutStr("Hit SECO Action Delegate", g_TermHeight - 8).
                Breakpoint().
                for eng in __SEList
                {
                    if eng:Ignition and not eng:Flameout
                    {
                        eng:Shutdown.
                    }
                }
                set g_ActiveEngines to GetActiveEngines().
                return False.
            }.
            set actDel to actDel@:Bind(_SEList).

            set SECOArmed to true.
        }

        return list(SECOArmed, chkDel, actDel).
    }

// #endregion
//  *- Staging actions and conditions
    // #region

    // CheckUllage
    //
    local function CheckUllage
    {
        if g_NextEngines:Length = 0
        {
            set g_NextEngines to GetNextEngines("1000", 0).
        }

        if g_ShipEngines:IGNSTG:HasKey(g_NextEngines[0]:Stage)
        {
            local engObj to g_ShipEngines:IGNSTG[g_NextEngines[0]:Stage].
            if engObj:ULLAGE
            {
                return engObj:FuelStability >= 0.975.
            }
            else
            {
                return true.
            }
        }
        else 
        {
            return true.
        }
    }

    // SafeStage
    global function SafeStage
    {
        wait until Stage:Ready.
        stage.
        wait 0.01.
    }

    // SafeStageWithUllage
    global function SafeStageWithUllage
    {
        if Stage:Ready
        {
            OutStr("Stage ready", g_TermHeight - 5).
            if CheckUllage()
            {
                OutStr("Ullage Check Successful", g_TermHeight - 4).
                stage.
                wait 0.25.
                return true.
            }
        }
        return false.
    }
    // #endregion

// #endregion