@lazyGlobal off.
// #include "0:/lib/loadDep.ks"

// Variables *****

global g_stageInfo to lex(
    "HotStage",         uniqueSet(),
    "SpinStabilized",   uniqueSet(),
    "Engines",          lex(), 
    "Resources",        lex()
).


// Functions *****
global g_activeEngines to ActiveEngines().
lock g_activeEngines to ActiveEngines().

// *** Vessel Systems
// #region

    // *** Engines
    // #region
    // ActiveEngines :: [<vessel>Ship], [<bool>IncludeSepMotors] -> Lexicon<thrust, availThrust, engines, sepStage
    // Returns a lexicon containing currently active engines and perf data for those engines
    global function ActiveEngines
    {
        parameter ves is ship,
                  includeSepMotors to false.

        local actThr        to 0.
        local avlThr        to 0.
        local avlTWR        to 0.
        local curTWR        to 0.
        local fuelFlow      to 0.
        local fuelFlowMax   to 0.
        local massFlow      to 0.
        local massFlowMax   to 0.
        local engLex        to lex().
        local engList       to list().
        local sepflag       to true.
        local localGrav     to constant:g * (ves:body:radius / (ves:body:radius + ship:altitude))^2.

        local sumThr_Del_AllEng to { 
            parameter _eng. 

            engList:add(_eng). 
            set actThr to actThr + _eng:thrust. 
            set avlThr to avlThr + _eng:availableThrustAt(body:atm:altitudePressure(ship:altitude)).
            set fuelFlow to fuelFlow + _eng:fuelFlow.
            set fuelFlowMax to fuelFlowMax + _eng:maxFuelFlow.
            set massFlow to massFlow + _eng:massFlow.
            set massFlowMax to massFlowMax + _eng:maxMassFlow.
        }.

        local sumThr_Del_NoSep to
        {
            parameter _eng.

            if not g_partInfo["Engines"]["SepMotors"]:contains(_eng:name)
            {
                set sepFlag to false.
                engList:add(_eng). 
                set actThr to actThr + _eng:thrust. 
                set avlThr to avlThr + _eng:availableThrustAt(body:atm:altitudePressure(ship:altitude)).
                set fuelFlow to fuelFlow + _eng:fuelFlow.
                set fuelFlowMax to fuelFlowMax + _eng:maxFuelFlow.
                set massFlow to massFlow + _eng:massFlow.
                set massFlowMax to massFlowMax + _eng:maxMassFlow.
            }
        }.

        local sumThr_Del to choose sumThr_Del_AllEng@ if includeSepMotors else sumThr_Del_NoSep@.

        for eng in ves:engines 
        { 
            if eng:ignition and not eng:flameout
            {
                sumThr_Del:call(eng).
            }
        }

        set avlTWR to max(0.00001, avlThr) / (ves:mass * localGrav).
        set curTWR to max(0.00001, actThr) / (ves:mass * localGrav).
        
        return lex("Thrust", actThr, "AvailThrust", avlThr, "TWR", curTWR, "AvailTWR", avlTWR, "Engines", engList, "SepStage", sepFlag).
    }

    // TODO Write Engine Perf Module
    // GetEnginePerfData :: List<Engines> -> Lexicon<engine perf data>
    // Returns a lexicon containing engine performance data
    global function GetEnginePerfData
    {
        parameter _engList to ActiveEngines().

        return lexicon("Thrust", _engList["Thrust"], "TWR", _engList["TWR"], "AvailThrust", _engList["AvailThrust"], "AvailTWR", _engList["AvailTWR"], "FuelFlow", 0, "MassFlow", 0).
    }

    // GetResourcesFromEngines :: List<Engines> -> Lexicon<resource data>
    // Returns a lexicon containing data on the resources used by the passed-in engines
    global function GetResourcesFromEngines
    {
        parameter _engList to list().

        local _engRes_SummedPct to 0.
        local _resObj to lex("PctRemaining", 0, "Resources", lex()).

        if _engList:length > 0
        {
            for _eng in _engList
            {
                from { local _idx to 0.} until _idx > _eng:consumedResources:values:length step { set _idx to _idx + 1.} do
                {
                    local res to _eng:consumedResources:values[_idx].
                    set _resObj["Resources"][res:name] to res.

                    set _idx to _idx + 1.
                    set _engRes_SummedPct to (_engRes_SummedPct + (max(0.001, res:amount) / res:capacity)) / _idx.
                }
            }
        }
        set _resObj["PctRemaining"] to _engRes_SummedPct.
        return _resObj.
    }

    // InitActiveEngines :: none -> List<Engines>
    // Initializes the g_activeEngines variable.
    global function InitActiveEngines
    {
        if not (defined g_activeEngines) 
        {
            global lock g_activeEngines to list().
        }
        //set g_activeEngines to ActiveEngines().
        //return g_activeEngines.
    }

    // #endregion

    // *** Parachutes
    // #region
    // ArmChutes :: [<List<modules>>ParachuteModules] -> none
    // Arms a list of parachutes. By default, all chutes on vessel.
    global function ArmChutes
    {
        parameter chuteList is list().

        if chuteList:length = 0 set chuteList to ship:modulesNamed("RealChuteModule").
        for m in chuteList
        {
            m:doEvent("arm parachute").
        }
    }
    // #endregion

    // *** Staging
    // #region

    // ArmAutoStaging :: [<scalar>Stage to disbale auto staging] -> none
    // Initiates a staging trigger that will continue being preserved until the desired stage number is reached
    global function ArmAutoStaging
    {
        // Auto-stage
        when ship:availableThrust < 0.0005 then
        {
            SetStopStage(true).
            if stage:number > g_stopStage
            {
                OutMsg("Staging...").
                SafeStage().
                wait 0.10.

                if g_activeEngines:SepStage
                {
                    OutInfo("Sep motors activated, priming stage engines").
                    wait 0.50.
                    wait until stage:ready.
                    stage.
                }

                OutInfo("Engine ignition sequence initiated...").
                local ts_stg to time:seconds + 2.5.
                wait until time:seconds >= ts_stg or g_activeEngines:thrust > 0.01.
                
                OutMsg("Staging complete...").
                wait 0.10.

                if stage:number > g_stopStage
                {
                    preserve.
                }
                else
                {
                    OutMsg("StopStage reached").
                }
            }
        }
    }

    // HotStage :: [<scalar>TriggerOnResourcePctRemaining] -> none
    //  Stages once the average resources remaining in the tanks for the active engines
    //  reaches the threshold
    global function HotStage
    {
        parameter _stgPctTrigger to 0.0025.
        
        //set g_activeEngines   to ActiveEngines(ship).
        
        local _pctTrig  to _stgPctTrigger * 2.
        local _resObj   to GetResourcesFromEngines(g_activeEngines:engines).
        local pctRemain to 0.
        local resStart  to 0.
        local resEnd    to 0.
        local timeDenom to 0.

        OutMsg("Hot Staging in progress...").

        set resStart to _resObj:Resources:values[0]:amount.
        local ts to time:seconds + 1.

        until time:seconds >= ts
        {
            wait 0.01.
        }
        set resEnd to _resObj:Resources:values[0]:amount.
        local resRateSec to (resStart - resEnd) / 0.01.
        local timeRemaining to (_resObj:Resources:values[0]:amount - (_resObj:Resources:values[0]:amount * (_pctTrig * 2))) / resRateSec.
        set ts to time:seconds + timeRemaining.

        until pctRemain <= _pctTrig or time:seconds >= ts
        {
            set pctRemain to _resObj:PctRemaining.
            set sVal to ship:prograde.
            DispLaunchTelemetry().
            wait 0.01.
        }
        stage.

        if g_stageInfo["HotStage"]:contains(stage:number) 
        {
            g_stageInfo["HotStage"]:remove(stage:number). 
        }
        wait 0.25.
    }

    // SafeStage :: none -> none
    // Function to wait until staging is ready, stage the vessel, then update g_activeEngines
    global function SafeStage
    {
        local curStage to stage:number.
        OutInfo("Waiting for stage ready...").
        wait until stage:ready.
        OutInfo("Stage ready!").
        wait 0.25.
        stage.
        wait 0.25.
        if stage:number < curStage OutInfo("Stage successful!").
        set g_activeEngines to ActiveEngines(ship, false).
        wait 0.05.
    }
    // #endregion
// #endregion