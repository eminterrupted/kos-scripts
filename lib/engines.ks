@lazyGlobal off.

// *~ Dependencies ~* //
// #region
    // #include "0:/lib/globals.ks"
    // #include "0:/lib/util.ks"
    // #include "0:/lib/disp.ks"
    // #include "0:/lib/vessel.ks"
// #endregion


// *~ Variables ~* //
// #region
    // *- Local
    // #region
    // #endregion

    // *- Global
    // #region
    global g_ActiveEngines          to list().
    global g_ActiveEngines_Data     to Lexicon().
    global g_ActiveEngines_Data_Epoch to -1.
    global g_ActiveEngines_Specs     to Lexicon().

    global g_NextEngines            to list().
    global g_NextEngines_Data       to Lexicon().
    global g_NextEngines_Data_Epoch to -1.
    global g_NextEngines_Specs       to Lexicon().

    // global g_RehydrateEngines_Flag  to True.

    global g_ShipEngines            to GetShipEnginesByStage().
    global g_ShipEngines_Specs       to Lexicon().
    // #endregion

    // *- Object entry registrations
    // This adds engines to the part info global
    set g_PartInfo["Engines"] to Lexicon( 
        "SepRef", list(
            "ROSmallSpinMotor"              // Spin Motor (Small)
            ,"ROE-1204sepMotor"             // UA1204 Nosecone & Separation Motor
            ,"ROE-1205sepMotor"             // UA1205 Nosecone & Separation Motor
            ,"ROE-1206sepMotor"             // UA1206 Nosecone & Separation Motor
            ,"ROE-1207sepMotor"             // UA1207 Nosecone & Separation Motor
            ,"ROE-1208sepMotor"             // UA1208 Nosecone & Separation Motor
            ,"sepMotorSmall"                // Radial Separation Motor (Small)
            ,"sepMotor1"                    // Radial Separation Motor (Medium)
            ,"sepMotorLarge"                // Radial Separation Motor (Large)
            ,"SnubOtron"                    // Separation Motor (Small)
            ,"CREI_RO_IntSep_33"            // InternalRCS SRB (CREI 33%  Resize)
            ,"CREI_RO_IntSep_50"            // InternalRCS SRB (CREI 50%  Resize)
            ,"CREI_RO_IntSep_75"            // InternalRCS SRB (CREI 50%  Resize)
            ,"CREI_RO_IntSep_100"           // InternalRCS SRB (CREI 100% Resize)
            ,"CREI_RO_IntSep_166"           // InternalRCS SRB (CREI 166% Resize)
            ,"CREI_RO_IntSep_200"           // InternalRCS SRB (CREI 200% Resize)
            ,"B9_Engine_T2_SRBS"            // B9 Radial Sep Motor
            ,"B9_Engine_T2_SRBS_CREI_25"    // B9 Radial Sep Motor (CREI 25% Resize)
            ,"B9_Engine_T2_SRBS_CREI_34"    // B9 Radial Sep Motor (CREI 34% Resize)
            ,"B9_Engine_T2_SRBS_CREI_50"    // B9 Radial Sep Motor (CREI 50% Resize)
            ,"B9_Engine_T2_SRBS_CREI_67"    // B9 Radial Sep Motor (CREI 67% Resize)
            ,"B9_Engine_T2_SRBS_CREI_150"   // B9 Radial Sep Motor (CREI 150% Resize)
            ,"ROC-MercuryPosigradeBDB"      // RO Mercury Posigrade Kick Motor
            ,"CREI.RO.IntSep.33"            // InternalRCS SRB (CREI 33%  Resize)1
            ,"CREI.RO.IntSep.50"            // InternalRCS SRB (CREI 50%  Resize)
            ,"CREI.RO.IntSep.100"           // InternalRCS SRB (CREI 100% Resize)
            ,"CREI.RO.IntSep.75"           // InternalRCS SRB (CREI 100% Resize)
            ,"CREI.RO.IntSep.166"           // InternalRCS SRB (CREI 166% Resize)
            ,"CREI.RO.IntSep.200"           // InternalRCS SRB (CREI 200% Resize)
            ,"B9.Engine.T2.SRBS"            // B9 Radial Sep Motor
            ,"B9.Engine.T2.SRBS.CREI.25"    // B9 Radial Sep Motor (CREI 25% Resize)
            ,"B9.Engine.T2.SRBS.CREI.34"    // B9 Radial Sep Motor (CREI 34% Resize)
            ,"B9.Engine.T2.SRBS.CREI.50"    // B9 Radial Sep Motor (CREI 50% Resize)
            ,"B9.Engine.T2.SRBS.CREI.67"    // B9 Radial Sep Motor (CREI 67% Resize)
            ,"B9.Engine.T2.SRBS.CREI.150"   // B9 Radial Sep Motor (CREI 150% Resize)
            ,"ROE-TX280"                    // Saturn Ullage Motor
            ,"ROE.TX280"                    // Saturn Ullage Motor
            ,"ROE-Agena_Retro_TypeIII"      // Agena Ullage Motor
            ,"ROE-Agena.Retro.TypeIII"      // Agena Ullage Motor

            // ,"B9_Engine_T2A_SRBS"           // B9 Radial Retro Motor
            // ,"B9_Engine_T2A_SRBS_CREI_25"   // B9 Radial Retro Motor (CREI 25% Resize)
            // ,"B9_Engine_T2A_SRBS_CREI_50"   // B9 Radial Retro Motor (CREI 50% Resize)
            // ,"B9_Engine_T2A_SRBS_CREI_150"  // B9 Radial Retro Motor (CREI 150% Resize)
        )
        ,"RetroRef", list(
             "B9.Engine.T2A.SRBS"           // B9 Radial Retro Motor
            ,"B9.Engine.T2A.SRBS.CREI.25"    // B9 Radial Sep Motor (CREI 25% Resize)
            ,"B9.Engine.T2A.SRBS.CREI.34"    // B9 Radial Sep Motor (CREI 34% Resize)
            ,"B9.Engine.T2A.SRBS.CREI.50"    // B9 Radial Sep Motor (CREI 50% Resize)
            ,"B9.Engine.T2A.SRBS.CREI.67"    // B9 Radial Sep Motor (CREI 67% Resize)
            ,"B9.Engine.T2A.SRBS.CREI.150"   // B9 Radial Sep Motor (CREI 150% Resize)
        )
        ,"VernRef", list(
            "ROE-LR101"          // Atlas Vernier Motor (old)
            ,"ROE-LR101_2"       // Atlas Vernier Motor
            ,"ROE-LR101.2"       // Atlas Vernier Motor
            ,"ROE-LR101Inline"   // Thor / Delta Vernier Motor (old)
            ,"ROE-LR101Inline_2" // Thor / Delta Vernier Motor
            ,"ROE-LR101Inline.2" // Thor / Delta Vernier Motor
        )
    ).

    // This adds propellant collections
    set g_PropInfo["Solids"] to list(
        "PSPC"
        ,"PUPE"
        ,"NGNC"
    ).
// #endregion

// Initialization code
// #region
// HydrateEngineConfigs().
// #endregion


