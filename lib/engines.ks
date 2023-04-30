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
    // #endregion

    // *- Object entry registrations
    // This adds engines to the part info global
    set g_PartInfo["Engines"] to lexicon( 
        "SepRef", list(
            "ROSmallSpinMotor"      // Spin Motor (Small)
            ,"CREI_RO_IntSep_33"    // Internal sep motor (33% scale)
            ,"CREI_RO_IntSep_100"   // Internal sep motor (normal scale)
            ,"CREI_RO_IntSep_166"   // Internal sep motor (166% scale)
            ,"ROE-1204sepMotor"     // UA1204 Nosecone & Separation Motor
            ,"ROE-1205sepMotor"     // UA1205 Nosecone & Separation Motor
            ,"ROE-1206sepMotor"     // UA1206 Nosecone & Separation Motor
            ,"ROE-1207sepMotor"     // UA1207 Nosecone & Separation Motor
            ,"ROE-1208sepMotor"     // UA1208 Nosecone & Separation Motor
            ,"sepMotorSmall"        // Radial Separation Motor (Small)
            ,"sepMotor1"            // Radial Separation Motor (Medium)
            ,"sepMotorLarge"        // Radial Separation Motor (Large)
            ,"SnubOtron"            // Separation Motor (Small)
        )
    ).
// #endregion


