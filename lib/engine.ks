@LazyGlobal off.

// *~ Dependencies ~* //
// #region

// #endregion

// *~ Variables ~* //
// #region
    // *- Common Values
    // #region

    global tVal to 0.

    // #endregion

    // *- Reference Objects
    local __engRef to lexicon(
        "sep", lexicon(
            "names", list(
                "ROSmallSpinMotor"
            )
        )
    ).

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

    // get_vessel_engines :: ([_ves<Vessel>]) -> (_ves:Engines)<List[Engines]>
    // Returns all engines for a vessel, default is the core's ship.
    global function get_vessel_engines
    {
        parameter _ves is Core:Part:Ship.

        return _ves:Engines.
    }

    // map_vessel_engines :: (input params)<type> -> (output params)<type>
    // Maps engines by activations stage. Alternate mode will map by detachment stage
    global function map_vessel_engines
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

    // update_engine_map :: ([_inputEngMap<lex>]) -> _outputMap<lex>
    // Hydrates a givens engine map
    global function update_engine_map
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
            return map_vessel_engines().
        }

        return _inEngMap.
    }

    // get_burn_stage_engines:: ([_stgLim<int>]) -> (stgEngs<List[Engines]>)
    // Returns all engines for a given ignition stage
    global function get_burn_stage_engines
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

    // get_dc_stage_engines :: ([_stgLim<int>]) -> (stgEngs<List[Engines]>)
    // Returns all engines for a given ignition stage
    global function get_dc_stage_engines 
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

    // get_active_engines :: ([_ves<Vessel>], [_stgLim<int>]) -> (activeEngs<List[Engines]>)
    // Returns the engines on the vessel that are currently firing and not flamed out. 
    // Optional params will target other vessels and/or scope to only engines above a certain stage
    global function get_active_engines
    {
        parameter _ves is Ship,
                  _filter is "".

        local activeEngs to list().
        
        for eng in _ves:Engines
        {
            if eng:Ignition
            {
                if not eng:Flameout
                {
                    if _filter = "nosep"
                    {
                        if not __engRef:sep:names:Contains(eng:Name) or eng:Tag:Length > 0
                        {
                            activeEngs:Add(eng).
                        }
                    }
                    else
                    {
                        activeEngs:Add(eng).
                    }
                }
            }
        }
        return activeEngs.
    }
    // #endregion

    // *- Engine Ignition
    // #region

    // staged_engine_ignition
    // Ignites the engines to a given stage
    global function staged_engine_ignition
    {
        parameter _stgTo is Stage:Number - 1.

        set tVal to 1.
        lock throttle to tVal.
        
        until Stage:Number <= _stgTo
        {
            out_info("Engine ignition: [{0} -> {1}]":Format(Stage:Number, _stgTo)).
            wait until stage:ready.
            stage.
            local thrPct to choose (Round(Ship:Thrust / Ship:AvailableThrust) * 100) if Ship:Thrust > 0 and Ship:AvailableThrust > 0 else 0.
            out_info("Thrust: {0} [{1,5}%]":Format(Round(Ship:Thrust, 2), thrPct:tostring), 1).
        }

        return Stage:Number = _stgTo.
    }
    // #endregion
// #endregion