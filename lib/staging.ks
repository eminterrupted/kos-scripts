// #include "0:/lib/depLoader.ks"
@LazyGlobal off.

// *~ Dependencies ~* //
// #region
// #endregion


// *~ Variables ~* //
// #region
    // *- Local
    // #region
    local l_HotStage_Init to lex("ARMED", false, "ENGS", list(),"SPOOL", 0, "STG", -1).
    // #endregion

    // *- Global
    // #region
    global g_AS_Armed   to false.
    global g_HotStage   to l_HotStage_Init.
    global g_HS_Active  to false.
    global g_HS_Armed   to false.
    global g_HS_TS      to 0.
    // #endregion
    // 

    // *- Local Anonymous Delegates
    // #region
    // #endregion

    // *- Global Anonymous Delegates
    // #region
    global g_AS_Act   to { return false.}.
    global g_AS_Check to { return false.}.

    global g_HS_Act   to { return false.}.
    global g_HS_Check to { return false.}.
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
            set g_AS_Check to { print "I'm autostagin checkin!" at (0, cr()). return g_Conditions[_conditionType]@:Bind(_conditionThresh).}.
            set g_AS_Act   to { SafeStage(). set g_AS_Act to false. if Stage:Number <= g_StageLimit { set g_AS_Armed to false.}}.
            set resultCode to 1.
        }
        return resultCode.
    }

    global function DisableAutoStaging
    {
        set g_AS_Armed to false.
        set g_AS_Check to NoOp@.
        set g_AS_Act   to NoOp@.
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

        print "Arming hot stage" at (25, 20).
        local burnTime to 0.
        local hs to GetNextHotStage(_stgLim).
        local spoolTime to 0.
        if _checkVal < 0
        {
            if g_ShipEngines:IGNSTG:HasKey(hs:STG)
            {
                set burnTime to g_ShipEngines:IGNSTG:STGBURNTIME.
                set spoolTime to g_ShipEngines:IGNSTG[hs:STG]:STGSPOOLTIME.
                set _checkVal to burnTime - (spoolTime * 1.25).
            }
            else
            {
                set _checkVal to 60.
            }
        }
        
        set g_HS_Check to {
            parameter __checkVal,
                      __curVal.

            print "I'm hotstage-checkin!" at (0, cr()).
            if Stage:Number = g_HotStage:STG + 1
            {
                print "HS ETA: T{0}  ":Format(Round(__curVal, 2)) at (0, cr()).
                return __curVal <= __checkVal.
            }
            return false.
        }.
        set g_HS_Check to g_HS_Check@:Bind(spoolTime * 1.26).
        
        set g_HS_Act to DoHotStaging@.

        set hs:ARMED to true.
        set g_HotStage to hs.
        set g_HS_Armed to true.
    }
    
    global function DisableHotStaging
    {
        set g_HS_Armed to false.
        set g_HS_Check to NoOp@.
        set g_HS_Act   to NoOp@.
    }

    // DoHotStaging
    global function DoHotStaging
    {
        if not g_HS_Active
        {
            for eng in g_HotStage:ENGS
            {
                eng:Activate.
            }
            set g_HS_TS to Time:Seconds + g_HotStage:SPOOL.
            set g_HS_Active to true.
        }
        else
        {
            if Time:Seconds >= g_HS_TS
            {
                wait until Stage:Ready.
                stage.
                set g_HotStage to l_HotStage_Init.
                set g_HS_Active to false.
                set g_HS_Armed to false.
            }
        }
        return g_HS_Active.
    }

    // GetHotStages
    global function GetHotStages
    {
        parameter _stgLim.

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
                set hotstageObj[engStgId]:SPOOL to Max(hotstageObj[engStgId]:SPOOL, GetEngineSpoolTime(eng)).
                set hotstageObj[engStgId]:STG   to eng:Stage.
            }
        }

        return hotstageObj.
    }

    // GetNextHotStage
    global function GetNextHotStage
    {
        parameter _stgLim.

        local hotstageObj to GetHotStages(_stgLim).
        local nextHotStage to lex().
        
        from { local stg to Stage:Number - 1.} until stg < _stgLim step { set stg to stg - 1.} do
        {
            if hotStageObj:HasKey(stg:ToString)
            {
                set nextHotStage to hotstageObj[stg:ToString].
                set nextHotStage:ARMED to stg = Stage:Number - 1.
                break.
            }
        }
        return nextHotStage.
    }
    
    // #endregion


//  *- Staging actions and conditions
    // #region

    // SafeStage
    local function SafeStage
    {
        // Check if current stage has RCS that should be disabled before staging.
        for m in Ship:ModulesNamed("ModuleRCSFX")
        {
            if m:Part:DecoupledIn >= Stage:Number - 1
            {
                m:SetField("RCS", False).
            }
        }
        wait until Stage:Ready.
        stage.
        wait 0.01.
    }
    // #endregion

// #endregion