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
            ,"CREI_RO_IntSep_33"            // Internal sep motor (33% scale)
            ,"CREI_RO_IntSep_100"           // Internal sep motor (normal scale)
            ,"CREI_RO_IntSep_166"           // Internal sep motor (166% scale)
            ,"ROE-1204sepMotor"             // UA1204 Nosecone & Separation Motor
            ,"ROE-1205sepMotor"             // UA1205 Nosecone & Separation Motor
            ,"ROE-1206sepMotor"             // UA1206 Nosecone & Separation Motor
            ,"ROE-1207sepMotor"             // UA1207 Nosecone & Separation Motor
            ,"ROE-1208sepMotor"             // UA1208 Nosecone & Separation Motor
            ,"sepMotorSmall"                // Radial Separation Motor (Small)
            ,"sepMotor1"                    // Radial Separation Motor (Medium)
            ,"sepMotorLarge"                // Radial Separation Motor (Large)
            ,"SnubOtron"                    // Separation Motor (Small)
            ,"CREI_RO_IntSep_50"            // InternalRCS SRB (CREI 50% Resize)
            ,"CREI_RO_IntSep_100"           // InternalRCS SRB (CREI 100% Resize)
            ,"CREI_RO_IntSep_166"           // InternalRCS SRB (CREI 166% Resize)
            ,"CREI_RO_IntSep_200"           // InternalRCS SRB (CREI 200% Resize)
            ,"B9_Engine_T2_SRBS"            // B9 Radial Sep Motor
            ,"B9_Engine_T2_SRBS_CREI_25"    // B9 Radial Sep Motor (CREI 25% Resize)
            ,"B9_Engine_T2_SRBS_CREI_50"    // B9 Radial Sep Motor (CREI 50% Resize)
            ,"B9_Engine_T2_SRBS_CREI_150"   // B9 Radial Sep Motor (CREI 150% Resize)
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
        )
    ).

    // This adds propellant collections
    set g_PropInfo["Solids"] to list(
        "PSPC"
    ).
// #endregion