// *~ Functions ~* //
// #region
    // *- Engine Lists
    // #region
    
    // GetActiveEngines :: [(_ves)<Ship>] -> (ActiveEngines)<List)
    // Returns a list of engines current firing and with a stage number great than the current one
    global function GetActiveEngines
    {
        parameter _ves is Ship.

        local engList to list().
        for eng in _ves:Engines
        {
            if eng:ignition
            {
                if not eng:flameout
                {
                    if eng:stage >= Stage:Number
                    {
                        engList:Add(eng).
                    }
                }
            }
        }

        return engList.
    }

    // GetEnginesForStage :: (Stage Number)<scalar> -> (Engines activated by that stage)<List>
    // Returns engines for a given stage number
    global function GetEnginesForStage
    {
        parameter _stg.

        local engList to list().

        for eng in ship:engines
        {
            if eng:Stage = _stg
            { 
                engList:Add(eng). 
            }
        }
        return engList.
    }

    // GetNextEngines :: -> (engList)<List>
    // Returns the next set of engines, starting with the current stage and iterating towards 0 until it finds them (or doesn't)
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
            ,"Ullage",          _eng:Ullage
        ).
        return engSpecObj.
    }

    // GetEnginesSpecs :: (_engList)<List> -> (engsSpecs)<Lexicon>
    // Engine specs for a list of engines, keyed by the engine unique vessel identifier (CID)
    global function GetEnginesSpecs
    {
        parameter _engList.

        local fuelStabilityAvg to 0.
        local fuelStabilityMin to 1.
        local engsSpecs to lexicon(
            "SpoolTime", 0
            ,"FuelStabilityAvg", 0
            , "FuelStabilityMin", 0
        ).

        from { local i to 0.} until i = _engList:Length step { set i to i + 1.} do
        {
            local eng to _engList[i].

            local engSpecs to GetEngineSpecs(eng).
            set engsSpecs["SpoolTime"] to max(engsSpecs:SpoolTime, engSpecs:SpoolTime).
            
            set fuelStabilityMin to min(engSpecs:FuelStability, fuelStabilityMin).
            set engsSpecs["FuelStabilityMin"] to fuelStabilityMin.
            
            set fuelStabilityAvg to ((engsSpecs:FuelStabilityAvg * i) + engSpecs:FuelStability) / (i + 1).
            set engsSpecs["FuelStabilityAvg"] to fuelStabilityAvg.

            set engsSpecs[eng:CID] to engSpecs.
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
        from { local i to 0.} until i = engList:Length step { set i to i + 1.} do
        {
            local eng           to engList[i].
            local engSpecs      to GetEngineSpecs(eng).
            set isSepStage      to choose true if isSepStage or engSpecs:IsSepMotor else false.
            if engStgObj:HasKey(eng:Stage)
            {
                set engStgObj[eng:Stage]["Engines"][eng:CID] to engSpecs.
            }
            else
            {
                set engStgObj[eng:Stage] to lexicon(
                    "Engines", lexicon(
                        eng:CID, engSpecs
                    )
                ).
            }
            set engStgObj[eng:Stage]["IsSepStage"] to isSepStage.
        }

        return engStgObj.
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
        //:ToNumber(1) / 100.
        local engPerfObj to lexicon(
            "CID",              _eng:CID
            ,"EngName",         _eng:Name
            ,"EngTitle",        _eng:Title
            ,"Flameout",        _eng:Flameout
            ,"FuelFlow",        _eng:FuelFlow
            ,"FuelStability",   fuelStabilityScalar
            ,"Ignition",        _eng:Ignition
            ,"ISPAt",           _eng:ISPAt(altPres)
            ,"IsSepMotor",      sepMotorCheck
            ,"MassFlow",        GetField(m, "Mass Flow")
            ,"Thrust",          _eng:MaxThrust
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
            ,"SepStg", true
        ).

        local aggFuelStability      to 0.
        local aggISP                to 0.
        local aggISPAt              to 0.
        local aggMassFlow           to 0.
        local aggMassFlowMax        to 0.
        local aggMassRemaining      to 0.
        local aggThrust             to 0.
        local aggThrustAvailPres    to 0.
        // local aggTWR                to 0.
        local thrustPct             to 0.

        local burnTimeRemaining     to 999999999.

        from { local i to 0.} until i = _engList:Length step { set i to i + 1.} do
        {
            local eng       to _engList[i].
            local engLex    to GetEnginePerformanceData(eng).
            

            set aggThrust           to aggThrust + eng:Thrust.
            set aggThrustAvailPres  to aggThrustAvailPres + engLex:ThrustAvailPres.
            set aggMassFlow         to aggMassFlow + eng:MassFlow.
            set aggMassFlowMax      to aggMassFlowMax + eng:MaxMassFlow.
            if (engLex:Ignition and not engLex:Flameout) set aggEngPerfObj["Ignition"] to True.
            
            set aggEngPerfObj["Engines"][eng:CID] to engLex.
            if aggEngPerfObj["SepStg"] 
            {
                if g_PartInfo["Engines"]:SEPREF:Contains(eng:Name) set aggEngPerfObj["SepStg"] to true.
                else set aggEngPerfObj["SepStg"] to false.
            }
            local _am to 0.
            for res in eng:ConsumedResources:Values
            {
                set _am to _am + (res:amount * res:density).
                if res:MassFlow > 0 
                {
                    set burnTimeRemaining to (res:Amount * res:Density) / max(0.00000001, res:MassFlow).
                }
                else 
                {
                    set burnTimeRemaining to 999999.//  min(burnTimeRemaining, (res:amount * res:density) / max(res:massFlow, 0.00000000001)).
                }
            }
        }

        // set aggISPAt to max(aggThrustAvailPres, 0.000000001) / max(aggMassFlowMax * 1000000, 0.00001).
        // set aggISP   to max(aggThrust, 0.000000001) / max(aggMassFlow * 1000000, 0.00001).
        // set thrustPct to max(aggThrust, 0.000000001) / max(aggThrustAvailPres, 0.00001).
        set aggISPAt  to choose aggThrustAvailPres / aggMassFlowMax if aggMassFlowMax > 0 else 0.
        set aggISP    to choose aggThrust / aggMassFlow if aggMassFlow > 0 else 0.
        set thrustPct to choose aggThrust / aggThrustAvailPres if aggThrust > 0 else 0.

        set aggEngPerfObj["ISP"]                to aggISP.
        set aggEngPerfObj["ISPAt"]              to aggISPAt.
        set aggEngPerfObj["Thrust"]             to aggThrust.
        set aggEngPerfObj["ThrustAvailPres"]    to aggThrustAvailPres.
        set aggEngPerfObj["ThrustPct"]          to thrustPct.
        set aggEngPerfObj["BurnTimeRemaining"]  to round(burnTimeRemaining, 3).

        // set aggEngPerfObj["LastUpdate"] to Round(Time:Seconds, 2).

        return aggEngPerfObj.
    }
    // #endregion
// #endregion