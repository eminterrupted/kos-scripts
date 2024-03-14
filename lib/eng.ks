// #include "0:/lib/depLoader.ks"
@LazyGlobal off.

// *~ Dependencies ~* //
// #region
// #endregion


// *~ Variables ~* //
// #region
    // *- Global
    // #region
    
    // #endregion
    
    // *- Local
    // #region
    local l_MaxFlightData to 10000.
    // #endregion

    // *- Global Anonymous Delegates
    // #region
    // #endregion

    // *- Local Anonymous Delegates
    // #region
    // #endregion

    // *- Misc Reference Objects
    
    // Manually-curated object holding info about engine configurations that isn't typically available via APIs (usually seen only in UI)
    // Legend: 
    //  - BTR [BurnTime(Rated)]: Rated burn time based on the engine config. 
    //  - OBR [OverBurnRatio]  : The max percentage amount of rated burn time that can be added to the BTR value, used like this: BTR + (BTR * ((CurFlightData / MaxFlightData) * OBR). 
    //                           * This results in a sliding scale of increasing overburn time as more flight data comes in, and that hopefully results in safer overburns. 
    global g_engConfigs is lexicon(
         "A-4",         lex("BTR", 70, "OBR", 0.14)
        ,"XLR43-NA-1",  lex("BTR", 65, "OBR", 0.14)
        ,"Veronique",   lex("BTR", 45, "OBR", 0.20)
        ,"U-1250",      lex("BTR", 56, "OBR", 0.22)
    ).
// #endregion


