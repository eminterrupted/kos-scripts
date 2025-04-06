@LazyGlobal off.

// *~ Dependencies ~* //
// #region

// #endregion

// *~ Variables ~* //
// #region
    // *- Common Values
    // #region

    // #endregion

    // *- Delegates
    // #region

    // #endregion
// #endregion

// *** Library Setup Code *** //
// This should rarely be used! //
// #region

// #endregion

// *~ Functions ~* //
// #region

    // *- Engine Enumeration
    // #region

    // :: Global
    // #region
    
    // GetVesselEngines :: ([_ves<Vessel>]) -> (_ves:Engines)<List[Engines]>
    // Returns all engines for a vessel, default is the core's ship.
    global function GetVesselEngines
    {
        parameter _ves is Core:Part:Ship.

        return _ves:Engines.
    }

    // MapVesselEngines :: (input params)<type> -> (output params)<type>
    // Maps engines by activations stage. Alternate mode will map by detachment stage
    global function MapVesselEngines
    {
        parameter _ves is Core:Part:Ship,
                  _mapByDetachStage is false.

        local engMap to lexicon("MapByDC", _mapByDetachStage, "Stg", lex()).

        for eng in _ves:Engines
        {
            local mapStage to choose eng:DecoupledIn if _mapByDetachStage else eng:Stage.

            if engMap:StgSet:HasKey(mapStage)
            {
                engMap:StgSet[mapStage]:Engs:Add(eng).
                set engMap:StgSet[mapStage]:TotThr to engMap:StgSet[mapStage]:TotThr + eng:Thrust.
                set engMap:StgSet[mapStage]:AvailThr to engMap:StgSet[mapStage]:AvailThr + eng:AvailableThrust.
                set engMap:StgSet[mapStage]:PossThr to engMap:StgSet[mapStage]:PossThr + eng:PossibleThrust.
            }
            else
            {
                set engMap:StgSet[mapStage] to lexicon(
                    "Engs", list(eng),
                    "TotThr", eng:Thrust,
                    "AvailThr", eng:AvailableThrust,
                    "PossThr", eng:PossibleThrust
                ).
            }
        }

        return _ves:Engines.
    }

    // UpdateEngineMap :: ([_inputEngMap<lex>]) -> _outputMap<lex>
    // Hydrates a givens engine map
    global function UpdateEngineMap
    {
        parameter _inEngMap is lexicon(),
                  _engList is Ship:Engines.

        if _inEngMap:HasKey("MapByDC")
        {
            for eng in _engList
            {
                local mapStage to choose eng:DecoupledIn if _inEngMap:MapByDC else eng:Stage.

                if _inEngMap:StgSet:HasKey(mapStage)
                {
                    _inEngMap:StgSet[mapStage]:Engs:Add(eng).
                    set _inEngMap:StgSet[mapStage]:TotThr to _inEngMap:StgSet[mapStage]:TotThr + eng:Thrust.
                    set _inEngMap:StgSet[mapStage]:AvailThr to _inEngMap:StgSet[mapStage]:AvailThr + eng:AvailableThrust.
                    set _inEngMap:StgSet[mapStage]:PossThr to _inEngMap:StgSet[mapStage]:PossThr + eng:PossibleThrust.
                }
                else
                {
                    set _inEngMap:StgSet[mapStage] to lexicon(
                        "Engs", list(eng),
                        "TotThr", eng:Thrust,
                        "AvailThr", eng:AvailableThrust,
                        "PossThr", eng:PossibleThrust
                    ).
                }
            }
        }
        else
        {
            return MapVesselEngines().
        }

        return _inEngMap.
    }

    // GetBurnStageEngines :: ([_stgLim<int>]) -> (stgEngs<List[Engines]>)
    // Returns all engines for a given ignition stage
    global function GetBurnStageEngines 
    {
        parameter _ves is Ship,
                  _stg is Stage:Number,
                  _includeAllAvailable is false.

        local stgEngs to list().
        
        if _includeAllAvailable
        {
            for eng in _ves:Engines
            {
                if eng:Stage >= _stg
                {
                    stgEngs:Add(eng).
                }
            }
        }
        else
        {
            for eng in _ves:Engines
            {
                if eng:Stage = _stg
                {
                    stgEngs:Add(eng).
                }
            }
        }
        return stgEngs.
    }

    // GetDCStageEngines :: ([_stgLim<int>]) -> (stgEngs<List[Engines]>)
    // Returns all engines for a given ignition stage
    global function GetDCStageEngines 
    {
        parameter _ves is Ship,
                  _stg is Stage:Number,
                  _includeAllAvailable is false.

        local stgEngs to list().
        
        if _includeAllAvailable
        {
            for eng in _ves:Engines
            {
                if eng:DecoupledIn >= _stg
                {
                    stgEngs:Add(eng).
                }
            }
        }
        else
        {
            for eng in _ves:Engines
            {
                if eng:DecoupledIn = _stg
                {
                    stgEngs:Add(eng).
                }
            }
        }
        return stgEngs.
    }

    // GetActiveEngines :: ([_ves<Vessel>], [_stgLim<int>]) -> (activeEngs<List[Engines]>)
    // Returns the engines on the vessel that are currently firing and not flamed out. 
    // Optional params will target other vessels and/or scope to only engines above a certain stage
    global function GetActiveEngines
    {
        parameter _ves is Ship.

        local activeEngs to list().
        
        for eng in _ves:Engines
        {
            if eng:Ignition
            {
                if not eng:Flameout
                {
                    activeEngs:Add(eng).
                }
            }
        }
        return activeEngs.
    }
    // #endregion

    // :: Local
    // #region
    
    // FunctionName :: (input params)<type> -> (output params)<type>
    // Description
    
    // #endregion
    
    // #endregion

// #endregion