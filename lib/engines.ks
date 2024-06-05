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
    global g_ActiveEngines_Data     to lexicon().
    global g_ActiveEngines_Spec     to lexicon().

    global g_NextEngines            to list().
    global g_NextEngines_Data       to lexicon().
    global g_NextEngines_Spec       to lexicon().

    global g_ShipEngines_Spec       to lexicon().
    // #endregion

    // *- Object entry registrations
    // This adds engines to the part info global
    set g_PartInfo["Engines"] to lexicon( 
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
            ,"CREI_RO_IntSep_100"           // InternalRCS SRB (CREI 100% Resize)
            ,"CREI_RO_IntSep_166"           // InternalRCS SRB (CREI 166% Resize)
            ,"CREI_RO_IntSep_200"           // InternalRCS SRB (CREI 200% Resize)
            ,"B9_Engine_T2_SRBS"            // B9 Radial Sep Motor
            ,"B9_Engine_T2_SRBS_CREI_25"    // B9 Radial Sep Motor (CREI 25% Resize)
            ,"B9_Engine_T2_SRBS_CREI_50"    // B9 Radial Sep Motor (CREI 50% Resize)
            ,"B9_Engine_T2_SRBS_CREI_150"   // B9 Radial Sep Motor (CREI 150% Resize)
            ,"ROC-MercuryPosigradeBDB"      // RO Mercury Posigrade Kick Motor
            ,"CREI.RO.IntSep.33"            // InternalRCS SRB (CREI 33%  Resize)1
            ,"CREI.RO.IntSep.50"            // InternalRCS SRB (CREI 50%  Resize)
            ,"CREI.RO.IntSep.100"           // InternalRCS SRB (CREI 100% Resize)
            ,"CREI.RO.IntSep.166"           // InternalRCS SRB (CREI 166% Resize)
            ,"CREI.RO.IntSep.200"           // InternalRCS SRB (CREI 200% Resize)
            ,"B9.Engine.T2.SRBS"            // B9 Radial Sep Motor
            ,"B9.Engine.T2.SRBS.CREI.25"    // B9 Radial Sep Motor (CREI 25% Resize)
            ,"B9.Engine.T2.SRBS.CREI.50"    // B9 Radial Sep Motor (CREI 50% Resize)
            ,"B9.Engine.T2.SRBS.CREI.150"   // B9 Radial Sep Motor (CREI 150% Resize)
            // ,"B9_Engine_T2A_SRBS"           // B9 Radial Retro Motor
            // ,"B9_Engine_T2A_SRBS_CREI_25"   // B9 Radial Retro Motor (CREI 25% Resize)
            // ,"B9_Engine_T2A_SRBS_CREI_50"   // B9 Radial Retro Motor (CREI 50% Resize)
            // ,"B9_Engine_T2A_SRBS_CREI_150"  // B9 Radial Retro Motor (CREI 150% Resize)
        )
        ,"RetroRef", list(
            "B9_Engine_T2A_SRBS"           // B9 Radial Retro Motor
            ,"B9_Engine_T2A_SRBS_CREI_25"   // B9 Radial Retro Motor (CREI 25% Resize)
            ,"B9_Engine_T2A_SRBS_CREI_50"   // B9 Radial Retro Motor (CREI 50% Resize)
            ,"B9_Engine_T2A_SRBS_CREI_150"  // B9 Radial Retro Motor (CREI 150% Resize)
            ,"B9.Engine.T2A.SRBS"           // B9 Radial Retro Motor
            ,"B9.Engine.T2A.SRBS.CREI.25"   // B9 Radial Retro Motor (CREI 25% Resize)
            ,"B9.Engine.T2A.SRBS.CREI.50"   // B9 Radial Retro Motor (CREI 50% Resize)
            ,"B9.Engine.T2A.SRBS.CREI.150"  // B9 Radial Retro Motor (CREI 150% Resize)
        )
    ).

    // This adds propellant collections
    set g_PropInfo["Solids"] to list(
        "PSPC"
        ,"PUPE"
        ,"NGNC"
    ).
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

        local engList to list().

        for eng in _ves:engines
        {
            if _engType = "all" or eng:tag:length > 0
            {
                if eng:Ignition and not eng:flameout
                {
                    engList:add(eng).
                }
            }
            else if _engType = "NoBooster"
            {
                // OutDebug("Eng in NoBooster: {0} | Decoupler: {1}":Format(eng, eng:Decoupler), 10).
                // wait 0.01.
                if eng:Decoupler <> "None"
                {
                    if eng:Decoupler:Tag:MatchesPattern("^Booster.*")
                    {
                    }
                    else
                    {
                        if eng:Ignition and not eng:flameout
                        {
                            engList:add(eng).    
                        }
                    }
                }
            }
            else if _engType = "NoSRB"
            {
                if eng:Ignition and not eng:flameout and not g_PropInfo:Solids:Contains(eng:ConsumedResources:Keys[0])
                {
                    engList:add(eng).
                }
            }
            else if _engType = "NoSep"
            {
                if eng:Ignition and not eng:flameout and not g_PartInfo:Engines:SepRef[eng:Name]
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

    // GetEnginesForStage :: (Stage Number)<scalar> -> (Engines activated by that stage)<List>
    // Returns engines for a given stage number
    global function GetEnginesForStage
    {
        parameter _stg, 
                  _type is "All",
                  _stgCheckType is 0. // -1: <=
                                      // 0: ==
                                      // 1: >=

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
        parameter _startAtStg is Stage:Number.

        local engList to list().

        from { local i to _startAtStg - 1.} until i <= 0 step { set i to i - 1.} do
        {
            set engList  to GetEnginesForStage(i).
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

        // OutDebug("[GetNextEngineStage][{0}] _engTypes: [{1}]":Format(_startStg, _engTypes), crDbg()).
        for eng in Ship:Engines
        {
            if eng:Stage < _startStg
            {
                if _engTypes = "ALL"
                {
                    if not g_PartInfo:Engines:SepRef:Contains(eng:name) or eng:Tag:Length > 0
                    {
                        if eng:Ignitions > 0 set nextStg to Max(nextStg, eng:Stage).
                    }
                }
            }
        }
        // OutDebug("[GetNextEngineStage][{0}] nextStg: [{1}]":Format(_startStg, nextStg), crDbg()).
        return nextStg.
    }
    // #endregion

    // *- Engine Specifications
    // #region

    // GetEngineSpecs :: (_eng)<Engine> -> (engSpecObj)<Lexicon>
    // Returns a set of useful details about this engine such as spool time, ullage requirement, and max mass and fuel flows
    global function GetEngineSpecs
    {
        parameter _eng.

        local m to _eng:GetModule("ModuleEnginesRF").
        local sepMotorCheck to (g_PartInfo:Engines:SepRef:Contains(_eng:Name) and _eng:Tag:Length = 0).
        
        local fuelStability         to GetField(m, "propellant"). // GetField(m, "propellant").
        local stabilityStrIdx       to fuelStability:Find("(").
        local fuelStabilityScalar   to choose fuelStability:SubString(stabilityStrIdx + 1, fuelStability:Find("%") - stabilityStrIdx - 2):ToNumber(0.01) / 100 if fuelStability:Contains("%") else 0.01.

        local mixRatio to GetField(m, "mixture ratio").
        if g_resultCode = 2 { set mixRatio to 1. }

        local spoolTime to GetField(m, "effective spool-up time").
        if g_ResultCode = 2 { set spoolTime to 0.01. }

        local engSpecObj to lexicon(
            "ActiveStage",      _eng:Stage
            ,"AllowRestart",    _eng:AllowRestart
            ,"AllowShutdown",   _eng:AllowShutdown
            ,"CID",              _eng:CID
            ,"EngConfig",       _eng:Config
            ,"EngName",         _eng:Name
            ,"EngTitle",        _eng:Title
            ,"FuelFlowMax",     _eng:MaxFuelFlow
            ,"FuelStability",   fuelStabilityScalar
            ,"HasGimbal",       _eng:HasGimbal
            ,"Ignitions",       GetField(m, "ignitions remaining")
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
        ).
        return engSpecObj.
    }

    // GetEnginesSpecs :: (_engList)<List> -> (engsSpecs)<Lexicon>
    // Engine specs for a list of engines, keyed by the engine unique vessel identifier (CID)
    global function GetEnginesSpecs
    {
        parameter _engList.

        local fuelStabilityAvg  to 0.
        local fuelStabilityMin  to 1.
        local TotalResMass      to 0.
        local AggregateMassLex to lexicon(
            "MAXMASSFLOW", 0
            ,"RESOURCES", lexicon()
        ).
        
        local engsSpecs to lexicon(
            "SpoolTime",            0
            ,"FuelStabilityAvg",    0
            ,"FuelStabilityMin",    0
            ,"EstBurnTime",         0
            ,"StgThrust",           0
            ,"Ignitions",           0
            ,"AllowRestart",        False
            ,"AllowShutdown",       False
            ,"AllowThrottle",       False
            ,"HasGimbal",           False
            ,"Multimode",           False
            ,"PressureFed",         False
            ,"PrimaryMode",         False
            ,"Ullage",              False
            ,"Modes",               list()
            ,"Configs",             lexicon()
            ,"Engines",             lexicon()
        ).

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

            set AggregateMassLex:MAXMASSFLOW to AggregateMassLex:MAXMASSFLOW + eng:MaxMassFlow.
            set AggregateMassLex["Engines"] to lexicon(
                eng:Name, lexicon()
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
                if eng:GetModule("ModuleEnginesRF"):HasField("Predicted Residuals")
                {
                    set resMass to resMass * (1 - GetField(eng:GetModule("ModuleEnginesRF"), "Predicted Residuals")).
                }

                if not AggregateMassLex:Engines:HasKey("Resources")
                {
                    set TotalResMass to TotalResMass + resMass.
                    AggregateMassLex:Engines:Add(
                        "Resources", lexicon(
                            resName, lexicon(
                                "Amount",       engResource:Amount
                                ,"Capacity",    engResource:Capacity
                                ,"Density",     engResource:Density
                                ,"Mass",        resMass
                                ,"MaxMassFlow", engResource:MaxMassFlow
                                ,"Ratio",       engResource:Ratio
                            )
                        )
                    ).
                }
                else
                {
                    if AggregateMassLex:Engines:Resources:HasKey(resName)
                    {
                        set AggregateMassLex:Engines:Resources[resName]:MaxMassFlow to AggregateMassLex:Engines:Resources[resName]:MaxMassFlow + engResource:MaxMassFlow.
                    }
                    else
                    {
                        AggregateMassLex:Engines:Resources:Add(
                            resName, lexicon(
                                "Amount",       engResource:Amount
                                ,"Capacity",    engResource:Capacity
                                ,"Density",     engResource:Density
                                ,"Mass",        resMass
                                ,"MaxMassFlow", engResource:MaxMassFlow
                                ,"Ratio",       engResource:Ratio
                            )
                        ).
                    }
                }
            }
            engsSpecs:Engines:Add(eng:CID, engSpecs).
        }

        if (TotalResMass > 0 and AggregateMassLex:MaxMassFlow > 0)
        {
            local btResList to list().
            for res in AggregateMassLex:Engines:Resources:Values
            {
                btResList:Add(res:Mass / res:MaxMassFlow).
            }
            local bt to 999999999.
            from { local i to 0.} until i = btResList:Length step { set i to i + 1.} do
            {
                set bt to Min(bt, btResList[i]).
            }
            set engsSpecs:EstBurnTime to Round(bt, 2).
        }
        return engsSpecs.
    }

    // GetShipEnginesSpecs :: (_ves)(vessel) -> (engStgObj)(Engines Specs By Stage)
    // Returns engine specifications in a lexicon keyed by stage activation number.
    // Also denotes if a stage contains sep motors without tags (meaning they are 
    // true sepratrons; tagged motors perform non-seperation actions such as spin motors)
    global function GetShipEnginesSpecs
    {
        parameter _ves is Ship.

        local engStgObj  to lexicon().
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
                set engStgObj[eng:Stage]["EngSpecs"][eng:CID] to engSpecs.
                engStgObj[eng:Stage]["EngList"]:Add(eng).
            }
            else
            {
                set engStgObj[eng:Stage] to lexicon(
                    "EngSpecs", lexicon(
                        eng:CID, engSpecs
                    )
                    ,"StgSpec", lexicon()
                    ,"EngList", list(eng)
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
                set totalBurnTime to totalBurnTime + engStgObj[_stgKey]:StgSpec:EstBurnTime.
            }
        }
        set engStgObj["TotalBurnTime"] to totalBurnTime.

        return engStgObj.
    }
    // #endregion

    // *- Engine Specification Helpers
    // #region
    // GetTotalISP :: (<list>Engines) -> <scalar>
    // Returns averaged ISP for a list of engines
    global function GetTotalIsp
    {
        parameter _engList, 
                  _mode is "vac".

        local relThr to 0.
        local totThr to 0.

        local engIsp to { 
            parameter eng. 
            if _mode = "vac" return eng:VISP.
            if _mode = "sl" return eng:SLISP.
            if _mode = "cur" return eng:ispAt(body:ATM:AltitudePressure(Ship:Altitude)).
        }.

        if _engList:Length > 0 
        {
            for eng in _engList
            {
                set totThr to totThr + eng:PossibleThrust.
                set relThr to relThr + (eng:PossibleThrust / engIsp(eng)).
            }

            // clrDisp(30).
            // print "GetTotalIsp                    " at (2, 30).
            // print "stg: " + stg.
            // print "totThr: " + totThr at (2, 31).
            // print "relThr: " + relThr at (2, 32).
            //Breakpoint().
            if totThr = 0
            {
                return 0.00001.
            }
            else
            {
                return totThr / relThr.
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
        parameter _eng.

        local m                     to _eng:GetModule("ModuleEnginesRF").
        local altPres               to Body:ATM:AltitudePressure(Ship:Altitude).
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
        local engPerfObj to lexicon(
            "CID",              _eng:CID
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
        parameter _engList.

        local aggEngPerfObj to lexicon(
            "Engines", lexicon()
            ,"Resources", lexicon()
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
        local averageResiduals      to 0.
        local thrustPct             to 0.
        local totalFuelMass         to 0.
        local twr                   to 0.
        local aggFailureObj         to lexicon().

        local burnTimeRemaining     to 999999999.

        from { local i to 0.} until i = _engList:Length step { set i to i + 1.} do
        {
            local eng to _engList[i].
            // if eng:Decoupler <> "None" and eng:Decoupler:Tag:MatchesPattern("booster")
            // {
            local engLex    to GetEnginePerformanceData(eng).    

            local m to engLex:Module.
            local engResiduals to m:GetField("Predicted Residuals").
            set averageResiduals to averageResiduals + engResiduals.

            set aggThrust           to aggThrust + engLex:Thrust.
            set aggThrustAvailPres  to aggThrustAvailPres + engLex:ThrustAvailPres.
            set aggMassFlow         to aggMassFlow + eng:MassFlow.
            set aggMassFlowMax      to aggMassFlowMax + eng:MaxMassFlow.
            if (engLex:Ignition and not engLex:Flameout) set aggEngPerfObj["Ignition"] to True.
            if engLex:FailureCause:Length > 0
            {   
                set aggFailureCount to aggFailureCount + 1.
                if not aggFailureObj:HasKey(engLex:Status)
                {
                    set aggFailureObj[engLex:Status] to 
                    (
                        lexicon(
                            eng:CID, list(
                                eng:Name,
                                engLex:FailureCause
                            )
                        )
                    ).
                }
                else
                {
                    aggFailureObj[engLex:Status]:Add(eng:CID, lexicon("Name", eng:name, "Cause", engLex:FailureCause)).
                }
            }
                
            set aggEngPerfObj["Engines"][eng:CID] to engLex.

            if aggEngPerfObj["SepStg"] 
            {
                if g_PartInfo["Engines"]:SEPREF:Contains(eng:Name) set aggEngPerfObj["SepStg"] to true.
                else set aggEngPerfObj["SepStg"] to false.
            }
            
            for res in eng:ConsumedResources:Values
            {
                local fuelMass to 0.
                local resMass to 0.
                if not aggEngPerfObj:Resources:HasKey(res:Name) 
                {
                    set resMass to res:amount * res:density.
                    set fuelMass to resMass * (1 - engResiduals).
                    set totalFuelMass to totalFuelMass + resMass.
                    aggEngPerfObj:Resources:Add(res:Name, lexicon("Amount", res:Amount, "Capacity", res:Capacity, "FuelMass", fuelMass, "MassFlow", res:MassFlow, "MaxMassFlow", res:MaxMassFlow)).
                    // if res:MassFlow > 0 
                    // {
                    //     set totalMassFlow to totalMassFlow + res:MassFlow.
                    //     // set burnTimeRemaining to (res:Amount * res:Density) / max(0.0000000001, min(999999, res:MassFlow)).
                    //     // if g_ActiveEngines:Length > 0
                    //     // {
                    //     //     set burnTimeRemaining to max(burnTimeRemaining, 0.0000001) / max(0.001, g_ActiveEngines:Length).
                    //     // }
                    // }
                    // else 
                    // {
                    //     set burnTimeRemaining to 999999.//  min(burnTimeRemaining, (res:amount * res:density) / max(res:massFlow, 0.00000000001)).
                    // }
                }
                else
                {
                    set aggEngPerfObj:Resources[res:Name]:MassFlow to aggEngPerfObj:Resources[res:Name]:MassFlow + res:MassFlow.
                    set aggEngPerfObj:Resources[res:Name]:MaxMassFlow to aggEngPerfObj:Resources[res:Name]:MaxMassFlow + res:MaxMassFlow.
                }
            }
        }

        set aggISPAt        to choose aggThrustAvailPres / aggMassFlowMax if aggThrustAvailPres > 0 and aggMassFlowMax > 0     else 0.
        set aggISP          to choose aggThrust / aggMassFlow             if aggThrust > 0          and aggMassFlow > 0        else 0.
        set aggMassFlowPct  to choose 0 if aggMassFlow = 0 or aggMassFlowMax = 0 else aggMassFlow / aggMassFlowMax.
        set thrustPct       to choose aggThrust / aggThrustAvailPres      if aggThrust > 0          and aggThrustAvailPres > 0 else 0.

        set averageResiduals to choose 0 if averageResiduals <= 0 else averageResiduals / _engList:Length.
        set totalFuelMass to totalFuelMass * (1 - averageResiduals).

        if (totalFuelMass > 0 and aggMassFlow > 0)
        {
            local btResList to list().
            for res in aggEngPerfObj:Resources:Values
            {
                btResList:Add(Max(res:FuelMass, 0.0001) / Max(res:MassFlow, 0.00001)).
            }
            for _bt in btResList
            {
                set burnTimeRemaining to Min(burnTimeRemaining, _bt).
            }
        }

        set twr to choose 0 if aggThrust = 0 else aggThrust / Ship:Mass * GetLocalGravity().
        
        // set burnTimeRemaining to choose -1 if aggMassFlow <= 0 or totalUsableFuelMass <= 0 else totalUsableFuelMass / aggMassFlow.

        set aggEngPerfObj["AverageResiduals"]    to Round(averageResiduals, 5).
        set aggEngPerfObj["BurnTimeRemaining"]   to Round(burnTimeRemaining, 3).
        set aggEngPerfObj["Failures"]            to aggFailureCount.
        set aggEngPerfObj["FailureSet"]          to aggFailureObj.
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

        // set aggEngPerfObj["LastUpdate"] to Round(Time:Seconds, 2).

        return aggEngPerfObj.
    }




    global function GetEnginesBurnTimeRemaining
    {
        parameter _engList.

        local avgResiduals      to 0.
        local estBurnTime       to 999999.
        local fuelMass          to 0.
        local massFlow          to 0.
        local maxMassFlow       to 0.
        local totalFuelMass     to 0.
        
        local engBurnTimeLex to lexicon(
            "Resources", lexicon()
            ,"EstBurnTime", estBurnTime
        ).
        
        for eng in _engList
        {
            local m to eng:GetModule("ModuleEnginesRF").
            local engineResiduals to choose m:GetField("Predicted Residuals") if m:HasField("Predicted Residuals") else 0.
            set avgResiduals to avgResiduals + engineResiduals.

            for res in eng:ConsumedResources:Values
            {
                if engBurnTimeLex:Resources:Keys:Contains(res:Name)
                {
                    set engBurnTimeLex:Resources[res:Name]:MassFlow to engBurnTimeLex:Resources[res:Name]:MassFlow + res:MassFlow.
                    set engBurnTimeLex:Resources[res:Name]:MaxMassFlow to engBurnTimeLex:Resources[res:Name]:MassFlow + res:MaxMassFlow.
                }
                else
                {
                    set fuelMass to res:amount * res:density.
                    set totalFuelMass to totalFuelMass + fuelMass.
                    engBurnTimeLex:Resources:Add(res:Name, lexicon("Object", res, "FuelMass", fuelMass, "MassFlow", res:MassFlow, "MaxMassFlow", res:MaxMassFlow)).
                }
            }
            set massFlow to massFlow + eng:MassFlow.
            set maxMassFlow to maxMassFlow + eng:MaxMassFlow.
        }

        set avgResiduals to choose 1 - (avgResiduals / _engList:Length) if avgResiduals <> 0 and _engList:Length > 0 else 1.
        
        if (totalFuelMass > 0 and massFlow > 0)
        {
            local btResList to list().
            for res in engBurnTimeLex:Resources:Values
            {
                btResList:Add((res:FuelMass * avgResiduals) / res:MassFlow).
            }
            for _bt in btResList
            {
                set estBurnTime to Min(estBurnTime, _bt).
            }
        }

        return Round(estBurnTime, 2).
    }


    global function GetEnginesBurnTimeRemaining_Next
    {
        parameter _engList.

        local allFuelMass to 0.
        local allMassFlow to 0.
        local engFuelMass to 0.
        local engMassFlow to 0.
        local maxMassFlow to 0.
        local burnTimeRemaining to 0.
        local burnTimeTotal     to 0.
        local engineBurnTime    to 0.
        local residualsAverage  to 0.
        local engineResiduals   to 0.

        local doneFlag to false.

        from { local i to 0.} until i >= _engList:Length step { set i to i + 1.} do
        {
            set engFuelMass to 0.
            set engMassFlow to 0.

            set engineBurnTime to 0.
            local eng to _engList[i].
            // local engCount to i + 1.

            local m to eng:GetModule("ModuleEnginesRF").
            set engineResiduals to m:GetField("Predicted Residuals").

            set doneFlag to false.
            from { local _i to 0.} until _i >= eng:ConsumedResources:Values:Length or doneFlag step { set _i to _i + 1.} do
            {
                local engResource to eng:ConsumedResources:Values[_i].
                // OutInfo("Processing Resource: {0}":Format(engResource:Name)).
                if engResource:MassFlow > 0 
                {
                    set engFuelMass to engFuelMass + (engResource:amount * engResource:density).
                    
                    
                    set allFuelMass to allFuelMass - (allFuelMass * engineResiduals).
                    set allMassFlow to allMassFlow + engResource:MassFlow.
                    set maxMassFlow to maxMassFlow + engResource:MaxMassFlow.
                    set engineBurnTime   to (allFuelMass - (allFuelMass * engineResiduals)) / engResource:MaxMassFlow.
                    set burnTimeRemaining  to burnTimeRemaining + engineBurnTime.
                    set doneFlag to true.
                }
            }
            set residualsAverage to (residualsAverage + engineResiduals) / _engList:Length.
        }
        set burnTimeTotal to burnTimeRemaining / _engList:Length.
        set burnTimeTotal to choose 999999 if burnTimeTotal = 0 else burnTimeTotal.
        // OutInfo("GetEnginesBurnTimeRemainingExit: {0}s":Format(Round(burnTimeTotal, 2))).
        return burnTimeTotal.
    }

    // #endregion

    // *- Event Handlers
    // #region
    global function SetupMECOEventHandler
    {
        parameter _execStr to "Ascent".

        local MECOEngList to Ship:PartsTaggedPattern("{0}\|MECO\|\d*":Format(_execStr)).
        local MECO_EngineID_List to list().
        local resultFlag to False.

        for p in MECOEngList 
        { 
            MECO_EngineID_List:Add(p:CID).
        }

        local MECO_Time to MECOEngList[0]:Tag:Replace("{0}|MECO|":Format(_execStr),""):ToNumber(-1).
        global MECO_Action_Counter to 0.
        if MECO_Time >= 0 
        {
            local checkDel to { parameter _params is list(). return MissionTime >= _params[1].}.
            local actionDel to 
            { 
                parameter _params is list(). 
                
                set MECO_Action_Counter to MECO_Action_Counter + 1. 
                
                local engIDList to _params[0].

                from { local i to 0.} until i = g_ActiveEngines:Length or engIDList:Length = 0 step { set i to i + 1.} do
                {
                    local eng to g_ActiveEngines[i].
                    
                    if engIDList:Contains(eng:CID)
                    {
                        if eng:Ignition and not eng:flameout
                        {
                            eng:shutdown.
                            // if eng:HasGimbal 
                            // {
                            //     DoAction(eng:Gimbal, "Lock Gimbal", true).
                            // }
                            engIDList:Remove(engIDList:Find(eng:CID)).
                        }
                    }
                }
                wait 0.01. 
                return false.
            }.
                
            local MECO_Event to CreateLoopEvent("MECO", "EngineCutoff", list(MECO_EngineID_List, MECO_Time), checkDel@, actionDel@).
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
