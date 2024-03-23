// #include "0:/lib/depLoader.ks"
@LazyGlobal off.

// *~ Dependencies ~* //
// #region
// #endregion


// *~ Variables ~* //
// #region
    // *- Local
    // #region
    local l_EngCfgPath to "0:/data/ref/eng.cfg".
    local l_MaxFlightData to 10000.
    // #endregion

    // *- Global
    // #region
    global g_ActiveEngines          to list().
    global g_ActiveEngines_PerfData to lex().
    global g_NextEngines            to list().
    global g_ShipEngines            to lexicon().

    global g_Throt to 0.
    // #endregion
    
    // *- Local Anonymous Delegates
    // #region
    // #endregion

    // *- Global Anonymous Delegates
    // #region
    // #endregion

    // *- Misc Reference Objects
    
    // Object holding info about engine configurations that isn't typically available via APIs (usually seen only in UI)
    // List Legend: 
    //  - [0] [BurnTime(Rated)]: Rated burn time based on the engine config. 
    //  - [1] [OverBurnRatio]  : The max percentage amount of rated burn time that can be added to the BTR value, used like this: BTR + (BTR * ((CurFlightData / MaxFlightData) * OBR). 
    //                           * This results in a sliding scale of increasing overburn time as more flight data comes in, and that hopefully results in safer overburns. 
    global g_EngineConfigs is lexicon(
        //  "A-4",         list(70,  0.14)
        // ,"A-6",         list(65,  0.16)
        // ,"A-9",         list(115, 0.12)
        // ,"XLR43-NA-1",  list(65,  0.14)
        // ,"XLR43-NA-3",  list(65,  0.18)
        // ,"Veronique",   list(45,  0.20)
        // ,"VeroniqueAGI",list(49,  0.20)
        // ,"U-1250",      list(56,  0.22)
        // ,"S-3",         list(182, 0.075)
        // ,"AJ10-27",     list(52,  0.125)
        // ,"AJ10-37",     list(115, 0.125)
    ).

    global g_EngRef is lexicon(
        "SEP", list(
            "CREI_RO_IntSep_200"
            ,"CREI_RO_IntSep_150"
            ,"CREI_RO_IntSep_100"
            ,"CREI_RO_IntSep_050"
            ,"CREI_RO_IntSep_033"
            ,"ROSmallSpinMotor"
            ,"sepMotor1"
            ,"sepMotor1Short"
            ,"sepMotorLarge"
            ,"sepMotorLargeShort"
            ,"sepMotorMicro"
            ,"sepMotorMicroShort"
            ,"sepMotorSmall"
            ,"sepMotorSmallShort"
            ,"SnubOtron"
        )
    ).
// #endregion

// Library Initialization code
HydrateEngineConfigs().

// *~ Global Functions ~* //
// #region

// *- Engine lists
// #region

    // GetActiveEngines
    global function GetActiveEngines
    {
        parameter _ship is Ship.

        local engList to list().
        for eng in Ship:Engines
        {
            if eng:Ignition and not eng:Flameout engList:add(eng).
        }
        return engList.
    }

    // GetNextEngines ::
    // Returns the next group of engines that will be ignited by stage using g_ShipEngines:IGNSTG
    // Optional datamask parameter to scope to engine types (regular, booster, sep/ullage motors)
    global function GetNextEngines
    {
        parameter _ship is Ship,
                  _dataMask is "1110". // [0] Regular engines
                                       // [1] Booster engines
                                       // [2] Sep motors
                                       // [0] Reserved / Currently unused

        local engList to list().

        from { local iStg to Stage:Number - 1.} until iStg < 0 step { set iStg to iStg - 1.} do
        {
            if g_ShipEngines:IGNSTG:HasKey(iStg)
            {
                
                for eng in g_ShipEngines:IGNSTG[iStg]:ENG
                {
                    local isBooster to choose false if eng:Decoupler = "None" else eng:Decoupler:Tag:MatchesPattern("Booster").
                    local isSep     to g_EngRef:SEP:Contains(eng:name) and eng:Tag:Length = 0.

                    if _dataMask[0]:ToNumber(0) and (not isBooster and not isSep)
                    {
                        engList:Add(eng).
                    }
                    else if _dataMask[1]:ToNumber(0) and isBooster
                    {
                        engList:add(eng).
                    }
                    else if _dataMask[2]:ToNumber(0) and isSep
                    {
                        engList:add(eng).
                    }
                }
                
                if engList:Length > 0 
                {
                    break.
                }
            }
        }

        return engList.
    }