// *~ Functions ~* //
// #region
    // *- Engine Lists
    // #region
    
    // GetActiveEngines :: [(_ves)<Ship>] -> (ActiveEngines)<List)
    // Gets all engines that are active right now, no matter what stage they were
    // activated in. 
    // Valid _engType values are "All", "NoSRB" (excludes all solid rocket motors), and "NoSep" (excludes sep motors) 
    global function GetActiveEngines
    {
        parameter _ves is ship,
                  _engType is "all".

        if g_Debug OutDebug("GetActiveEngines for vessel (_engType[{0}])":Format(_engType)).

        local engList to list().

        if _engType = "all" // or eng:tag:length > 0
        {
            for eng in _ves:engines
            {
                if eng:Ignition and not eng:flameout
                {
                    engList:add(eng).
                }
            }
        }
        else if _engType = "NoBooster"
        {
            for eng in _ves:engines
            {
                // OutDebug("Eng in NoBooster: {0} | Decoupler: {1}":Format(eng, eng:Decoupler), 10).
                // wait 0.01.
                if eng:Ignition and not eng:flameout
                {
                    if eng:Decoupler <> "None"
                    {
                        if not eng:Decoupler:Tag:MatchesPattern(".*booster\|.*")
                        {
                            engList:add(eng).    
                        }
                    }
                    else
                    {
                        engList:add(eng).
                    }
                }
            }
        }
        else if _engType = "LastOfStage"
        {
            for eng in _ves:engines
            {
                if eng:Ignition and not eng:flameout
                {
                    if eng:Decoupler <> "None"
                    {
                        if not eng:Decoupler:Tag:MatchesPattern("(booster|.ECO)")
                        {
                            engList:add(eng).    
                        }
                    }
                    else 
                    {
                        engList:add(eng).    
                    }
                }
            }
        }
        else if _engType = "NoSRB"
        {
            for eng in _ves:engines
            {
                if eng:Ignition and not eng:flameout and not g_PropInfo:Solids:Contains(eng:ConsumedResources:Keys[0]) and not (eng:Decoupler:Tag:MatchesPattern("booster"))
                {
                    engList:add(eng).
                }
            }
        }
        else if _engType = "NoSep"
        {
            for eng in _ves:engines
            {
                if eng:Ignition and not eng:flameout and not g_PartInfo:Engines:SepRef:Contains(eng:Name)
                {
                    engList:add(eng).
                }
            
            }
        }
        return engList.
    }
    
    // GetEnginesDC :: _engList<List> -> bestDC<Decoupler>
    global function GetEnginesDC
    {
        parameter _engList.

        local minDCStg to Stage:Number.
        local bestDC to "".
        
        for eng in _engList
        {
            if eng:DecoupledIn < minDCStg
            {
                set minDCStg to eng:DecoupledIn.
                set bestDC to eng:Decoupler.
            }
        }
        return bestDC.
    }

    global function GetEnginesByStageLex
    {
        
    }

    // GetEnginesForStage :: (Stage Number)<scalar> -> (Engines activated by that stage)<List>
    // Returns engines for a given stage number
    global function GetEnginesForStage
    {
        parameter _stg, 
                  _type is "All",
                  _stgCheckType is 0. // -1: <=
                                      // 0: ==
                                      // 1: >=

        if g_Debug OutDebug("GetEnginesForStage (_stg[{0}]|_type[{1}])":Format(_stg, _type), CrDbg()).

        local engList to list().
        local checkDel to _EQ_@.

        if _stgCheckType <> 0 
        {
            set checkDel to choose _GE_@ if _stgCheckType > 0 else _LE_@. 
        }

        for eng in ship:engines
        {
            if checkDel:Call(eng:Stage, _stg)
            { 
                if _type = "All" 
                {
                    engList:Add(eng).
                }
                else if _type = "Main"
                {
                    if not g_PartInfo:Engines:SepRef:Contains(eng:Name) and eng:Tag:Length = 0
                    {
                        engList:Add(eng).
                    }
                }
                else if _type = "Sep"
                {
                    if g_PartInfo:Engines:SepRef:Contains(eng:Name) and eng:Tag:Length = 0
                    {
                        engList:Add(eng).
                    }
                }
                else if _type = "Booster"
                {
                    if eng:Decoupler:Tag:MatchesPattern("^Booster\|\d*")
                    {
                        engList:Add(eng).
                    }
                }
            }
        }
        return engList.
    }


    // GetNextEngines :: [_startAtStg<Scalar>] -> (engList)<List>
    // Returns the next set of engines, starting with the provided stage number (by default current stage - 1), and iterating towards 0 until it finds them (or doesn't)
    global function GetNextEngines
    {
        parameter _startAtStg is Stage:Number,
                  _engTypes is "All".

        if g_Debug OutDebug("GetNextEngines starting at stage [{0}]":Format(_startAtStg)).

        local engList to list().

        from { local i to _startAtStg - 1.} until i < 0 step { set i to i - 1.} do
        {
            set engList  to GetEnginesForStage(i, _engTypes).
            if engList:Length > 0 
            {
                return engList.
            }
        }
        return engList.
    }

    global function GetNextEngineStage
    {
        parameter _startStg is Stage:Number,
                  _engTypes is "ALL".

        local nextStg is 0.

        if g_Debug OutDebug("GetNextEngineStage (_startStg[{0}]|_engTypes[{1}])":Format(_startStg, _engTypes), crDbg()).
        for eng in Ship:Engines
        {
            if eng:Stage < _startStg
            {
                if _engTypes = "ALL"
                {
                    if not g_PartInfo:Engines:SepRef:Contains(eng:name) or eng:Tag:Length > 0
                    {
                        if eng:Ignitions <> 0 set nextStg to Max(nextStg, eng:Stage).
                    }
                }
            }
        }
        // OutDebug("[GetNextEngineStage][{0}] nextStg: [{1}]":Format(_startStg, nextStg), crDbg()).
        return nextStg.
    }

    global function GetNextUsableEngines
    {
        parameter _startStg is Stage:Number,
                  _stopStg is 0,
                  _engTypes is "NoSep".

        if g_Debug OutDebug("GetNextUsableEngines (_startStg[{0}]|_engTypes[{1}])":Format(_startStg, _engTypes), crDbg()).

        local maxStg is _startStg.
        local engLex to lexicon().

        for eng in Ship:Engines
        {
            if not g_PartInfo:Engines:SepRef:Contains(eng:name) or eng:Tag:Length > 0
            {
                if eng:Stage >= _stopStg
                {
                    if eng:Ignitions <> 0
                    {
                        set maxStg to Max(maxStg, eng:Stage).
                        if engLex:HasKey(eng:Stage) 
                        {
                            engLex[eng:Stage]:Add(eng).
                        }
                        else
                        {
                            engLex:Add(eng:Stage, list(eng)).
                        }
                    }
                }
            }
        }

        local nextStg to maxStg.
        from { local doneFlag to false. } until doneFlag or nextStg < _stopStg step { set nextStg to nextStg - 1.} do 
        {
            if engLex:HasKey(nextStg)
            {
                local engs to engLex[nextStg].
                local btRemaining to GetEnginesBurnTimeRemaining_Next(engs).
                if btRemaining > 0
                {
                    return engs.
                }
            }
        }
        
        // OutDebug("[GetNextEngineStage][{0}] nextStg: [{1}]":Format(_startStg, nextStg), crDbg()).
        return list().
    }

    //
    global function GetShipEnginesByStage
    {
        local engLex to Lexicon().
        for eng in Ship:Engines
        {
            if engLex:HasKey(eng:Stage)
            {
                engLex[eng:Stage]:Add(eng).
            }
            else
            {
                engLex:Add(eng:Stage, list(eng)).
            }
        }
        return engLex.
    }
    // #endregion

    // *- Engine Specifications
    // #region

    // GetEngineSpecs :: (_eng)<Engine> -> (engSpecObj)<Lexicon>
    // Returns a set of useful details about this engine such as spool time, ullage requirement, and max mass and fuel flows
    global function GetEngineSpecs
    {
        parameter _eng.

        if g_Debug OutDebug("GetEngineSpecs for [{0}:{1}:{2}]":Format(_eng:Stage, _eng:Name, _eng:UID), crDbg()).

        local m to _eng:GetModule("ModuleEnginesRF").
        local sepMotorCheck to (g_PartInfo:Engines:SepRef:Contains(_eng:Name) and _eng:Tag:Length = 0).
        
        local fuelStability to "Very Stable (100.0 %)".
        if m:HasField("propellant") {
            set fuelStability to GetField(m, "propellant", fuelStability).
        }
        local stabilityStrIdx to fuelStability:Find("(").
        local fuelStabilityScalar   to choose fuelStability:SubString(stabilityStrIdx + 1, fuelStability:Find("%") - stabilityStrIdx - 2):ToNumber(0.01) / 100 if fuelStability:Contains("%") else 0.01.

        local mixRatio to GetField(m, "mixture ratio", 1).
        // if g_resultCode = 2 { set mixRatio to 1. }

        local spoolTime to GetField(m, "effective spool-up time", 0.0000000000001).
        // if g_ResultCode = 2 { set spoolTime to 0.01. }

        local engSpecObj to Lexicon(
            "ActiveStage",      _eng:Stage
            ,"AllowRestart",    _eng:AllowRestart
            ,"AllowShutdown",   _eng:AllowShutdown
            ,"UID",             _eng:UID
            ,"DCStg",           _eng:DecoupledIn
            ,"EngConfig",       _eng:Config
            ,"EngName",         _eng:Name
            ,"EngTitle",        _eng:Title
            ,"FuelFlowMax",     _eng:MaxFuelFlow
            ,"FuelStability",   fuelStabilityScalar
            ,"HasGimbal",       _eng:HasGimbal
            ,"Ignitions",       GetField(m, "ignitions remaining")
            ,"IgnitionStg",     _eng:Stage
            ,"IsSepMotor",      sepMotorCheck
            ,"ISP",             _eng:ISP
            ,"ISPSeaLevel",     _eng:SeaLevelISP
            ,"ISPVacumm",       _eng:VacuumISP
            ,"MassFlowMax",     _eng:MaxMassFlow
            ,"MixRatio",        mixRatio
            ,"Modes",           _eng:Modes
            ,"MultiMode",       _eng:MultiMode
            ,"PressureFed",     _eng:PressureFed
            ,"Residuals",       GetField(m, "predicted residuals")
            ,"Resources",       _eng:ConsumedResources
            ,"SpoolTime",       spoolTime
            ,"ThrottleMin",     _eng:MinThrottle
            ,"ThrottleLock",    _eng:ThrottleLock
            ,"ThrustPoss",      _eng:PossibleThrust
            ,"ThrustAvail",     _eng:AvailableThrust
            ,"Ullage",          _eng:Ullage
            ,"UID",             _eng:UID
        ).
        return engSpecObj.
    }

    // GetEnginesSpecs :: (_engList)<List> -> (engsSpecs)<Lexicon>
    // Engine specs for a list of engines, keyed by the engine unique vessel identifier (UID)
    global function GetEnginesSpecs
    {
        parameter _engList.

        if g_Debug OutDebug("GetEnginesSpecs for [{0}] engines":Format(_engList:Length)).

        local fuelStabilityAvg  to 0.
        local fuelStabilityMin  to 1.
        local TotalResMass      to 0.
        local AggregateMassLex to Lexicon(
            "MAXMASSFLOW", 0
            ,"RESOURCES", Lexicon()
        ).
        
        local engsSpecs to Lexicon(
            "AvgExhVelo",           0
            ,"AvgISP",              0
            ,"BurnTimeRemaining",   0
            ,"FuelStabilityAvg",    0
            ,"FuelStabilityMin",    0
            ,"Ignitions",           0
            ,"SpoolTime",           0
            ,"StgMass",             0
            ,"StgShipMass",         0
            ,"StgThrust",           0
            ,"AllowRestart",        False
            ,"AllowShutdown",       False
            ,"IsSolid",             False
            ,"Multimode",           False
            ,"PressureFed",         False
            ,"PrimaryMode",         False
            ,"Ullage",              False
            ,"Modes",               list()
            ,"Configs",             Lexicon()
            ,"Engines",             Lexicon()
            ,"ThrottleEnabled",     list() // List of engine UIDs that have throttle capabilities; default is no throttle ability (throttle is locked to 100%)
        ).

        if _engList:Length = 0
        {
            return engsSpecs.
        }
        else
        {
            local totalThrust to 0.
            local ispWeighting to 0.
            
            
            from { local i to 0.} until i = _engList:Length step { set i to i + 1.} do
            {
                local eng to _engList[i].
                local engSpecs to GetEngineSpecs(eng).
                set engsSpecs["SpoolTime"] to max(engsSpecs:SpoolTime, engSpecs:SpoolTime).
                
                set engsSpecs["StgThrust"] to engsSpecs["StgThrust"] + engSpecs["ThrustPoss"].

                set fuelStabilityMin to min(engSpecs:FuelStability, fuelStabilityMin).
                set engsSpecs["FuelStabilityMin"] to fuelStabilityMin.
                
                set fuelStabilityAvg to ((engsSpecs:FuelStabilityAvg * i) + engSpecs:FuelStability) / (i + 1).
                set engsSpecs["FuelStabilityAvg"] to fuelStabilityAvg.

                if engSpecs["ThrottleMin"] < 1 
                {
                    engsSpecs["ThrottleEnabled"]:Add(eng:UID).
                }
                
                set AggregateMassLex:MAXMASSFLOW to AggregateMassLex:MAXMASSFLOW + eng:MaxMassFlow.
                set AggregateMassLex["Engines"] to Lexicon(
                    eng:Name, Lexicon()
                ).
                if eng:AllowRestart
                {
                    set engsSpecs:AllowRestart to True.
                }
                if eng:AllowShutdown
                {
                    set engsSpecs:AllowShutdown to True.
                }
                if eng:Ullage
                {
                    set engsSpecs:Ullage to True.
                }
                if eng:HasGimbal
                {
                    set engsSpecs:HasGimbal to True.
                }
                set engsSpecs:Ignitions      to choose 99 if eng:Ignitions < 0 else max(engsSpecs:Ignitions, eng:Ignitions).          

                for resName in eng:ConsumedResources:Keys
                {
                    local engResource to eng:ConsumedResources[resName].
                    local resMass to (engResource:Amount * engResource:Density).
                    local residuals to 0.
                    if eng:GetModule("ModuleEnginesRF"):HasField("Predicted Residuals")
                    {
                        // set resMass to resMass * (1 - GetField(eng:GetModule("ModuleEnginesRF"), "Predicted Residuals")).
                        // set resMass to resMass * (1 - GetField(eng:GetModule("ModuleEnginesRF"), "Predicted Residuals")).
                        set residuals to resMass * GetField(eng:GetModule("ModuleEnginesRF"), "Predicted Residuals").
                    }

                    if not AggregateMassLex:Engines:HasKey("Resources")
                    {
                        set TotalResMass to TotalResMass + resMass.
                        AggregateMassLex:Engines:Add(
                            "Resources", Lexicon(
                                resName, Lexicon(
                                    "Amount",           engResource:Amount
                                    ,"Capacity",        engResource:Capacity
                                    ,"Density",         engResource:Density
                                    ,"Mass",            resMass
                                    ,"MaxMassFlow",     engResource:MaxMassFlow
                                    ,"Ratio",           engResource:Ratio
                                    ,"TotalResiduals",  residuals
                                )
                            )
                        ).
                    }
                    else
                    {
                        if AggregateMassLex:Engines:Resources:HasKey(resName)
                        {
                            set AggregateMassLex:Engines:Resources[resName]:MaxMassFlow to AggregateMassLex:Engines:Resources[resName]:MaxMassFlow + engResource:MaxMassFlow.
                            set AggregateMassLex:Engines:Resources[resName]:TotalResiduals to AggregateMassLex:Engines:Resources[resName]:TotalResiduals + residuals.
                        }
                        else
                        {
                            AggregateMassLex:Engines:Resources:Add(
                                resName, Lexicon(
                                    "Amount",       engResource:Amount
                                    ,"Capacity",    engResource:Capacity
                                    ,"Density",     engResource:Density
                                    ,"Mass",        resMass
                                    ,"MaxMassFlow", engResource:MaxMassFlow
                                    ,"Ratio",       engResource:Ratio
                                    ,"TotalResiduals", residuals
                                )
                            ).
                        }
                    }
                }

                // ISP
                set totalThrust to totalThrust + eng:PossibleThrust.
                set ispWeighting to ispWeighting + (eng:PossibleThrust / eng:ISPAt(Body:ATM:AltitudePressure(Ship:Altitude))).

                engsSpecs:Engines:Add(eng:UID, engSpecs).
            }
            if totalThrust = 0
            {
                set engsSpecs:AvgISP to 0.00001.
            }
            else
            {
                // if g_Debug OutDebug("EffectiveISP  : " + allPossibleThrust / allWeightedThrust, crDbg()).
                set engsSpecs:AvgISP to choose 0 if totalThrust = 0 or ispWeighting = 0 else totalThrust / ispWeighting.
            }
            set engsSpecs:AvgExhVelo to Constant:g0 * engsSpecs:AvgISP.
            set engsSpecs:StgShipMass to GetStageMass(engsSpecs:Engines:Values[0]:IgnitionStg).

            if (TotalResMass > 0 and AggregateMassLex:MaxMassFlow > 0)
            {
                // local bt to 999999999.
                // for resName in AggregateMassLex:Engines:Resources:Keys
                // {
                //     local res to AggregateMassLex:Engines:Resources[resName].
                //     if res:Mass > 0 and res:MaxMassFlow > 0
                //     {
                //         set bt to Min(bt, (res:Mass - AggregateMassLex:Engines:Resources[resName]:TotalResiduals) / res:MaxMassFlow).
                //     }
                // }
                // set engsSpecs:BurnTimeRemaining to Round(bt, 2).
                set engsSpecs:BurnTimeRemaining to GetEnginesBurnTimeRemaining_Next(_engList).
            }

            return engsSpecs.
        }
    }

    // GetShipEnginesSpecs :: (_ves)(vessel) -> (engStgObj)(Engines Specs By Stage)
    // Returns engine specifications in a lexicon keyed by stage activation number.
    // Also denotes if a stage contains sep motors without tags (meaning they are 
    // true sepratrons; tagged motors perform non-seperation actions such as spin motors)
    global function GetShipEnginesSpecs
    {
        parameter _ves is Ship.

        local engStgObj  to Lexicon().
        local engList    to _ves:Engines.
        local isSepStage to false.
        local totalBurnTime to 0.

        from { local i to 0.} until i = engList:Length step { set i to i + 1.} do
        {
            local eng           to engList[i].
            local engSpecs      to GetEngineSpecs(eng).
            set isSepStage      to choose true if isSepStage or engSpecs:IsSepMotor else false.
            if engStgObj:HasKey(eng:Stage)
            {
                set engStgObj[eng:Stage]["EngSpecs"][eng:UID] to engSpecs.
                engStgObj[eng:Stage]["EngList"]:Add(eng).
                engStgObj[eng:Stage]["ENGUID"]:Add(eng:UID).
            }
            else
            {
                set engStgObj[eng:Stage] to Lexicon(
                    "EngSpecs", Lexicon(
                        eng:UID, engSpecs
                    )
                    ,"StgSpec", Lexicon()
                    ,"EngList", list(eng)
                    ,"ENGUID", list(eng:UID)
                ).
            }
            set engStgObj[eng:Stage]["IsSepStage"] to isSepStage.
        }

        for _stgKey in engStgObj:Keys
        {
            local stgEngs to engStgObj[_stgKey]:EngList.
            if stgEngs:Length > 0
            {
                set engStgObj[_stgKey]:StgSpec to GetEnginesSpecs(stgEngs).
                set totalBurnTime to totalBurnTime + engStgObj[_stgKey]:StgSpec:BurnTimeRemaining.
            }
        }
        set engStgObj["TotalBurnTime"] to totalBurnTime.
        
        return engStgObj.
    }
    // #endregion

    // *- Engine Specification Helpers
    // #region

    // Compare Engine Specs

    // GetPredictedBurnTime2 -- 
    global function GetPredictedBurnTime2
    {
        parameter _engs is g_NextEngines.

        local btRemaining to 999999.
        local dcStg to -1.
        local stgResLex to Lexicon().

        // Get engine mass flows and residuals
        for eng in _engs
        {
            set dcStg to eng:DecoupledIn.
            local residuals to 0.
            if eng:HasModule("ModuleEnginesRF")
            {
                local m to eng:GetModule("ModuleEnginesRF").
                set   residuals to GetField(m, "predicted residuals", 0).
            }

            for cres in eng:ConsumedResources:Values
            {
                local maxFlow to cres:MaxFuelFlow.
                
                if not stgResLex:HasKey(cres:Name)
                {
                    stgResLex:Add(cres:Name, Lexicon(
                        "Amount",           cres:Amount
                        ,"Density",         cres:Density
                        ,"MaxFlow",         maxFlow
                        ,"Engs",            Lexicon(eng:UID, list(maxFlow))
                        ,"Residuals",       residuals
                        )
                    ).
                }
                else
                {
                    stgResLex[cres:Name]:Engs:Add(eng:UID, list(maxFlow)).
                    set stgResLex[cres:Name]:MaxFlow   to stgResLex[cres:Name]:MaxFlow + maxFlow.
                    set stgResLex[cres:Name]:Residuals to stgResLex[cres:Name]:Residuals + residuals.
                }
            }
        }

        // Based on engine stage, find the resources. This wouldn't be necessary if ConsumedResources would actually work when the engine isn't active :(
        for res in Ship:Resources
        {
            if stgResLex:HasKey(res:Name)
            {
                local resAmt to 0.
                
                for p in res:Parts
                {
                    if p:DecoupledIn = dcStg
                    {
                        for pRes in p:Resources
                        {
                            if pRes:Name = res:Name
                            {
                                set resAmt to resAmt + pRes:Amount.
                            }
                        }
                    }
                }
                set btRemaining to Min(btRemaining, (resAmt * (1 - stgResLex[res:Name]:Residuals)) / stgResLex[res:Name]:MaxFlow).
            }
        }

        return btRemaining.
    }

    // GetPredictedBurnTime -- 
    global function GetPredictedBurnTime
    {
        parameter _engs is g_NextEngines.

        local btRemaining to 999999.
        local dcStg to -1.
        local stgResLex to Lexicon().

        // Get engine mass flows and residuals
        for eng in _engs
        {
            set dcStg to eng:DecoupledIn.
            local residuals to 0.00000000001.
            if eng:HasModule("ModuleEnginesRF")
            {
                local m to eng:GetModule("ModuleEnginesRF").
                set   residuals to 1 - GetField(m, "predicted residuals", 0).
            }

            for cres in eng:ConsumedResources:Values
            {
                if not stgResLex:HasKey(cres:Name)
                {
                    stgResLex:Add(cres:Name, Lexicon(
                        "Amount",           0
                        ,"Density",         cres:Density
                        ,"MaxMassFlow",     0
                        ,"Engs",            Lexicon()
                        )
                    ).
                }
                stgResLex[cres:Name]:Engs:Add(eng:UID, list(cres:MaxMassFlow * residuals)).
                set stgResLex[cres:Name]:MaxMassFlow to stgResLex[cres:Name]:MaxMassFlow + (cres:MaxMassFlow * residuals).
            }
        }

        // Based on engine stage, find the resources. This wouldn't be necessary if ConsumedResources would actually work when the engine isn't active :(
        local resList to list().
        list Resources in resList.
        for res in resList
        {
            if stgResLex:HasKey(res:Name)
            {
                local resAmt to 0.
                local resCap to 0.
                
                for p in res:Parts
                {
                    if p:DecoupledIn = dcStg
                    {
                        for pRes in p:Resources
                        {
                            if pRes:Name = res:Name
                            {
                                set resAmt to resAmt + pRes:Amount.
                                set resCap to resCap + pRes:Capacity.
                            }
                        }
                    }
                }

                set stgResLex[res:Name]:Amount to resAmt.
                set stgResLex[res:Name]:Capacity to resCap.
                
                set btRemaining to Min((stgResLex[res:Name]:Amount * stgResLex[res:Name]:Density) / stgResLex[res:Name]:MaxMassFlow, btRemaining).
            }
        }

        return btRemaining.
    }

    // GetTotalISP :: (<list>Engines) -> <scalar>
    // Returns averaged ISP for a list of engines
    global function GetTotalIsp
    {
        parameter _engList, 
                  _mode is "vac".

        local ispWeighting to 0.
        local totalThrust to 0.

        local engIsp to { 
            parameter __eng,
                      __mode.
            if __mode = "vac" return __eng:VISP.
            if __mode = "sl" return __eng:SLISP.
            if __mode = "cur" return __eng:ispAt(body:ATM:AltitudePressure(Ship:Altitude)).
        }.

        if _engList:Length > 0 
        {
            for eng in _engList
            {
                set totalThrust to totalThrust + eng:PossibleThrust.
                set ispWeighting to ispWeighting + (eng:PossibleThrust / engIsp(eng, _mode)).
            }

            // OutDebug("GetTotalIsp  ", crDbg(10)).
            // OutDebug("Engine Stage : " + _engList[0]:Stage, crDbg()).
            // OutDebug("totalThrust  : " + totalThrust, crDbg()).
            // OutDebug("ispWeighting : " + ispWeighting, crDbg()).

            if totalThrust = 0 or ispWeighting = 0
            {
                return 0.00001.
            }
            else
            {
                return totalThrust / ispWeighting.
            }
        }
        else
        {
            return 0.00001.
        }
    }

    // GetExhVel :: (<list>Engines) -> <scalar>
    // Returns the averaged exhaust velocity for a list of engines
    global function GetExhVel
    {
        parameter _engList, 
                  _mode is "vac".

        return Constant:g0 * GetTotalIsp(_engList, _mode).
    }
    // #endregion

    // *- Engine State
    // #region

    // GetEngineFuelStability :: [(_engList)<List[Engine]>] | [(_engList)<Engine>] -> ([FuelStabilityMin, FuelStabilityAvg])<List[Scalar]>
    // Returns the fuel stability of a given set of engines in a list format containing
    //  - [0] the minimum fuel stability value found amongst all engines
    //  - [1] the average value amongst all engines
    // Acceptable inputs are a list of engines, or a single engine object.
    global function GetEngineFuelStability
    {
        parameter _engList is g_NextEngines.

        local FuelStabilityAvg  to 0.
        local FuelStabilityMin  to 1.
        
        if _engList:IsType("Engine")
        {
            set _engList to list(_engList).
        }

        from { local i to 0.} until i = _engList:Length step { set i to i + 1.} do
        {
            local eng to _engList[i].
            local m to eng:GetModule("ModuleEnginesRF").

            local EngFuelStability      to GetField(m, "propellant").
            local StabilityStrIdx       to EngFuelStability:Find("(").
            local FuelStabilityScalar   to choose EngFuelStability:SubString(StabilityStrIdx + 1, EngFuelStability:Find("%") - StabilityStrIdx - 2):ToNumber(0.01) / 100 if EngFuelStability:Contains("%") else 0.01.

            set FuelStabilityAvg to ((FuelStabilityAvg * i) + FuelStabilityScalar) / (i + 1).
            set FuelStabilityMin to min(FuelStabilityScalar, FuelStabilityMin).
        }
        return List(FuelStabilityMin, FuelStabilityAvg).
    }
    // #endregion

    // *- Engine Performance
    // #region

    // GetEnginePerformanceData :: (_eng)<Engine> -> (engPerfObj)<Lexicon>
    // Returns current performance data for an engine.
    global function GetEnginePerformanceData
    {
        parameter _eng,
                  _altPres is -1. // Pass pre-computed value to avoid redundant atmosphere lookups when called in a loop

        local m                     to _eng:GetModule("ModuleEnginesRF").
        local altPres               to choose Body:ATM:AltitudePressure(Ship:Altitude) if _altPres < 0 else _altPres.
        local availThrustPres       to _eng:AvailableThrustAt(altPres).
        local sepMotorCheck         to (g_PartInfo:Engines:SepRef:Contains(_eng:Name) and _eng:Tag:Length = 0).
        // local thrustPct             to max(_eng:MaxThrust, .00001) / max(availThrustPres, 0.1).
        local thrustPct             to choose _eng:MaxThrust / availThrustPres if availThrustPres > 0 else 0.
        local fuelStability         to GetField(m, "propellant"). // GetField(m, "propellant").
        local stabilityStrIdx       to fuelStability:Find("(").
        local fuelStabilityScalar   to choose fuelStability:SubString(stabilityStrIdx + 1, fuelStability:Find("%") - stabilityStrIdx - 2):ToNumber(0.01) / 100 if fuelStability:Contains("%") else 0.01.

        local statusString          to TrimHTML(m:GetField("Status")).
        local failureCause          to choose "" if statusString = "Nominal" else GetField(m, "Cause").
        
        global function TrimHTML
        {
            parameter _str.

            local _spl to _str:Split(">").
            if _spl:Length > 1
            {
                set _str to _spl[1]:split("<")[0].
            }
            return _str.
        }

        //:ToNumber(1) / 100.
        local engPerfObj to Lexicon(
            "UID",              _eng:UID
            ,"EngName",         _eng:Name
            ,"EngTitle",        _eng:Title
            ,"FailureCause",    failureCause
            ,"Flameout",        _eng:Flameout
            ,"FuelFlow",        _eng:FuelFlow
            ,"FuelStability",   fuelStabilityScalar
            ,"Ignition",        _eng:Ignition
            ,"ISPAt",           _eng:ISPAt(altPres)
            ,"IsSepMotor",      sepMotorCheck
            ,"MassFlow",        GetField(m, "Mass Flow")
            ,"MaxThrust",       _eng:MaxThrust
            ,"Module",          m
            ,"Status",          statusString
            ,"Thrust",          _eng:Thrust
            ,"ThrustAvailPres", availThrustPres
            ,"ThrustPct",       thrustPct
        ).

        return engPerfObj.
    }

    // GetEnginesPerformanceData :: (_engList)<list> -> (aggEngPerfObj)<lexicon>
    // Wrapper that will return a lexicon containing all engPerfObjs for engines in the input list
    global function GetEnginesPerformanceData
    {
        parameter _engList,
                  _dataIn is Lexicon("_epoch", 0).

        if _dataIn:HasKey("_epoch")
        {
            if Round(Time:Seconds, 2) = _dataIn:_epoch
            {
                return _dataIn.
            }
        }
        
        local aggEngPerfObj to Lexicon(
            "Engines", Lexicon()
            ,"Resources", Lexicon()
            ,"SepStg", False
        ).

        local aggFailureCount       to 0.
        local aggISP                to 0.
        local aggISPAt              to 0.
        local aggMassFlow           to 0.
        local aggMassFlowMax        to 0.
        local aggMassFlowPct        to 0.
        local aggThrust             to 0.
        local aggThrustAvailPres    to 0.
        local ignStatus             to false.
        local thrustPct             to 0.
        local totalFuelMass         to 0.
        local totalResiduals        to 0.
        local normResiduals         to 0.
        local usableMassFlow        to 0.
        local usableFuelMass        to 0.
        local twr                   to 0.
        local aggFailureObj         to lexicon().
        local residualsObject       to lexicon().

        local burnTimeRemaining     to 999999999.

        local sepCheckFlag to true.

        // Compute once — same for all engines on the same ship at the same altitude
        local l_altPres to Body:ATM:AltitudePressure(Ship:Altitude).
        
        from { local i to 0.} until i = _engList:Length step { set i to i + 1.} do
        {
            local eng to _engList[i].
            local engLex    to GetEnginePerformanceData(eng, l_altPres).    

            local m to engLex:Module.
            local engResidual      to m:GetField("Predicted Residuals").
            local normedResidual   to engResidual * eng:MaxMassFlow.
            set totalResiduals to totalResiduals + engResidual.
            set normResiduals to normResiduals + normedResidual.
            if eng:MassFlow > 0 
            {
                set residualsObject[eng:uid] to lex(
                "Data", list(engResidual, normedResidual, eng:MaxMassFlow)
                ).
            }

            set aggMassFlow         to aggMassFlow + eng:MassFlow.
            set aggMassFlowMax      to aggMassFlowMax + eng:MaxMassFlow.
            set aggThrust           to aggThrust + engLex:Thrust.
            set aggThrustAvailPres  to aggThrustAvailPres + engLex:ThrustAvailPres.
            if (engLex:Ignition and not engLex:Flameout) set ignStatus to True.// set aggEngPerfObj["Ignition"] to True.
            if engLex:FailureCause:Length > 0
            {   
                set aggFailureCount to aggFailureCount + 1.
                if not aggFailureObj:HasKey(engLex:Status)
                {
                    set aggFailureObj[engLex:Status] to 
                    (
                        Lexicon(
                            eng:UID, list(
                                eng:Name,
                                engLex:FailureCause
                            )
                        )
                    ).
                }
                else
                {
                    aggFailureObj[engLex:Status]:Add(eng:UID, Lexicon("Name", eng:name, "Cause", engLex:FailureCause)).
                }
            }
                
            set aggEngPerfObj["Engines"][eng:UID] to engLex.

            if sepCheckFlag
            {   
                if g_PartInfo["Engines"]:SEPREF:Contains(eng:Name)
                {
                    if eng:tag:length >= 0
                    {
                        set sepCheckFlag to false.
                    }
                }
                else 
                {
                    set sepCheckFlag to false.
                }
            }         
            
            local totalFuel     to 0.
            local totalFuelFlow to 0.
            for res in eng:ConsumedResources:Values
            {
                local fuelMass to 0.
                // local resMass to 0.
                if not aggEngPerfObj:Resources:HasKey(res:Name) 
                {
                    set fuelMass to res:Amount * res:Density. 
                    set totalFuelFlow to totalFuelFlow + res:FuelFlow.
                    set totalFuel to totalFuel + res:Amount.
                    set totalFuelMass to totalFuelMass + fuelMass.
                    set usableFuelMass to fuelMass.
                    set usableMassFlow to res:MassFlow.
                    aggEngPerfObj:Resources:Add(res:Name, Lexicon(
                        "Amount", res:Amount,
                        "Capacity", res:Capacity, 
                        "FuelFlow", res:FuelFlow,
                        "FuelMass", fuelMass, 
                        "MassFlow", res:MassFlow, 
                        "MaxMassFlow", res:MaxMassFlow
                        )
                    ).
                }
                else
                {
                    set aggEngPerfObj:Resources[res:Name]:MassFlow to aggEngPerfObj:Resources[res:Name]:MassFlow + res:MassFlow.
                    set aggEngPerfObj:Resources[res:Name]:MaxMassFlow to aggEngPerfObj:Resources[res:Name]:MaxMassFlow + res:MaxMassFlow.
                }
            }
        }

        set aggEngPerfObj["SepStg"] to sepCheckFlag.

        set aggISPAt        to choose aggThrustAvailPres / aggMassFlowMax if aggThrustAvailPres > 0 and aggMassFlowMax > 0     else 0.
        set aggISP          to choose aggThrust / aggMassFlow             if aggThrust > 0          and aggMassFlow > 0        else 0.
        set aggMassFlowPct  to choose 0 if aggMassFlow = 0 or aggMassFlowMax = 0 else aggMassFlow / aggMassFlowMax.
        set thrustPct       to choose aggThrust / aggThrustAvailPres      if aggThrust > 0          and aggThrustAvailPres > 0 else 0.

        set totalResiduals to choose 0 if totalResiduals <= 0 else totalResiduals.// / _engList:Length.
        
        local newNormedResidual to 0.
        
        for uid in residualsObject:Keys
        {
            local engPct to residualsObject[uid]:Data[2] / aggMassFlowMax.
            set residualsObject[uid]["Pct"] to engPct.
            set residualsObject[uid]["Nrm"] to residualsObject[uid]:Data[0] * (1 - engPct).
            set newNormedResidual to newNormedResidual + residualsObject[uid]["Nrm"].
        }
        set newNormedResidual to choose newNormedResidual / residualsObject:Length if residualsObject:Length > 0 else 0.

        set usableFuelMass to usableFuelMass * (1 - newNormedResidual).
        set usableMassFlow to aggMassFlow.
        if usableFuelMass > 0 and usableMassFlow > 0
        {
            set burnTimeRemaining to (usableFuelMass / usableMassFlow).
        }

        set twr to choose 0 if aggThrust = 0 else aggThrust / Ship:Mass * GetLocalGravity().

        set aggEngPerfObj["AverageResiduals"]    to Round(totalResiduals, 5).
        set aggEngPerfObj["BurnTimeRemaining"]   to Round(burnTimeRemaining, 3).
        set aggEngPerfObj["Failures"]            to aggFailureCount.
        set aggEngPerfObj["FailureSet"]          to aggFailureObj.
        set aggEngPerfObj["Ignition"]            to ignStatus.
        set aggEngPerfObj["ISP"]                 to aggISP.
        set aggEngPerfObj["ISPAt"]               to aggISPAt.
        set aggEngPerfObj["MassFlow"]            to aggMassFlow.
        set aggEngPerfObj["MassFlowMax"]         to aggMassFlowMax.
        set aggEngPerfObj["MassFlowPct"]         to aggMassFlowPct.
        set aggEngPerfObj["Thrust"]              to aggThrust.
        set aggEngPerfObj["ThrustAvailPres"]     to aggThrustAvailPres.
        set aggEngPerfObj["ThrustPct"]           to thrustPct.
        set aggEngPerfObj["TotalUsableFuelMass"] to totalFuelMass.
        set aggEngPerfObj["TWR"]                 to twr.

        set aggEngPerfObj["_epoch"]              to Round(Time:Seconds, 2).

        return aggEngPerfObj.
    }



    // GetEnginesBurnTimeRemaining
    global function GetEnginesBurnTimeRemaining
    {
        parameter _engList.

        if g_Debug OutDebug("GetEnginesBurnTimeRemaining for [{0}] engines":Format(_engList:Length)).

        local AvgResiduals      to 0.
        local BurnTimeRemaining       to 999999.
        // local fuelMass          to 0.
        // local FuelFlow          to 0.
        // local MaxFuelFlow       to 0.
        local MaxResiduals      to 0.
        local NormalizedResiduals to 0.
        
        local EngBurnTimeLex to Lexicon(
            "Resources", Lexicon()
            ,"BurnTimeRemaining", BurnTimeRemaining
        ).

        // local res to "". // resource pointer
        
        // local TotalFuelFlow     to 0.
        // local TotalFuelAmount   to 0.
        // local TotalFuelCapacity to 0.
        // local TotalFuelMass     to 0.

        for eng in _engList
        {
            local m to eng:GetModule("ModuleEnginesRF").
            local engineResiduals to choose m:GetField("Predicted Residuals") if m:HasField("Predicted Residuals") else 0.
            // local FuelRatio to m:GetField("mixture ratio").

            set AvgResiduals to AvgResiduals + engineResiduals.
            set MaxResiduals to Max(MaxResiduals, engineResiduals).
            
            // for res in eng:ConsumedResources:Values
            // {
            local res to eng:ConsumedResources:Values[0].

            set NormalizedResiduals to ((engineResiduals * eng:MaxMassFlow) + NormalizedResiduals).

            if EngBurnTimeLex:Resources:Keys:Contains(res:Name)
            {
                // set EngBurnTimeLex:Resources[res:Name]:TotalFuelFlow to EngBurnTimeLex:Resources[res:Name]:TotalFuelFlow + res:FuelFlow.
                // set EngBurnTimeLex:Resources[res:Name]:MaxFuelFlow to EngBurnTimeLex:Resources[res:Name]:MaxFuelFlow + res:MaxFuelFlow.

                set engBurnTimeLex:Resources[res:Name]:MassFlow to engBurnTimeLex:Resources[res:Name]:MassFlow + res:MassFlow.
                set engBurnTimeLex:Resources[res:Name]:MaxMassFlow to engBurnTimeLex:Resources[res:Name]:MaxMassFlow + res:MaxMassFlow.

                // set engBurnTimeLex:Resources[res:Name]:MaxMassFlow to engBurnTimeLex:Resources[res:Name]:MassFlow + res:MaxMassFlow.
            }
            else
            {
                // EngBurnTimeLex:Resources:Add(res:Name, Lexicon("Object", res, "TotalFuelAmount", res:Amount, "TotalFuelFlow", res:FuelFlow, "MaxFuelFlow", res:MaxFuelFlow)).
                EngBurnTimeLex:Resources:Add(res:Name, Lexicon("Object", res, "TotalFuelMass", res:Amount * res:density, "TotalMassFlow", res:MassFlow, "MaxMassFlow", res:MaxMassFlow, "NrmResiduals", NormalizedResiduals)).

                // set fuelMass to res:amount * res:density.
                // set totalFuelMass to totalFuelMass + fuelMass.
                // engBurnTimeLex:Resources:Add(res:Name, Lexicon("Object", res, "FuelMass", fuelMass, "MassFlow", res:MassFlow, "MaxMassFlow", res:MaxMassFlow)).
            }
            
            // set TotalFuelAmount to EngBurnTimeLex:Resources[res:Name]:TotalFuelAmount.   // TotalFuelAmount + res:Amount.
            // set TotalFuelCapacity to EngBurnTimeLex:Resources[res:Name]:TotalFuelCapacity. // TotalFuelCapacity + res:Capacity.

            // set FuelFlow to FuelFlow + eng:FuelFlow.
            // set MaxFuelFlow to MaxFuelFlow + eng:MaxFuelFlow.
            // set FuelFlow to FuelFlow + eng:MassFlow.
            // set MaxFuelFlow to MaxFuelFlow + eng:MaxMassFlow.

        }
        // set NormalizedResiduals to NormalizedResiduals / _engList:Length.
        // set NormalizedResiduals to choose 1 - (NormalizedResiduals / _engList:Length) if NormalizedResiduals <> 0 and _engList:Length > 0 else 1.
        // set NormalizedResiduals to choose NormalizedResiduals / _engList:Length if NormalizedResiduals <> 0 and _engList:Length > 0 else 1.
        set NormalizedResiduals to max(NormalizedResiduals, 0.000001).

        // set AvgResiduals to choose 1 - (AvgResiduals / _engList:Length) if AvgResiduals <> 0 and _engList:Length > 0 else 1.
        set AvgResiduals to choose AvgResiduals / _engList:Length if AvgResiduals <> 0 and _engList:Length > 0 else 1.
        
        // if (totalFuelMass > 0 and FuelFlow > 0)
        // if (TotalFuelFlow > 0)
        if EngBurnTimeLex:Resources:Length > 0
        {
            // if EngBurnTimeLex:Resources:Values[0]:TotalFuelFlow > 0
            // {
                local btResList to list().
                // set res to EngBurnTimeLex:Resources:Values[0].
                for res in EngBurnTimeLex:Resources:Values
                {
                    // btResList:Add((res:FuelMass * maxResiduals) / res:MassFlow).
                    // btResList:Add((res:TotalFuelAmount * AvgResiduals) / res:TotalFuelFlow).
                    // btResList:Add((res:TotalFuelAmount * NormalizedResiduals) / res:TotalFuelFlow).
                    if res:TotalMassFlow > 0 
                    {
                        // set BurnTimeRemaining to Min(BurnTimeRemaining, btResList:Add((res:TotalFuelAmount * (1 - AvgResiduals)) / res:TotalFuelFlow)).
                        set BurnTimeRemaining to Min(BurnTimeRemaining, btResList:Add((res:TotalFuelMass * (1 - NormalizedResiduals)) / res:TotalMassFlow)).
                    }
                }
                // for _bt in btResList
                // {
                //     set BurnTimeRemaining to Min(BurnTimeRemaining, _bt).
                // }
            // }
        }
        else
        {
            return 0.
        }

        return Round(BurnTimeRemaining, 2).
    }


    // GetEnginesBurnTimeRemaining_Next
    global function GetEnginesBurnTimeRemaining_Next
    {
        parameter _engList.

        local maxMassFlow to 0.

        local burnTimeRemaining to 0.
        local burnTimeTotal     to 0.
        // local residualsAverage  to 0.

        if _engList:Length = 0
        {
            return burnTimeRemaining.
        }
        else
        {
            local engResourceLex to lexicon().
            // local normalizedResiduals to 0.
            // local engResidualsLex to lexicon().
            // local modNormMassFlow to 0.
            
            from { local i to 0.} until i >= _engList:Length step { set i to i + 1.} do
            {
                local eng to _engList[i].
                // local engCount to i + 1.

                local m to eng:GetModule("ModuleEnginesRF").
                local engineResiduals to m:GetField("Predicted Residuals"). 
                local residualMulti to 1 + engineResiduals.

                local modMixRatio to choose m:GetField("mixture ratio") if m:HasField("mixture ratio") else 1.
                local modMassFlow to m:GetField("mass flow").
                local engMassFlow to Max(eng:MassFlow, modMassFlow).
                local engMaxMassFlow to Max(engMassFlow, Max(eng:MaxMassFlow, modMassFlow)).
                
                local engNormMassFlow to engMassFlow * residualMulti.
                local engNormMaxMassFlow to engMaxMassFlow * residualMulti.
                local normMaxMassFlow to Max(engNormMassFlow, engNormMaxMassFlow).

                set maxMassFlow to maxMassFlow + engMaxMassFlow.


                from { local _i to 0. local doneFlag to false.} until _i >= eng:ConsumedResources:Values:Length or doneFlag step { set _i to _i + 1.} do
                {
                    local engResource to eng:ConsumedResources:Values[_i].
                    
                    // OutInfo("Processing Resource: {0}":Format(engResource:Name)).
                    local resMassFlow to Max(engResource:MassFlow * residualMulti, engNormMassFlow / modMixRatio).
                    local resMaxMassFlow to Max(engResource:MaxMassFlow * residualMulti, normMaxMassFlow * (1 / modMixRatio)).

                    // local resMaxMassFlow to Max(engResource:MaxMassFlow * engResource:Ratio, eng:MaxMassFlow * (1 / modMixRatio)).
                    
                    if engMassFlow > 0
                    {
                        if engResourceLex:HasKey(engResource:Name)
                        {
                            set engResourceLex[engResource:Name]:MassFlow to engResourceLex[engResource:Name]:MassFlow + resMassFlow.
                            set engResourceLex[engResource:Name]:MaxMassFlow to engResourceLex[engResource:Name]:MaxMassFlow + resMaxMassFlow.
                            set engResourceLex[engResource:Name]:AvailableFuelMass to engResource:Amount * engResource:Density.
                        }
                        else
                        {
                            set engResourceLex[engResource:Name] to lex(
                                "MassFlow", resMassFlow
                                ,"MaxMassFlow", resMaxMassFlow
                                ,"AvailableFuelMass", (engResource:Amount * engResource:Density)
                            ).
                        }
                        set doneFlag to true.
                    }
                }
                // set normalizedResiduals to normalizedResiduals + (engineResiduals * engMaxMassFlow).
                // set residualsAverage to (residualsAverage + engineResiduals) / _engList:Length.
            }

            // set normalizedResiduals to (normalizedResiduals / maxMassFlow) / _engList:Length.
            
            set burnTimeRemaining to 0.
            
            for res in engResourceLex:Values
            {
                // local usableFuelMass to res:AvailableFuelMass * (1 - normalizedResiduals).
                set burnTimeRemaining to Max(burnTimeRemaining, res:AvailableFuelMass / res:MassFlow).
            }
            
            set burnTimeTotal to choose 999999 if burnTimeRemaining = 0 else burnTimeRemaining.
            // set burnTimeTotal to choose 0 if burnTimeRemaining = 0 else burnTimeRemaining / _engList:Length.
            // set burnTimeTotal to choose 999999 if burnTimeTotal = 0 else burnTimeTotal.
            // OutInfo("GetEnginesBurnTimeRemainingExit: {0}s":Format(Round(burnTimeTotal, 2))).
            return burnTimeTotal.
        }
    }
    // #endregion

    // *- Engine Config Hydration
    // #region
    
    // HydrateEngineConfigs
    // Reads file at 0:/data/ref/eng.cfg if present
    // If not present, sets a flag that these calculations must be done via fuel burn estimates. 
    // Parameter to optionally write any new types present in g_EngineConfgs after g_ShipEngines hydration to file
    local function HydrateEngineConfigs
    {
        parameter _cacheConfigs to false.

        local cfgSet to lex().

        if exists(l_EngCfgPath)
        {
            local cachedCfgs to Open(l_EngCfgPath):ReadAll:String:Split(char(10)).
            for cfg in cachedCfgs
            {
                local cfgParts to cfg:Split(",").
                cfgSet:Add(cfgParts[0], list(cfgParts[1]:ToNumber(-1), cfgParts[2]:ToNumber(0))).
            }
        }
        set g_EngineConfigs to cfgSet.
    }
    // @endregion

    // *- Event Handlers
    // #region
    global function SetupMECOEventHandler
    {
        parameter _execStr to "Ascent".

        local MECO_Engine_List to Ship:PartsTaggedPattern("{0}\|MECO\|\d*(\.\d*)*":Format(_execStr)).
        local MECO_EngineID_Sets to Lexicon().
        local MECO_EngineID_List to List().
        local resultFlag to False.

        local Current_MECO_ID to 999999.
        
        for p in MECO_Engine_List 
        { 
            local ecoMET to p:Tag:Split("|")[2]:ToNumber(0).

            if ecoMET > 0 
            {
                if MECO_EngineID_Sets:HasKey(ecoMET)
                {
                    MECO_EngineID_Sets[ecoMET]:Add(p).
                }
                else
                {
                    MECO_EngineID_Sets:Add(ecoMET, list(p)).
                }

                set Current_MECO_ID to Min(Current_MECO_ID, ecoMET).
            }
        }
        
        local MECO_Time    to Current_MECO_ID.

        global MECO_Action_Counter to 0.

        if MECO_Time > 0 
        {
            local checkDel to 
            { 
                parameter _params is list(). 
                
                OutInfo("MECO T-{0}s ":Format(Round(MissionTime - _params[1], 2)), 1). 
                return MissionTime >= _params[1].
            }.

            local actionDel to 
            {
                parameter _params is list(). 
                
                set MECO_Action_Counter to MECO_Action_Counter + 1. 
                
                for eng in Ship:PartsTaggedPattern("Ascent\|MECO\|{0}":Format(_params[1]))
                {
                    if eng:Ignition and not eng:flameout
                    {
                        eng:shutdown.
                        if eng:HasGimbal 
                        {
                            DoAction(eng:Gimbal, "Lock Gimbal", true).
                        }
                        set eng:tag to "".
                    }
                }
                set g_ActiveEngines to GetActiveEngines(ship, "NoBooster").
                set g_ActiveEngines_Specs to GetEnginesSpecs(g_ActiveEngines).
                set g_ActiveEngines_Data to GetEnginesPerformanceData(g_ActiveEngines).
                
                wait 0.01. 

                if Ship:PartsTaggedPattern("^Ascent\|MECO\|\d*(\.\d*)*"):Length > 0
                {
                    UnregisterLoopEvent("MECO").
                    return SetupMECOEventHandler().
                }
                else
                {
                    OutInfo("", 1).
                    set g_MECOArmed to False.
                    return g_MECOArmed.
                }
            }.
                
            local MECO_Event to CreateLoopEvent("MECO", "EngineCutoff", list(MECO_EngineID_List, Current_MECO_ID), checkDel@, actionDel@).
            if RegisterLoopEvent(MECO_Event)
            {
                set resultFlag to True.
                // OutDebug("MECO Handler Created").
            }
        }
        return resultFlag.
    }
    // #endregion
// #endregion