// *~ Global Functions ~* //
// #region

    // *- Engine lists
    // #region

    // GetShipEngines :: [_ves<vessel>], [_bitMask<string>] -> Lexicon()
    // 
    global function GetShipEngines
    {
        parameter _ves is Ship,
                  _dataMask is "111111001100".  // A Bitmask to determine which data to hydrate during this iteration. Returns everything by default.
                                                // All non-hydrated data will retain default values (or not be included at all maybe?)
                                                    // Legend:
                                                    // CharIdx :   B1   |   B2   |   B3   

                                                    // Byte 1 - ENGUID
                                                    //   [0]   : (1)000 |        |        : [ENGUID] Lexicon of engine data keyed by UID. First bit will add a pointer and engine status to the object. 
                                                    //                                      Additionl (Optional) switches:
                                                    //   [1]   : 1(1)00 |        |           -- Include Standard Eng Suffix Specs (MaxPossibleThrust, SLISP, VISP, Ignitions, etc)
                                                    //   [2]   : 10(1)0 |        |           -- Include ModuleEnginesRF data (Status, residuals, spool-up time, etc)
                                                    //   [3]   : 100(1) |        |           -- Include TestFlight module data (FlightData, MTBF & other failure info, etc)                                        

                                                    // Byte 2 - IGNSTG
                                                    //   [4]   :        | (1)000 |        : [IGNSTG] Lexicon of engine UIDs keyed by ignition stage. 
                                                    //                                      Additional (Optional) switches:
                                                    //   [5]   :        | 1(1)00 |           -- Include aggregated stage specs
                                                    //   [6]   :        | 10(1)0 |           -- Currently unused // TODO Include current aggregated performance data
                                                    //   [7]   :        | 100(1) |           -- Currently unused

                                                    // Byte 3 - DCSTG
                                                    //   [8]   :        |        | (1)000 : [DCSTG] Lexicon of engine UIDs keyed by the stage they are decoupled in. 
                                                    //                                      Additional (Optional) switches:
                                                    //   [9]   :        |        | 1(1)00    -- Include aggregated stage specs
                                                    //   [10]  :        |        | 10(1)0    -- Currently unused // TODO Include current aggregated performance data
                                                    //   [11]  :        |        | 100(1)    -- Currently unused

                                                    // - Example:   A _dataMask parameter of '111011000100' would return an engObj with the following (*) marked data hydrated, 
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

        Breakpoint("[{0}]: GetShipEngs Started":Format(Round(Time:Seconds, 2))).

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
                    
                    engObj:ENGUID:Add(euid, lex(
                        "ENG",           eng
                        ,"CONFIG",       eng:Config
                        ,"CONSUMEDRSRC", eng:ConsumedResources:Keys
                        ,"DECOUPLEDIN",  eng:DecoupledIn
                        ,"HASGIMBAL",    eng:HasGimbal
                        ,"IGNREMAIN",    eng:Ignitions
                        ,"IGNSTATUS",    engIgnitionStatus
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

                            engObj:ENGUID[euid]:Add("MIXRATIO", PMGetField(engRFModule, "mixture ratio", 1)).
                            engObj:ENGUID[euid]:Add("RESIDUALS", PMGetField(engRFModule, "predicted residuals", 0)).
                            engObj:ENGUID[euid]:Add("SPOOLTIME", PMGetField(engRFModule, "effective spool-up time", 0)).
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
                            set engData to PMGetField(engTFRModule, "flight data", 0). 
                        }

                        if eng:HasModule("TestFlightFailure_IgnitionFail")
                        {
                            local engTFFModule to eng:GetModule("TestFlightFailure_IgnitionFail").

                            set ignChance to PMGetField(engTFFModule, "ignition chance", 0).
                            set timeSinceLastRun to PMGetField(engTFFModule, "time since shutdown", 0).
                        }

                        set overburnAddedTime   to 0.
                        set targetBurnTime      to -1.
                        set ratedBurnTime       to choose g_engConfigs[eng:Config]:BTR if g_engConfigs:Keys:Contains(eng:Config) else -1.

                        if ratedBurnTime > 0 and engData > 0
                        {
                            set overburnAddedTime to ratedBurnTime + (ratedBurnTime * (g_engConfigs[eng:Config]:OBR * (engData / l_MaxFlightData))).
                        }
                        set targetBurnTime to ratedBurnTime + overburnAddedTime.

                        engObj:ENGUID[euid]:Add("FLIGHTDATA",       engData).
                        engObj:ENGUID[euid]:Add("IGNCHANCE",        ignChance).
                        engObj:ENGUID[euid]:Add("RATEDBURNTIME",    ratedBurnTime).
                        engObj:ENGUID[euid]:Add("TIMESINCELASTRUN", timeSinceLastRun).
                        engObj:ENGUID[euid]:Add("TOTALRUNTIME",     targetBurnTime).
                    }
                }

                // Creates a view with engines grouped by stage they are ignited
                if _dataMask[4]
                {
                    set engObj:IGNSTG to GroupEnginesByStage(eng, "IGN", _dataMask[5], engObj:IGNSTG).
                }

                // Creates a view with engines grouped by stage they are decoupled
                if _dataMask[8]
                {
                    set engObj:DCSTG to GroupEnginesByStage(eng, "DC", _dataMask[9], engObj:DCSTG).
                }
            }
        }

        Breakpoint("[{0}]: GetShipEngs Complete":Format(Round(Time:Seconds, 2))).
        WriteJson(engObj, "0:/test/data/idfk.json").

        return engObj.
    }

    // #endregion

    // *- Engine Stats
    // #region

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
            if g_engConfigs:Keys:Contains(_eng:Config)
            {
                set burnTimeRated to g_engConfigs[_eng]:BTR.
                set burnTimePlus to burnTimeRated * overBurnRatio.
            }
        }
        else if _eng:IsType("String")
        {
            if g_engConfigs:Keys:Contains(_eng)
            {
                set burnTimeRated to g_engConfigs[_eng]:BTR.
                set burnTimePlus to burnTimeRated * overBurnRatio.
            }
        }

        return list(burnTimeRated, burnTimePlus, burnTimeFuel).
    }
    
    // #endregion

// #endregion