// #endregion

// *- Engine Stats
// #region

    // GetActiveBurnTimeRemaining
    global function GetActiveBurnTimeRemaining
    {
        parameter _engs is GetActiveEngines(),
                  _shaper to 0.8.

        local btRemaining to 999999.
        
        for eng in _engs
        {
            local residuals to 0.00000000001.
            if eng:HasModule("ModuleEnginesRF")
            {
                local m to eng:GetModule("ModuleEnginesRF").
                set   residuals to 1 - GetField(m, "predicted residuals", 0).
            }
            
            for ft in eng:ConsumedResources:Values
            {
                local resBT to (Stage:ResourcesLex[ft:Name]:Amount * Stage:ResourcesLex[ft:Name]:Density * residuals) / ft:MaxMassFlow.
                set btRemaining to Min(btRemaining, resBT).
            }
        }
        if btRemaining = 999999 
        {
            set btRemaining to 0.
        }
        else
        {
            set btRemaining to Max(0, (btRemaining * _shaper) - 0.5).
        }
        return btRemaining.
    }

    // GetEnginesISP :: (<list>Engines) -> <scalar>
    // Returns averaged ISP for a list of engines
    global function GetEnginesISP
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

    // GetEngineBurnTime
    global function GetEngineBurnTime
    {
        parameter _eng.

        local burnTimeRated  to -1.
        local burnTimePlus   to -1.
        local burnTimeFuel   to -1.
        local overBurnRatio  to 1.125.

        if _eng:IsType("Engine")
        {
            if _eng:HasModule("TestFlightReliability_EngineCycle")
            {
                local engFlightData to _eng:GetModule("TestFlightReliability_EngineCycle"):GetField("flight data").
                set overBurnRatio to ((overburnRatio - 1.01) * (Max(engFlightData, 0.1) / 10000)) + 1.01.
            }
            if g_EngineConfigs:Keys:Contains(_eng:Config)
            {
                set burnTimeRated to g_EngineConfigs[_eng][0].
                set burnTimePlus to burnTimeRated * overBurnRatio.
            }
        }
        else if _eng:IsType("String")
        {
            if g_EngineConfigs:Keys:Contains(_eng)
            {
                set burnTimeRated to g_EngineConfigs[_eng][0].
                set burnTimePlus to burnTimeRated * overBurnRatio.
            }
        }

        return list(burnTimeRated, burnTimePlus, burnTimeFuel).
    }

    
    // GetEngineSpoolTime
    global function GetEngineSpoolTime
    {
        parameter _eng.

        local spool to 0.

        if _eng:HasModule("ModuleEnginesRF")
        {
            local m to _eng:GetModule("ModuleEnginesRF").
            set spool to GetField(m, "effective spool-up time", 0).
        }
        return spool.
    }
    // #endregion

    // GetExhVel :: (<list>Engines) -> <scalar>
    // Returns the averaged exhaust velocity for a list of engines
    global function GetExhVel
    {
        parameter _engList,
                  _mode is "cur".

        return Constant:g0 * GetEnginesISP(_engList, _mode).
    }
// #endregion


