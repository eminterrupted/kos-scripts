// #include "0:/lib/depLoader.ks"
@LazyGlobal off.

// *~ Dependencies ~* //
// #region
// #endregion


// *~ Variables ~* //
// #region
    // *- Global
    // #region
    global g_engConfigs is lexicon(
         "A-4",         lex("BT", 70)
        ,"XLR43-NA-1",  lex("BT", 65)
        ,"Veronique",   lex("BT", 45)
    ).
    // #endregion
    
    // *- Local
    // #region
    // #endregion

    // *- Global Anonymous Delegates
    // #region
    // #endregion

    // *- Local Anonymous Delegates
    // #region
    // #endregion
// #endregion


// *~ Functions ~* //
// #region

    // *- Engine lists
    // #region

    // GetShipEngines
    global function GetShipEngines
    {
        parameter _ves is Ship.

        local engObj to lex(
              "DCSTG", lex()
            ,"ENGUID", lex()
            ,"IGNSTG", lex()
        ).

        if _ves:IsType("Vessel")
        {
            for eng in _ves:Engines
            {
                // First we will extracts some useful specification data from the modules
                local estResiduals  to 0.
                local mixRatio      to 1.
                local spoolTime     to 0.
                if eng:HasModule("ModuleEnginesRF")
                {
                    local engRFModule   to eng:GetModule("ModuleEnginesRF").

                    set estResiduals  to PMGetField(engRFModule, "predicted residuals", 0).
                    set mixRatio      to PMGetField(engRFModule, "mixture ratio", 1).
                    set spoolTime     to PMGetField(engRFModule, "effective spool-up time", 0).
                }

                // Collect data from the TestFlight modules
                local engData       to 0.
                local totRunTime    to 0.
                if eng:HasModule("TestFlightReliability_EngineCycle")
                {
                    local engTFRModule to eng:GetModule("TestFlightReliability_EngineCycle").

                    set engData to PMGetField(engTFRModule, "flight data", 0). 
                }

                local ignChance to 1.
                local timeSinceLastRun to 0.
                if eng:HasModule("TestFlightFailure_IgnitionFail")
                {
                    local engTFFModule to eng:GetModule("TestFlightFailure_IgnitionFail").

                    set ignChance to PMGetField(engTFFModule, "ignition chance", 0).
                    set timeSinceLastRun to PMGetField(engTFFModule, "time since shutdown", 0).
                }
                
                local ratedBurnTime to choose g_engConfigs[eng:Config]:BT if g_engConfigs:Keys:Contains(eng:Config) else -1.

                // Collect a pointer to the engine alongside all the useful data from above for later use
                engObj:ENGUID:Add(eng:UID, lex(
                        "ENG",              eng
                        ,"ALLOWRESTART",    eng:AllowRestart
                        ,"ALLOWSHUTDOWN",   eng:AllowShutdown
                        ,"CONFIG",          eng:Config
                        ,"CONSUMEDRSRC",    eng:ConsumedResources:Keys
                        ,"DECOUPLEDIN",     eng:DecoupledIn
                        ,"ENGDATA",         engData
                        ,"ENGNAME",         eng:Name
                        ,"ENGTITLE",        eng:Title
                        ,"ESTRESIDUALS",    estResiduals
                        ,"HASGIMBAL",       eng:HasGimbal
                        ,"IGNCHANCE",       ignChance
                        ,"IGNREMAIN",       eng:Ignitions
                        ,"ISPSL",           eng:SLISP
                        ,"ISPV",            eng:VISP
                        ,"MAXFUELFLOW",     eng:MaxFuelFlow
                        ,"MAXMASSFLOW",     eng:MaxMassFlow
                        ,"MAXTHRUST",       eng:MaxPossibleThrust
                        ,"MAXTHRUSTSL",     eng:MaxPossibleThrustAt(0)
                        ,"MINTHROTTLE",     eng:MinThrottle
                        ,"MIXRATIO",        mixRatio
                        ,"MULTIMODE",       eng:Multimode
                        ,"RATEDBURNTIME",   ratedBurnTime
                        ,"SPOOLTIME",       spoolTime
                        ,"STAGE",           eng:Stage
                        ,"TIMESINCELASTRUN",timeSinceLastRun
                        ,"TOTALRUNTIME",    totRunTime
                    )
                ).

                if engObj:IGNSTG:HasKey(eng:Stage)
                {
                    engObj:IGNSTG[eng:Stage]:UID:Add(eng:UID).
                    set engObj:IGNSTG[eng:Stage]:STGMAXTHRUST   to engObj:IGNSTG[eng:Stage]:STGMAXTHRUST   + eng:MaxPossibleThrust.
                    set engObj:IGNSTG[eng:Stage]:STGMAXTHRUSTSL to engObj:IGNSTG[eng:Stage]:STGMAXTHRUSTSL + eng:MaxPossibleThrustAt(0).
                    set engObj:IGNSTG[eng:Stage]:STGMAXFUELFLOW to engObj:IGNSTG[eng:Stage]:STGMAXFUELFLOW + eng:MaxFuelFlow.
                    set engObj:IGNSTG[eng:Stage]:STGMAXMASSFLOW to engObj:IGNSTG[eng:Stage]:STGMAXMASSFLOW + eng:MaxMassFlow.
                }
                else
                {
                    engObj:IGNSTG:Add(eng:Stage, lex(
                             "UID", list(eng:UID)
                            ,"STGMAXTHRUST", eng:MaxPossibleThrust
                            ,"STGMAXTHRUSTSL", eng:MaxPossibleThrustAt(0)
                            ,"STGMAXFUELFLOW", eng:MaxFuelFlow
                            ,"STGMAXMASSFLOW", eng:MaxMassFlow
                        )
                    ).

                }

                if engObj:DCSTG:HasKey(eng:DecoupledIn)
                {
                    engObj:DCSTG[eng:DecoupledIn]:Add(eng:UID).
                    set engObj:DCSTG[eng:Stage]:STGMAXTHRUST   to engObj:DCSTG[eng:Stage]:STGMAXTHRUST   + eng:MaxPossibleThrust.
                    set engObj:DCSTG[eng:Stage]:STGMAXTHRUSTSL to engObj:DCSTG[eng:Stage]:STGMAXTHRUSTSL + eng:MaxPossibleThrustAt(0).
                    set engObj:DCSTG[eng:Stage]:STGMAXFUELFLOW to engObj:DCSTG[eng:Stage]:STGMAXFUELFLOW + eng:MaxFuelFlow.
                    set engObj:DCSTG[eng:Stage]:STGMAXMASSFLOW to engObj:DCSTG[eng:Stage]:STGMAXMASSFLOW + eng:MaxMassFlow.
                }
                else
                {
                    engObj:DCSTG:Add(eng:DecoupledIn, lex(
                            "UID", list(eng:UID)
                            ,"STGMAXTHRUST", eng:MaxPossibleThrust
                            ,"STGMAXTHRUSTSL", eng:MaxPossibleThrustAt(0)
                            ,"STGMAXFUELFLOW", eng:MaxFuelFlow
                            ,"STGMAXMASSFLOW", eng:MaxMassFlow
                        )
                    ).
                }
            }
        }

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
                set burnTimeRated to g_engConfigs[_eng:Config]:BT * overBurnRatio.
            }
        }
        else if _eng:IsType("String")
        {
            if g_engConfigs:Keys:Contains(_eng)
            {
                set burnTimeRated to g_engConfigs[_eng]:BT * overBurnRatio.
            }
        }

        return list(burnTimeRated, burnTimePlus, burnTimeFuel).
    }
    
    // #endregion

// #endregion