// *~ Functions ~* //
// #region
    // *- Engine Lists
    // #region
    
    // GetActiveEngines :: [(_ves)<Ship>] -> (ActiveEngines)<List)
    // Gets all engines that are active right now, no matter what stage they were
    // activated in. 
    // Valid _engType values are "All" and "NoSep" (excludes sep motors) 
    global function GetActiveEngines
    {
        parameter _ves is ship,
                  _engType is "all".

        local engList to list().

        for eng in _ves:engines
        {
            if _engType = "all" or eng:tag:length > 0
            {
                if eng:ignition and not eng:flameout
                {
                    engList:add(eng).
                }
            }
        }
        return engList.
    }

    // GetEnginesForStage :: (Stage Number)<scalar> -> (Engines activated by that stage)<List>
    // Returns engines for a given stage number
    global function GetEnginesForStage
    {
        parameter _stg, 
                  _type is "All".

        local engList to list().

        for eng in ship:engines
        {
            if eng:Stage = _stg
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
                    if g_PartInfo:Engines:SepRef:Contains(eng:Name)
                    {
                        engList:Add(eng).
                    }
                }
            }
        }
        return engList.
    }


    // GetNextEngines :: -> (engList)<List>
    // Returns the next set of engines, starting with current stage - 1, and iterating towards 0 until it finds them (or doesn't)
    global function GetNextEngines
    {
        local engList to list().

        from { local i to Stage:Number - 1.} until i <= 0 step { set i to i - 1.} do
        {
            set engList  to GetEnginesForStage(i).
            if engList:Length > 0 
            {
                return engList.
            }
        }
        return engList.
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
            ,"Ullage",              false
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
            if eng:Ullage
            {
                set engsSpecs:Ullage to true.
            }

            for resName in eng:ConsumedResources:Keys
            {
                local engResource to eng:ConsumedResources[resName].
                local resMass to engResource:Amount * engResource:Density.

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
            }
            set engsSpecs[eng:CID] to engSpecs.
        }

        if (TotalResMass > 0 and AggregateMassLex:MaxMassFlow > 0)
        {
            set engsSpecs:EstBurnTime to (Round(TotalResMass / AggregateMassLex:MaxMassFlow, 2)).
        }
        // set engSpecs["ESTBURNTIME"] to choose (Round(TotalResMass / AggregateMassLex:MaxMassFlow, 2) if (TotalResMass > 0 and AggregateMassLex:MaxMassFlow > 0) else 0, 2).

        // local burnTimeEstimate to max(TotalResMass, 0.0001) / min(max(AggregateMassLex:MAXMASSFLOW, 0.0001), 1000).
        // set engsSpecs["ESTBURNTIME"] to Round(burnTimeEstimate, 2).

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
        local failureCause          to choose "" if statusString = "Nominal" else m:GetField("Cause").
        
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
            "Engines", lexicon(
                "Resources", lexicon(
                    "TotalMass", 0
                    ,"TotalMassFlow", 0
                )
            )
            ,"SepStg", False
        ).

        local aggFailureCount       to 0.
        local aggFuelStability      to 0.
        local aggISP                to 0.
        local aggISPAt              to 0.
        local aggMassFlow           to 0.
        local aggMassFlowMax        to 0.
        local aggMassFlowPct        to 0.
        local aggThrust             to 0.
        local aggThrustAvailPres    to 0.
        local averageResiduals      to 0.
        // local aggTWR             to 0.
        local thrustPct             to 0.
        local totalUsableFuelMass         to 0.
        local aggFailureObj         to lexicon().

        local burnTimeRemaining     to 999999999.

        from { local i to 0.} until i = _engList:Length step { set i to i + 1.} do
        {
            local eng to _engList[i].
            // if eng:Decoupler <> "None" and eng:Decoupler:Tag:MatchesPattern("booster")
            // {
            local engLex    to GetEnginePerformanceData(eng).    

            local m to engLex:Module.
            set averageResiduals to averageResiduals + m:GetField("Predicted Residuals").

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
            
            local resMass to 0.
            for res in eng:ConsumedResources:Values
            {
                if  not aggEngPerfObj:Engines:Resources:HasKey(res:Name) 
                {
                    set resMass to resMass + (res:amount * res:density).
                    set totalUsableFuelMass to totalUsableFuelMass + resMass.
                    aggEngPerfObj:Engines:Resources:Add(res:Name, lexicon("Amount", res:Amount, "Capacity", res:Capacity, "Mass", resMass, "MassFlow", res:MassFlow)).
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
            }
        }

        set aggISPAt        to choose aggThrustAvailPres / aggMassFlowMax if aggThrustAvailPres > 0 and aggMassFlowMax > 0     else 0.
        set aggISP          to choose aggThrust / aggMassFlow             if aggThrust > 0          and aggMassFlow > 0        else 0.
        set aggMassFlowPct  to choose 0 if aggMassFlow = 0 or aggMassFlowMax = 0 else aggMassFlow / aggMassFlowMax.
        set thrustPct       to choose aggThrust / aggThrustAvailPres      if aggThrust > 0          and aggThrustAvailPres > 0 else 0.

        set averageResiduals to choose 0 if averageResiduals <= 0 else averageResiduals / _engList:Length.
        set totalUsableFuelMass to totalUsableFuelMass * (1 - averageResiduals).

        set burnTimeRemaining to choose -1 if aggMassFlow <= 0 or totalUsableFuelMass <= 0 else totalUsableFuelMass / aggMassFlow.

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
        set aggEngPerfObj["TotalUsableFuelMass"] to totalUsableFuelMass.

        // set aggEngPerfObj["LastUpdate"] to Round(Time:Seconds, 2).

        return aggEngPerfObj.
    }




    global function GetEnginesBurnTimeRemaining
    {
        parameter _engList.

        local cachedMassFlow    to 0.
        local estBurnTime       to 0.
        local fuelMass          to 0.
        local massFlow          to 0.
        local maxMassFlow       to 0.
        local totalFuelMass     to 0.
        local totalMassFlow     to 0.
        
        local engBurnTimeLex to lexicon(
            "Resources", lexicon(
                 "TotalFuelMass", 0
                ,"TotalMassFlow", 0
                ,"MaxMassFlow", 0
            )
            ,"EngData", lexicon()
            ,"EstBurnTime", -1
        ).
        
        //for eng in _engList
        from { local i to 0. local c to 1. } until i = _engList:Length step { set i to i + 1. set c to c + 1.} do
        {
            local eng to _engList[i].
            local m to eng:GetModule("ModuleEnginesRF").
            local engineResiduals to choose Round(m:GetField("Predicted Residuals"), 7) if m:HasField("Predicted Residuals") else 0.

            engBurnTimeLex:EngData:Add(eng:UID, lexicon()).

            engBurnTimeLex:EngData[eng:UID]:Add("ConsumedResources", eng:ConsumedResources:Values).
            engBurnTimeLex:EngData[eng:UID]:Add("FlowMass", eng:MassFlow).
            engBurnTimeLex:EngData[eng:UID]:Add("EstBurnTime", -1).
            engBurnTimeLex:EngData[eng:UID]:Add("Residuals", engineResiduals).
            
            for res in eng:ConsumedResources:Values
            {
                // set fuelFlow to choose res:MassFlow else res:MaxMassFlow.
                local resMass to 0.
                
                if engBurnTimeLex:Resources:Keys:Contains(res:Name)
                {
                    // if g_Debug OutDebug("Resource Cached: {0}":Format(res:Name)).
                    // set resMass to (res:amount * res:density).
                    // set fuelMass to resMass *  (1 - engineResiduals).
                }
                else
                {
                    // if g_Debug OutDebug("Processing Resource: {0}":Format(res:Name)).
                    set resMass to (res:amount * res:density).
                    set fuelMass to resMass * (1 - engineResiduals).
                    set engBurnTimeLex:Resources:TotalFuelMass to engBurnTimeLex:Resources:TotalFuelMass + fuelMass.
                    set totalFuelMass to totalFuelMass + fuelMass.
                    // engBurnTimeLex:Resources:Add(res:Name, lexicon("ResObj", res, "MassFlow", res:MassFlow, "MaxMassFlow", res:MaxMassFlow, "FuelMass", resMass)).
                    engBurnTimeLex:Resources:Add(res:Name, lexicon("ResObj", res, "FuelMass", resMass)).
                }
                // set totalMassFlow to totalMassFlow + res:MassFlow.
                // set massFlow to massFlow + res:MassFlow.
                // set maxMassFlow to maxMassFlow + res:MaxMassFlow.
                // set engBurnTimeLex:Resources:TotalFuelMass to totalFuelMass.
                // set engBurnTimeLex:Resources:TotalMassFlow to totalMassFlow.
                // set engBurnTimeLex:Resources:MaxMassFlow to maxMassFlow.
            }
            set totalMassFlow to totalMassFlow + eng:MassFlow.
            set massFlow to massFlow + eng:MassFlow.
            set maxMassFlow to maxMassFlow + eng:MaxMassFlow.
            set engBurnTimeLex:Resources:TotalFuelMass to totalFuelMass.
            set engBurnTimeLex:Resources:TotalMassFlow to totalMassFlow.
            set engBurnTimeLex:Resources:MaxMassFlow to maxMassFlow.
        }

        // if g_Debug OutDebug("MaxMassFlow        : {0}":Format(Round(maxMassFlow, 7)), 1).
        // if g_Debug OutDebug("MaxMassFlow(Lex)   : {0}":Format(Round(engBurnTimeLex:Resources:MaxMassFlow, 7)), 2).
        // if g_Debug OutDebug("TotalFuelMass      : {0}":Format(Round(TotalFuelMass, 7)), 3).
        // if g_Debug OutDebug("TotalFuelMass(Lex) : {0}":Format(Round(engBurnTimeLex:Resources:TotalFuelMass, 7)), 4).
        
        set estBurnTime to choose fuelMass / massFlow if massFlow > 0 else fuelMass / maxMassFlow.
        set engBurnTimeLex:EstBurnTime to estBurnTime.
        
        //local engBurnTime to choose fuelMass / eng:MassFlow if eng:MassFlow > 0 else 0.
        // local engBurnTime to choose engBurnTimeLex:Resources["TotalFuelMass"] / engBurnTimeLex:Resources:MassFlow if massFlow > 0 else engBurnTimeLex:Resources["TotalFuelMass"] / engBurnTimeLex:Resources:MaxMassFlow.
        // set burnTimeRemaining to burnTimeRemaining + engBurnTime.
        // set engBurnTimeLex:EngData[eng:UID]:BurnTimeEstimate to burnTimeRemaining.
        
        // set engBurnTimeLex:EngData[eng:UID] to lexicon(
        //     "ConsumedResources", eng:ConsumedResources:Values
        //     ,"FlowMass", eng:MassFlow
        //     ,"BurnTimeEstimate", engBurnTime
        //     ,"Residuals", round(engineResiduals, 5)
        // ).

        // local burnTimeTotal to choose fuelMass / massFlow if (fuelMass > 0 and massFlow > 0) else 0.
        // local burnTimeTotal to choose burnTimeRemaining / _engList:Length if _engList:Length > 0 else 0.
        // local burnTimeTotal to burnTimeRemaining.

        // OutDebug("GetEnginesBurnTimeRemainingExit: {0}s":Format(Round(burnTimeTotal, 2))).
        
        return estBurnTime.
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
                        if eng:ignition and not eng:flameout
                        {
                            eng:shutdown.
                            if eng:HasGimbal 
                            {
                                DoAction(eng:Gimbal, "Lock Gimbal", true).
                            }
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