// *~ Local helper functions ~* //
// #region

    // ProcessIgnitionStageEngines
    // Helper for adding constructing a lex that contains UID pointers to engs, grouped by stage number, with optional extended stage data available
    local function GroupEnginesByStage
    {
        parameter _eng,
                  _engObj is lex(),
                  _stgType is "IGN", // Two possible values here - IGN, or the stage it's activated in, and DC, or the stage it's decoupled in.
                  _extendedInfo is false,
                  _objRef is lex().

        local stageGroup to choose _eng:DecoupledIn if _stgType = "DC" else _eng:Stage.
        // local groupIDStr to choose "DCSTG"          if _stgType = "DC" else "IGNSTG".
        local spoolTime to choose _eng:GetModule("ModuleEnginesRF"):GetField("effective spool-up time") if _eng:GetModule("ModuleEnginesRF"):HasField("effective spool-up time") else 0.
        
        local isSepMotor to g_EngRef:SEP:Contains(_eng:Name) and _eng:Tag:Length = 0.


        if _objRef:HasKey(stageGroup)
        {
            _objRef[stageGroup]:ENG:Add(_eng).
            _objRef[stageGroup]:UID:Add(_eng:UID).
            set _objRef[stageGroup]["SEPSTG"]    to choose isSepMotor if _objRef[stageGroup]:SEPSTG else false.
            set _objRef[stageGroup]["STG"]       to choose _eng:Stage if _stgType = "IGN" else _eng:DECOUPLEDIN.
            set _objRef[stageGroup]["STGBURNTIME"]  to Max(_objRef[stageGroup]:STGBURNTIME, _engObj:ENGUID[_eng:UID]:TARGETBURNTIME).
            set _objRef[stageGroup]["STGMAXSPOOL"]  to Max(_objRef[stageGroup]:STGMAXSPOOL, spoolTime).
            set _objRef[stageGroup]["STGMAXTHRUST"] to _objRef[stageGroup]:STGMAXTHRUST + _eng:MaxPossibleThrust.
        }
        else
        {
            _objRef:Add(stageGroup, lex(
                    "ENG", list(_eng)
                    ,"UID", list(_eng:UID)
                    ,"SEPSTG",          isSepMotor
                    ,"STG",             _eng:Stage
                    ,"STGBURNTIME",     Max(0, _engObj:ENGUID[_eng:UID]:TARGETBURNTIME)
                    ,"STGMAXSPOOL",     spoolTime
                    ,"STGMAXTHRUST",    _eng:MaxPossibleThrust
                )
            ).
        }

        if _extendedInfo
        {

            if _objRef[stageGroup]:HasKey("STGMAXTHRUSTSL") { set _objRef[stageGroup]:STGMAXTHRUSTSL to _objRef[stageGroup]:STGMAXTHRUSTSL + _eng:MaxPossibleThrustAt(0).} else { _objRef[stageGroup]:Add("STGMAXTHRUSTSL", _eng:MaxPossibleThrustAt(0)).}
            if _objRef[stageGroup]:HasKey("STGMAXFUELFLOW") { set _objRef[stageGroup]:STGMAXFUELFLOW to _objRef[stageGroup]:STGMAXFUELFLOW + _eng:MaxFuelFlow.} else { _objRef[stageGroup]:Add("STGMAXFUELFLOW", _eng:MaxFuelFlow).}
            if _objRef[stageGroup]:HasKey("STGMAXMASSFLOW") { set _objRef[stageGroup]:STGMAXMASSFLOW to _objRef[stageGroup]:STGMAXMASSFLOW + _eng:MaxMassFlow.} else { _objRef[stageGroup]:Add("STGMAXMASSFLOW", _eng:MaxMassFlow).}

            // set _objRef[stageGroup]:STGMAXTHRUSTSL to _objRef[stageGroup]:STGMAXTHRUSTSL + _eng:MaxPossibleThrustAt(0).
            // set _objRef[stageGroup]:STGMAXFUELFLOW to _objRef[stageGroup]:STGMAXFUELFLOW + _eng:MaxFuelFlow.
            // set _objRef[stageGroup]:STGMAXMASSFLOW to _objRef[stageGroup]:STGMAXMASSFLOW + _eng:MaxMassFlow.
        }

        return _objRef.
    }

    // GetEngineModuleData 
    // Extract some useful specification data from engine module
    local function GetEngineModuleData
    {
        parameter _eng,
                  _dataMask to "10". // [1] 0  - Specs
                                     //  0 [1] - Status

        local resultObj to lex(
            // "MIXRATIO", 1
            // ,"RESIDUALS", 0
            // ,"SPOOLTIME", 0
        ).

        if _eng:HasModule("ModuleEnginesRF")
        {
            local engRFModule to _eng:GetModule("ModuleEnginesRF").
            if _dataMask[0]
            {
                set resultObj["MIXRATIO"]    to GetField(engRFModule, "mixture ratio", 1).
                set resultObj["RESIDUALS"]   to GetField(engRFModule, "predicted residuals", 0).
                set resultObj["SPOOLTIME"]   to GetField(engRFModule, "effective spool-up time", 0).              
                set resultObj["THRUSTLIM"]   to GetField(engRFModule, "thrust limiter").
            }
            if _dataMask[1]
            {
                set resultObj["CURTHROTTLE"] to GetField(engRFModule, "current throttle").
                set resultObj["MASSFLOW"]    to GetField(engRFModule, "mass flow").
                set resultObj["ENGTEMP"]     to GetField(engRFModule, "eng. internal temp").
                set resultObj["THRUST"]      to GetField(engRFModule, "thrust").
                set resultObj["ISP"]         to GetField(engRFModule, "specific implulse").
                set resultObj["STATUS"]      to GetField(engRFModule, "status").
            }
        }

        return resultObj.
    }

    // GetEnginesPerformanceData
    //
    global function GetEnginesPerformanceData
    {
        parameter _engList is g_ActiveEngines,
                  _dataMask is "11000000".      // A 1-byte Bitmask to determine which data to hydrate during this iteration. Returns the base data by default.

                                                // Any bit with a value of 1 will hydrate the data based on the table below, while a value of 0 will not. 
                                                // All non-hydrated data will retain default values (or not be included at all maybe?)

                                                    // Legend:          B0       |
                                                    // CharIdx :   NB0  |   NB1  |


                                                    // Byte 0, Nibble 0 - ENGS
                                                    //   [0]   : (1)000 |        |   Returns basic performance data from the engine part
                                                    //   [1]   : 0(1)00 |        |    -- Include Standard Eng Perf Data (Current Thrust, ISP, Ignition, Flameout, etc)
                                                    //   [2]   : 10(1)0 |        |    -- Include Estimated Burn Time Remaining
                                                    //   [3]   : 100(1) |        |    -- Include TWR data                                     


                                                    // Byte 0, Nibble 1  2 - IGNST
                                                    //   [4]   :        | (1)000 |   [IGNSTG] Controls initial hydration of the IGNSTG object in the output. 
                                                    //                               IGNSTG is a lexicon of engine UIDs keyed by ignition stage, with options for aggregated stage data available

                                                    //                               Additional (Optional) switches:
                                                    //   [5]   :        | 1(1)00 |    -- Transform / hydrate aggregated stage specs
                                                    //   [6]   :        | 10(1)0 |    -- Currently unused // TODO Include current aggregated performance data
                                                    //   [7]   :        | 100(1) |    -- Currently unused



                                                    // Byte 1, Nibble 0 - DCSTG
                                                    //   [8]   :        |        |   [DCSTG] Controls initial hydration of the DCSTG object in the output
                                                    //                               DCSTG is a lexicon of engine UIDs keyed by ignition stage, with options for aggregated stage data available

                                                    //                               Additional (Optional) switches:
                                                    //   [9]   :        |        |    -- Transform / hydrate aggregated stage specs
                                                    //   [10]  :        |        |    -- Currently unused // TODO Include current aggregated performance data
                                                    //   [11]  :        |        |    -- Currently unused


                                                    // Byte 1, Nibble 1 - RESERVED
                                                    //   [12]  :        |        |   [RSRVD] Currently unused
                                                    //                                                  This is a nibble reserved for future functionality flags



                                                    // - Example:   A _dataMask parameter of '1110110001000000' would return an engObj with the following (*) marked data hydrated, 
                                                    //              with any disabled ~top-level~ node(s) remaining the default initialized empty lex value. 
                                                    //              Disabled ~child~ nodes will either not run if their parent is disabled, or remain the default initialized value if the parent is active.
                                                    //  
                                                    //           *-- ENGUID: Lex of engines keyed by UID
                                                    //               *- Engine suffix specs 
                                                    //               *- ModuleEnginesRF data 
                                                    //                - TestFlight data (bit[3] = 0 means this block will not run)
                                                    //           *-- IGNSTG: Engines keyed by Ignition Stage
                                                    //               *- Aggregate Stage Specs
                                                    //            -- DCSTG: Engines keyed by decoupled in stage
                                                    //                - Aggregate Stage Specs
                                                    //                      *** NOTE how this is set to 1 in this example but the preceding 0 bit is the parent and therefore overrides it. 
                                                    //                          Basically, if the parent isn't active, none of the children can be regardless of their value


        local perfObj to lex().

        if _dataMask[0]
        {
            set perfObj to lex(
                "ENGS", list()
                ,"FUELFLOW", 0
                ,"ISP", GetEnginesISP(_engList)
                ,"MASSFLOW", 0
                ,"THRUST", 0
                ,"ULLAGE", 1
                ,"IGNITION", 1
                ,"FLAMEOUT", 0
            ).
        }

        if _dataMask[1]
        {
            // perfObj:Add("FAILURES", 0).
            // perfObj:Add("FAILUREMODE", "").
            perfObj:Add("EXHVEL", GetExhVel(_engList)).
            perfObj:Add("MAXFUELFLOW", 0).
            perfObj:Add("MAXMASSFLOW", 0).
            perfObj:Add("MAXPOSSTHRUST", 0).
        }
        if _dataMask[2]
        {
            perfObj:Add("BURNTIMEREMAINING", GetActiveBurnTimeRemaining(_engList)).
        }
        if _dataMask[3]
        {
            perfObj:Add("TWR", 0).
        }

        for eng in _engList
        {
            perfObj:ENGS:Add(eng).
            if perfObj:HasKey("FUELFLOW") set perfObj:FUELFLOW to perfObj:FUELFLOW + eng:FuelFlow.
            if perfObj:HasKey("MASSFLOW") set perfObj:MASSFLOW to perfObj:MASSFLOW + eng:MassFlow.
            if perfObj:HasKey("THRUST")   set perfObj:THRUST   to perfObj:THRUST+ eng:Thrust.
            if perfObj:HasKey("ULLAGE")   set perfObj:ULLAGE   to choose 0 if not eng:Ullage else perfObj:ULLAGE.
            if perfObj:HasKey("IGNITION") set perfObj:IGNITION to choose 0 if not eng:Ignition else perfObj:IGNITION.
            if perfObj:HasKey("FLAMEOUT") set perfObj:FLAMEOUT to choose 0 if not eng:Flameout else perfObj:FLAMEOUT.
            if perfObj:HasKey("MAXFUELFLOW") set perfObj:MAXFUELFLOW to perfObj:MAXFUELFLOW + eng:MaxFuelFlow.
            if perfObj:HasKey("MAXMASSFLOW") set perfObj:MAXMASSFLOW to perfObj:MAXMASSFLOW + eng:MaxMassFlow.
            if perfObj:HasKey("MAXPOSSTHRUST") set perfObj:MAXPOSSTHRUST to perfObj:MAXPOSSTHRUST + eng:MaxPossibleThrust.
        }

        perfObj:Add("LASTUPDATE", Time:Seconds).

        return perfObj.
    }

    
    // GetEngineSuffixDataExtended
    // Helper for collecting useful data from the engine suffixes into something we can work with
    local function GetEngineSuffixDataExtended
    {
        parameter _eng,
                  _destObj to lex().

        if _eng:IsType("Engine")
        {
            set _destObj["ALLOWRESTART"]  to _eng:AllowRestart.
            set _destObj["ALLOWSHUTDOWN"] to _eng:AllowShutdown.
            set _destObj["IGNREMAIN"]     to _eng:Ignitions.
            set _destObj["ISPSL"]         to _eng:SLISP.
            set _destObj["ISPV"]          to _eng:VISP.
            set _destObj["MAXFUELFLOW"]   to _eng:MaxFuelFlow.
            set _destObj["MAXMASSFLOW"]   to _eng:MaxMassFlow.
            set _destObj["MAXTHRUST"]     to _eng:MaxPossibleThrust.
            set _destObj["MAXTHRUSTSL"]   to _eng:MaxPossibleThrustAt(0).
            set _destObj["MINTHROTTLE"]   to _eng:MinThrottle.
            set _destObj["MODES"]         to _eng:Modes.
        }
        else
        {
            set _destObj["ALLOWRESTART"]  to false.
            set _destObj["ALLOWSHUTDOWN"] to false.
            set _destObj["RESIDUALS"]     to 0.
            set _destObj["IGNREMAIN"]     to -1.
            set _destObj["ISPSL"]         to 0.
            set _destObj["ISPV"]          to 0.
            set _destObj["MAXBURNTIME"]   to -1.
            set _destObj["MAXFUELFLOW"]   to -1.
            set _destObj["MAXMASSFLOW"]   to -1.
            set _destObj["MAXTHRUST"]     to -1.
            set _destObj["MAXTHRUSTSL"]   to -1.
            set _destObj["MINTHROTTLE"]   to -1.
            set _destObj["MODES"]         to list().
        }

        return _destObj.
    }

    // GetShipEnginesSpecs :: [_ves<vessel>], [_bitMask<string>] -> Lexicon()
    // 
    global function GetShipEnginesSpecs
    {
        parameter _ves is Ship,
                  _dataMask is "1111110011000000".  // A 2-byte Bitmask to determine which data to hydrate during this iteration. Returns everything by default.

                                                // Any bit with a value of 1 will hydrate the data based on the table below, while a value of 0 will not. 
                                                // All non-hydrated data will retain default values (or not be included at all maybe?)

                                                    // Legend:          B0       |         B1
                                                    // CharIdx :   NB0  |   NB1  |   NB0   |   NB1   


                                                    // Byte 0, Nibble 0 - ENGUID
                                                    //   [0]   : (1)000 |        |          |           [ENGUID] Controls initial hydration of the ENGUID object in the output. 
                                                    //                                                  ENGUID is a lexicon of engine pointers and data data keyed by UID. 

                                                    //                                                  Additionl (Optional) switches:
                                                    //   [1]   : 1(1)00 |        |          |            -- Include Standard Eng Suffix Specs (MaxPossibleThrust, SLISP, VISP, Ignitions, etc)
                                                    //   [2]   : 10(1)0 |        |          |            -- Include ModuleEnginesRF data (Status, residuals, spool-up time, etc)
                                                    //   [3]   : 100(1) |        |          |            -- Include TestFlight module data (FlightData, MTBF & other failure info, etc)                                        


                                                    // Byte 0, Nibble 1  2 - IGNSTG
                                                    //   [4]   :        | (1)000 |          |           [IGNSTG] Controls initial hydration of the IGNSTG object in the output. 
                                                    //                                                  IGNSTG is a lexicon of engine UIDs keyed by ignition stage, with options for aggregated stage data available

                                                    //                                                  Additional (Optional) switches:
                                                    //   [5]   :        | 1(1)00 |          |            -- Transform / hydrate aggregated stage specs
                                                    //   [6]   :        | 10(1)0 |          |            -- Currently unused // TODO Include current aggregated performance data
                                                    //   [7]   :        | 100(1) |          |            -- Currently unused



                                                    // Byte 1, Nibble 0 - DCSTG
                                                    //   [8]   :        |        | (1)000   |           [DCSTG] Controls initial hydration of the DCSTG object in the output
                                                    //                                                  DCSTG is a lexicon of engine UIDs keyed by ignition stage, with options for aggregated stage data available

                                                    //                                                  Additional (Optional) switches:
                                                    //   [9]   :        |        | 1(1)00   |            -- Transform / hydrate aggregated stage specs
                                                    //   [10]  :        |        | 10(1)0   |            -- Currently unused // TODO Include current aggregated performance data
                                                    //   [11]  :        |        | 100(1)   |            -- Currently unused


                                                    // Byte 1, Nibble 1 - RESERVED FOR FUTURE USE
                                                    //   [12]  :        |        |          |  0000     [RSRVD] Currently unused
                                                    //                                                  This is a nibble reserved for future functionality flags



                                                    // - Example:   A _dataMask parameter of '1110110001000000' would return an engObj with the following (*) marked data hydrated, 
                                                    //              with any disabled ~top-level~ node(s) remaining the default initialized empty lex value. 
                                                    //              Disabled ~child~ nodes will either not run if their parent is disabled, or remain the default initialized value if the parent is active.
                                                    //  
                                                    //           *-- ENGUID: Lex of engines keyed by UID
                                                    //               *- Engine suffix specs 
                                                    //               *- ModuleEnginesRF data 
                                                    //                - TestFlight data (bit[3] = 0 means this block will not run)
                                                    //           *-- IGNSTG: Engines keyed by Ignition Stage
                                                    //               *- Aggregate Stage Specs
                                                    //            -- DCSTG: Engines keyed by decoupled in stage
                                                    //                - Aggregate Stage Specs
                                                    //                      *** NOTE how this is set to 1 in this example but the preceding 0 bit is the parent and therefore overrides it. 
                                                    //                          Basically, if the parent isn't active, none of the children can be regardless of their value


        local engObj to lexicon(
            "ENGUID", lex()
            ,"IGNSTG", lex()
            ,"DCSTG", lex()
        ).

        // Typechecking
        if _ves:IsType("Vessel")
        {
            for eng in _ves:Engines
            {
                local euid to eng:UID.
                // Eng pointer, basic info, and status
                if _dataMask[0]
                {
                    local engIgnitionStatus to choose "READY" if (not eng:Ignition and not eng:Flameout and eng:Ignitions > 0) else choose "FLAMEOUT" if eng:Flameout else "UNKNOWN".
                    local isBooster to choose false if eng:Decoupler = "None" else eng:Decoupler:Tag:Contains("Booster").
                    engObj:ENGUID:Add(euid, lex(
                        "ENG",           eng
                        ,"CONFIG",       eng:Config
                        ,"CONSUMEDRSRC", eng:ConsumedResources:Keys
                        ,"DECOUPLEDIN",  eng:DecoupledIn
                        ,"HASGIMBAL",    eng:HasGimbal
                        ,"IGNREMAIN",    eng:Ignitions
                        ,"IGNSTATUS",    engIgnitionStatus
                        ,"ISBOOSTER",    isBooster
                        ,"ISSEPMOTOR",   g_EngRef:SEP:Contains(eng:name)
                        ,"NAME",         eng:Name
                        ,"STAGE",        eng:Stage
                        ,"TITLE",        eng:Title
                        )
                    ).

                    // Addition data options
                    if _dataMask[1]
                    {
                        engObj:ENGUID[euid]:Add("ALLOWRESTART",  eng:AllowRestart).
                        engObj:ENGUID[euid]:Add("ALLOWSHUTDOWN", eng:AllowShutdown).
                        engObj:ENGUID[euid]:Add("ISPSL",         eng:SLISP).
                        engObj:ENGUID[euid]:Add("ISPV",          eng:VISP).
                        engObj:ENGUID[euid]:Add("MAXFUELFLOW",   eng:MaxFuelFlow).
                        engObj:ENGUID[euid]:Add("MAXMASSFLOW",   eng:MaxMassFlow).
                        engObj:ENGUID[euid]:Add("MAXTHRUST",     eng:MaxPossibleThrust).
                        engObj:ENGUID[euid]:Add("MAXTHRUSTSL",   eng:MaxPossibleThrustAt(0)).
                        engObj:ENGUID[euid]:Add("MINTHROTTLE",   eng:MinThrottle).
                        engObj:ENGUID[euid]:Add("MODES",         eng:Modes).
                    }
                    if _dataMask[2]
                    {
                        if eng:HasModule("ModuleEnginesRF")
                        {
                            local engRFModule to eng:GetModule("ModuleEnginesRF").

                            engObj:ENGUID[euid]:Add("MIXRATIO", GetField(engRFModule, "mixture ratio", 1)).
                            engObj:ENGUID[euid]:Add("RESIDUALS", GetField(engRFModule, "predicted residuals", 0)).
                            engObj:ENGUID[euid]:Add("PREDICTEDMASSFLOW", eng:MaxMassFlow * (1 - engObj:ENGUID[euid]:Residuals)).
                            engObj:ENGUID[euid]:Add("SPOOLTIME", GetField(engRFModule, "effective spool-up time", 0)).


                        }
                        else
                        {
                            engObj:ENGUID[euid]:Add("MIXRATIO", 1).
                            engObj:ENGUID[euid]:Add("RESIDUALS", 0).
                            engObj:ENGUID[euid]:Add("SPOOLTIME", 0).
                        }
                    }
                    if _dataMask[3]
                    {
                        local engData           to 0.0000001.
                        local ignChance         to 1.
                        local timeSinceLastRun  to 0.

                        local overburnAddedTime to 0.
                        local targetBurnTime    to -1.
                        local ratedBurnTime     to -1. 

                        if eng:HasModule("TestFlightReliability_EngineCycle")
                        {
                            local engTFRModule to eng:GetModule("TestFlightReliability_EngineCycle").
                            set engData to GetField(engTFRModule, "flight data", 0). 
                        }

                        if eng:HasModule("TestFlightFailure_IgnitionFail")
                        {
                            local engTFFModule to eng:GetModule("TestFlightFailure_IgnitionFail").

                            set ignChance to GetField(engTFFModule, "ignition chance", 0).
                            set timeSinceLastRun to GetField(engTFFModule, "time since shutdown", 0).
                        }

                        set overburnAddedTime   to 0.
                        set targetBurnTime      to -1.
                        set ratedBurnTime       to choose g_EngineConfigs[eng:Config][0] if g_EngineConfigs:Keys:Contains(eng:Config) else -1.

                        if ratedBurnTime > 0 and engData > 0
                        {
                            set overburnAddedTime to ratedBurnTime * (g_EngineConfigs[eng:Config][1] * (engData / l_MaxFlightData)).
                        }
                        
                        set targetBurnTime to ratedBurnTime + overburnAddedTime.

                        engObj:ENGUID[euid]:Add("FLIGHTDATA",       engData).
                        engObj:ENGUID[euid]:Add("IGNCHANCE",        ignChance).
                        engObj:ENGUID[euid]:Add("RATEDBURNTIME",    ratedBurnTime).
                        engObj:ENGUID[euid]:Add("TIMESINCELASTRUN", timeSinceLastRun).
                        engObj:ENGUID[euid]:Add("TARGETBURNTIME",   targetBurnTime).
                    }
                }

                // Creates a view with engines grouped by stage they are ignited
                if _dataMask[4]
                {
                    set engObj:IGNSTG to GroupEnginesByStage(eng, engObj, "IGN", _dataMask[5], engObj:IGNSTG:Copy).
                }

                // Creates a view with engines grouped by stage they are decoupled
                if _dataMask[8]
                {
                    set engObj:DCSTG to GroupEnginesByStage(eng, engObj, "DC", _dataMask[9], engObj:DCSTG:Copy).
                }
            }
        }

        return engObj.
    }


    // GetTestFlightModuleData
    local function GetTestFlightModuleData
    {
        parameter _eng,
                  _destObj to lex().

        local engData           to 0.
        local ignChance         to 1.
        local timeSinceLastRun  to 0.

        local overburnAddedTime to 0.
        local targetBurnTime    to -1.
        local ratedBurnTime     to -1. 

        if _eng:HasModule("TestFlightReliability_EngineCycle")
        {
            local engTFRModule to _eng:GetModule("TestFlightReliability_EngineCycle").
            set engData to GetField(engTFRModule, "flight data", 0). 
        }

        if _eng:HasModule("TestFlightFailure_IgnitionFail")
        {
            local engTFFModule to _eng:GetModule("TestFlightFailure_IgnitionFail").

            set ignChance to GetField(engTFFModule, "ignition chance", 0).
            set timeSinceLastRun to GetField(engTFFModule, "time since shutdown", 0).
        }

        set overburnAddedTime   to 0.
        set targetBurnTime      to -1.
        set ratedBurnTime       to choose g_EngineConfigs[_eng:Config][0] if g_EngineConfigs:Keys:Contains(_eng:Config) else -1.

        if ratedBurnTime > 0 and engData > 0
        {
            set overburnAddedTime to ratedBurnTime + (ratedBurnTime * (g_EngineConfigs[_eng:Config][1] * (engData / l_MaxFlightData))).
        }
        set targetBurnTime to ratedBurnTime + overburnAddedTime.

        set _destObj["FLIGHTDATA"]       to engData.
        set _destObj["IGNCHANCE"]        to ignChance.
        set _destObj["RATEDBURNTIME"]    to ratedBurnTime.
        set _destObj["TIMESINCELASTRUN"] to timeSinceLastRun.
        set _destObj["TOTALRUNTIME"]     to targetBurnTime.

        return _destObj.
    }

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

// #endregion