// *~ Local helper functions ~* //
// #region

    // ProcessIgnitionStageEngines
    // Helper for adding constructing a lex that contains UID pointers to engs, grouped by stage number, with optional extended stage data available
    local function GroupEnginesByStage
    {
        parameter _eng,
                  _stgType is "IGN", // Two possible values here - IGN, or the stage it's activated in, and DC, or the stage it's decoupled in.
                  _extendedInfo is false,
                  _objRef is lex().

        local stageGroup to choose _eng:DecoupledIn if _stgType = "DC" else _eng:Stage.
        // local groupIDStr to choose "DCSTG"          if _stgType = "DC" else "IGNSTG".

        if _objRef:HasKey(stageGroup)
        {
            _objRef[stageGroup]:UID:Add(_eng:UID).
            set _objRef[stageGroup]:STGMAXTHRUST to _objRef[stageGroup]:STGMAXTHRUST + _eng:MaxPossibleThrust.

            if _extendedInfo
            {
                set _objRef[stageGroup]:STGMAXTHRUST   to _objRef[stageGroup]:STGMAXTHRUST   + _eng:MaxPossibleThrust.
                set _objRef[stageGroup]:STGMAXTHRUSTSL to _objRef[stageGroup]:STGMAXTHRUSTSL + _eng:MaxPossibleThrustAt(0).
                set _objRef[stageGroup]:STGMAXFUELFLOW to _objRef[stageGroup]:STGMAXFUELFLOW + _eng:MaxFuelFlow.
                set _objRef[stageGroup]:STGMAXMASSFLOW to _objRef[stageGroup]:STGMAXMASSFLOW + _eng:MaxMassFlow.
                set _objRef[stageGroup]:STGMAXSPOOL    to Max(_objRef[stageGroup]:STGMAXSPOOL, _eng:GetModule("ModuleEnginesRF"):GetField("effective spool-up time")).
            }

        }
        else
        {
            if _extendedInfo
            {
                _objRef:Add(stageGroup, lex(
                    "UID", list(_eng:UID)
                    ,"STGMAXTHRUST",    _eng:MaxPossibleThrust
                    ,"STGMAXTHRUSTSL",  _eng:MaxPossibleThrustAt(0)
                    ,"STGMAXFUELFLOW",  _eng:MaxFuelFlow
                    ,"STGMAXMASSFLOW",  _eng:MaxMassFlow
                    ,"STGMAXSPOOL",     Max(0, _eng:GetModule("ModuleEnginesRF"):GetField("effective spool-up time"))
                    )
                ).
            }
            else
            {
                _objRef:Add(stageGroup, lex(
                    "UID", list(_eng:UID)
                    ,"STGMAXTHRUST",    0
                    ,"STGMAXTHRUSTSL",  0
                    ,"STGMAXFUELFLOW",  0
                    ,"STGMAXMASSFLOW",  0
                    ,"STGMAXSPOOL",     0
                    )
                ).
            }
        }

        return _objRef.
    }

    // GetEngineModuleData 
    // Extract some useful specification data from engine module
    local function GetEngineModuleData
    {
        parameter _eng,
                  _destObj to lex().

        if _eng:HasModule("ModuleEnginesRF")
        {
            local engRFModule to _eng:GetModule("ModuleEnginesRF").

            set _destObj["MIXRATIO"]    to PMGetField(engRFModule, "mixture ratio", 1).
            set _destObj["RESIDUALS"]   to PMGetField(engRFModule, "predicted residuals", 0).
            set _destObj["SPOOLTIME"]   to PMGetField(engRFModule, "effective spool-up time", 0).              
        }
        else
        {
            set _destObj["MIXRATIO"]  to 1.
            set _destObj["RESIDUALS"] to 0.
            set _destObj["SPOOLTIME"] to 0.
        }

        return _destObj.
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
            set engData to PMGetField(engTFRModule, "flight data", 0). 
        }

        if _eng:HasModule("TestFlightFailure_IgnitionFail")
        {
            local engTFFModule to _eng:GetModule("TestFlightFailure_IgnitionFail").

            set ignChance to PMGetField(engTFFModule, "ignition chance", 0).
            set timeSinceLastRun to PMGetField(engTFFModule, "time since shutdown", 0).
        }

        set overburnAddedTime   to 0.
        set targetBurnTime      to -1.
        set ratedBurnTime       to choose g_engConfigs[_eng:Config]:BTR if g_engConfigs:Keys:Contains(_eng:Config) else -1.

        if ratedBurnTime > 0 and engData > 0
        {
            set overburnAddedTime to ratedBurnTime + (ratedBurnTime * (g_engConfigs[_eng:Config]:OBR * (engData / l_MaxFlightData))).
        }
        set targetBurnTime to ratedBurnTime + overburnAddedTime.

        set _destObj["FLIGHTDATA"]       to engData.
        set _destObj["IGNCHANCE"]        to ignChance.
        set _destObj["RATEDBURNTIME"]    to ratedBurnTime.
        set _destObj["TIMESINCELASTRUN"] to timeSinceLastRun.
        set _destObj["TOTALRUNTIME"]     to targetBurnTime.

        return _destObj.
    }

// #endregion