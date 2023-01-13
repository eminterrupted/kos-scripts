@lazyGlobal off.
// #include "0:/lib/globals.ks"
// #include "0:/lib/loadDep.ks"

// Variables *****
global g_ShipEngines to lexicon().

global g_ArmAutoStage to false.

global g_boosterObj  to lexicon().
global g_BoosterSepArmed to false.

global g_stageInfo to lex(
    "HotStage",         uniqueSet(),
    "SpinStabilized",   uniqueSet(),
    "Engines",          lex(), 
    "Resources",        lex()
).

local v_SpoolTime to 0.
local StageLogic to lexicon(
    "DEF", {}
    ,"AutoStgOFF", { set g_ArmAutoStage to False. set g_StageLogicDelegate to stageLogic["AutoStgON"]@.}
    ,"AutoStgON", { set g_ArmAutoStage to True.}
).

global g_StageLogicTrigger to -99.
global g_StageLogicDelegate to stageLogic["DEF"]@.

local StgConDel to lexicon(
    "TS",      { parameter _tgtTS, _op.    return g_CompDel[_op]:Call(Time:Seconds, _tgtTS).  }
    ,"ETA_TS",  { parameter _tgtETA, _op.   return g_CompDel[_op]:Call(g_TS, (g_TS + _tgtETA)).}
    ,"ETA_AP",  { parameter _tgtETA, _op.   return g_CompDel[_op]:Call(ETA:Apoapsis,  _tgtETA).}
    ,"ETA_PE",  { parameter _tgtETA, _op.   return g_CompDel[_op]:Call(ETA:Periapsis, _tgtETA).}
    ,"AP",      { parameter _tgtAP, _op.    return g_CompDel[_op]:Call(Ship:Apoapsis, _tgtAP). }
    ,"PE",      { parameter _tgtPE, _op.    return g_CompDel[_op]:Call(Ship:Periapsis,_tgtPE). }
    ,"ALT",     { parameter _tgtAlt, _op.   return g_CompDel[_op]:Call(Ship:Altitude, _tgtAlt).}
    ,"ALTRDR",  { parameter _tgtAlt, _op.   return g_CompDel[_op]:Call(Alt:Radar, _tgtAlt).    }
).

// Functions *****
InitActiveEngines().
//lock g_ActiveEnginesLex to ActiveEngines().

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
        local engStatus     to "".
        local engList       to list().
        local sepflag       to true.
        local localGrav     to constant:g * (ves:Body:radius / (ves:Body:radius + ship:Altitude))^2.

        local sumThr_Del_AllEng to { 
            parameter _eng. 

            if not g_partInfo["Engines"]["SepMotors"]:contains(_eng:name) or (_eng:Tag:Length > 0 and _eng:Tag:Replace("sep",""):Length = _eng:Tag:Length)
            {
                set sepFlag to false.
            }

            engList:Add(_eng). 
            set actThr to actThr + _eng:thrust. 
            set avlThr to avlThr + _eng:AvailableThrustAt(body:Atm:AltitudePressure(ship:Altitude)).
            set fuelFlow to fuelFlow + _eng:fuelFlow.
            set fuelFlowMax to fuelFlowMax + _eng:maxFuelFlow.
            set massFlow to massFlow + _eng:massFlow.
            set massFlowMax to massFlowMax + _eng:maxMassFlow.
        }.

        local sumThr_Del_NoSep to
        {
            parameter _eng.

            if not g_partInfo["Engines"]["SepMotors"]:contains(_eng:name) or (_eng:Tag:Length > 0 and _eng:Tag:Replace("sep",""):Length = _eng:Tag:Length)
            {
                set sepFlag to false.
                engList:Add(_eng). 
                local m to _eng:GetModule("ModuleEnginesRF").
                if m:GetField("Status") = "Failed" 
                { 
                    set engStatus to m:GetField("Status"). 
                    set engFailReason to m:GetField("").
                }
                set actThr to actThr + _eng:thrust. 
                set avlThr to avlThr + _eng:AvailableThrustAt(body:Atm:AltitudePressure(ship:Altitude)).
                set fuelFlow to fuelFlow + _eng:fuelFlow.
                set fuelFlowMax to fuelFlowMax + _eng:maxFuelFlow.
                set massFlow to massFlow + _eng:massFlow.
                set massFlowMax to massFlowMax + _eng:maxMassFlow.
            }
        }.

        // TODO: add delegates for selection no solid rocket engines, and only solid rocket engines
        local sumThr_Del_NoSolids to {

        }.

        local sumThr_Del_OnlySolids to {

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
        
        return lex(
             "CURTHRUST", actThr
            ,"AVLTHRUST", avlThr
            ,"CURTWR", curTWR
            ,"AVLTWR", avlTWR
            ,"FUELFLOW", fuelFlow
            ,"FUELFLOWMAX", fuelFlowMax
            ,"MASSFLOW", massFlow
            ,"MASSFLOWMAX", massFlowMax
            ,"ENGLIST", engList
            ,"SEPSTG", sepFlag
            ,"ENGSTATUS", engStatus
        ).
    }

    // Given a list of engines, return perf data
    global function GetEnginePerfData
    {
        parameter engList is list().

        local actThr        to 0.
        local avlThr        to 0.
        local avlTWR        to 0.
        local curTWR        to 0.
        local fuelFlow      to 0.
        local fuelFlowMax   to 0.
        local massFlow      to 0.
        local massFlowMax   to 0.
        local engStatus     to "".
        local engFailReason to "".
        local localGrav     to constant:g * (Ship:Body:Radius / (Ship:Body:Radius + Ship:Altitude))^2.

        for _eng in engList
        {
            if _eng:ignition and not _eng:flameout
            {
                    local m to _eng:GetModule("ModuleEnginesRF").
                if m:GetField("Status") = "Failed" 
                { 
                    set engStatus to m:GetField("Status"). 
                    //set engFailReason to m:GetField("").
                }
                set actThr to actThr + _eng:Thrust. 
                set avlThr to avlThr + _eng:AvailableThrustAt(Body:Atm:AltitudePressure(Ship:Altitude)).
                set fuelFlow to fuelFlow + _eng:FuelFlow.
                set fuelFlowMax to fuelFlowMax + _eng:MaxFuelFlow.
                set massFlow to massFlow + _eng:MassFlow.
                set massFlowMax to massFlowMax + _eng:MaxMassFlow.
            }
        }.

        set avlTWR to max(0.00001, avlThr) / (Ship:Mass * localGrav).
        set curTWR to max(0.00001, actThr) / (Ship:Mass * localGrav).
        
        return lex(
             "CURTHRUST", actThr
            ,"AVLTHRUST", avlThr
            ,"THRPCT", actThr / avlThr
            ,"CURTWR", curTWR
            ,"AVLTWR", avlTWR
            ,"TWRSAFE", curTWR > 1.0
            ,"FUELFLOW", fuelFlow
            ,"FUELFLOWMAX", fuelFlowMax
            ,"MASSFLOW", massFlow
            ,"MASSFLOWMAX", massFlowMax
            ,"ENGLIST", engList
            ,"ENGSTATUS", engStatus
            ,"STATUSSTR", engFailReason
        ).
    }

    // GetActiveEngines :: <none> -> <List>Engines
    // Returns a list of the engines currently active (ignition == true and flameout == false)
    global function GetActiveEngines
    {
        parameter _includeSepMotors is false.

        local engList to list().

        for eng in ship:engines
        { 
            if eng:ignition and not eng:flameout
            {
                if _includeSepMotors { engList:Add(eng). }
                else if not g_partInfo["Engines"]["SepMotors"]:contains(eng:name) or eng:Tag:Replace("sep"):Length > 0 { engList:Add(eng). }
            }
        }
        return engList.
    }


    // GetEngineFlowData :: <List>Engines -> <Lexicon>EngineDataObject
    // Returns detailed lexicon containing data about engines, along with some stage-level engine values (i.e., ullage, fuelstability, etc)
    global function GetEngineFlowData
    {
        parameter _engList is GetActiveEngines().

        // local EngDataObj to lexicon().

        // local FuelStability to 0.
        // local PressureFed   to false.
        // local UllageFlag    to false.
        
        // local ActThr        to 0.
        // local AvlThr        to 0.
        // local AvlTWR        to 0.
        // local CurTWR        to 0.
        local FuelFlow      to 0.
        local FuelFlowMax   to 0.
        local MassFlow      to 0.
        local MassFlowMax   to 0.

        // TODO: Finish GetEngineData by adding additional functions for checking ullage, fuel stability, fuel flow, etc.
        for eng in _engList
        {
            // set ActThr to ActThr + eng:thrust. 
            // set AvlThr to AvlThr + eng:AvailableThrustAt(body:Atm:AltitudePressure(ship:Altitude)).
            set FuelFlow to FuelFlow + eng:fuelFlow.
            set FuelFlowMax to FuelFlowMax + eng:maxFuelFlow.
            set MassFlow to MassFlow + eng:massFlow.
            set MassFlowMax to MassFlowMax + eng:maxMassFlow.
        }

        return Lexicon("FUELFLOW", FuelFlow, "FUELFLOWMAX", FuelFlowMax, "MASSFLOW", MassFlow, "MassFlowMax", MassFlowMax).
    }



    // GetEnginesForStage :: <int>StageNumber -> <List>Engines
    // Returns the engines associated with a stage number. 
    // Empty list if no engines in that stage, or if _includeSepMotors is false and the only engines in the stage are sep motors.
    global function GetEnginesForStage
    {
        parameter _stgNum is Stage:Number,
                  _includeSepMotors is false.

        local engList to list().

        for eng in Ship:Engines
        {
            if eng:stage = _stgNum
            {
                if _includeSepMotors
                {
                    engList:Add(eng).
                }
                else if not g_partInfo["Engines"]["SepMotors"]:contains(eng:name) 
                {
                    engList:Add(eng).
                }
            }
        }
        return engList.
    }


    // GetNextEngines :: [<int>StageNumber] -> <Lexicon>EnginesObject 
    // Given a stage number, checks from that stage forward for the next set of non-sepratron engines
    // If no stage provided, defaults to current stage
    global function GetNextEngines
    {
        parameter _stgNum is Stage:Number,
                  _includeSepMotors is false.

        local nextEngList to list().

        for stgIdx in Range(_stgNum - 1, 0)
        {
            set nextEngList to GetEnginesForStage(stgIdx, _includeSepMotors).
            if nextEngList:Length > 0 { break. }
        }
        return nextEngList.
    }


    // GetShipEnginesObject :: <none> -> <Lexicon>
    // Returns a lexicon of engines on the vessel keyed by activation stage number
    global function GetShipEnginesObject
    {
        local EngineObj to lexicon().
        from { local i to stage:number.} until i < 0 step { set i to i - 1.} do 
        {
            set EngineObj[i] to lexicon("Engines", list(), "IsSepStage", True).
            for eng in Ship:Engines
            {
                if eng:stage = i
                {
                    if not g_PartInfo["Engines"]["SepMotors"]:contains(eng:name) or eng:Tag:Replace("sep",""):Length > 0
                    {
                        set EngineObj[i]["IsSepStage"] to False.
                    }

                    if not EngineObj[i]:HasKey("StgCon")
                    {
                        if eng:Tag:Contains("StgCon")
                        {
                            local stgCondList to ParseStageConditionTag(eng:tag).
                            set EngineObj[i]["StgCon"] to lexicon("ACTIVE", True, "COND", stgCondList[0], "OP", stgCondList[1], "TGTVAL", stgCondList[2], "CHKDEL", stgCondList[3]).
                        }
                        else
                        {
                            set EngineObj[i]["StgCon"] to lexicon("ACTIVE", False).
                        }
                    }
                }
            }
        }
        return EngineObj.
    }


    // SetGlobalShipEnginesObject :: <none> -> <none>
    // Method that refreshes the value of g_ShipEngines via GetShipEnginesObject
    global function SetGlobalShipEnginesObject
    {
        if not (defined g_ShipEngines) global g_ShipEngines to lexicon().
        set g_ShipEngines to GetShipEnginesObject().
    }


    // #endregion


    // ArmAutoBoosterSeparation :: <Lexicon>BoosterObject -> (none)
    // Creates a trigger for the boosters to seperate based on resource consumption
    global function ArmAutoBoosterSeparation
    {
        set g_BoosterObj to GetBoosters(ship).
        set g_line to 40.
        local disarmBoosterSep to { set g_BoosterSepArmed to false. }.
        local del_disarmBoosterSep to disarmBoosterSep@.
        if g_BoosterObj:PRESENT
        {
            for _setIdx in g_BoosterObj["BOOSTER_SETS"]:Keys
            {   
                // print "g_BoosterObj['BOOSTER_SETS']: {0}":format(g_BoosterObj:hasKey("BOOSTER_SETS")) at (2, g_line).
                // if g_BoosterObj:hasKey("BOOSTER_SETS") 
                // {
                //     print "g_BoosterObj['BOOSTER_SETS'][{0}]: {1}":format(_setIdx, g_BoosterObj["BOOSTER_SETS"]:hasKey(_setIdx)) at (2, cr()).
                //     if g_BoosterObj["BOOSTER_SETS"]:hasKey(_setIdx)
                //     {
                //         print "g_BoosterObj['BOOSTER_SETS'][{0}][{1}]: {2}":format(_setIdx, "DC", g_BoosterObj["BOOSTER_SETS"][_setIdx]:hasKey("DC")) at (2, cr()).
                //         if g_BoosterObj["BOOSTER_SETS"][_setIdx]:hasKey("DC")
                //         {
                //             print "{0,-10}: {1}":format("_stgIdx", _setIdx) at (2, cr()).
                //             // print g_BoosterObj["BOOSTER_SETS"][_stgIdx]["DC"] at (0, 50).
                //             print "g_BoosterObj['BOOSTER_SETS'][{0}][{1}]: {2}":format(_setIdx, "DC", g_BoosterObj["BOOSTER_SETS"][_setIdx]["DC"]:hasKey("MODULES")) at (2, cr()).
                //             if g_BoosterObj["BOOSTER_SETS"][_setIdx]["DC"]:hasKey("PARTLIST")
                //             {
                //                 print "{0,-10}: {1}":format("", true) at (2, cr()).
                //                 print g_BoosterObj["BOOSTER_SETS"][_setIdx]["DC"]:PARTLIST at (0, cr()).
                //             }
                //             else
                //             {
                //                 print "{0,-10}: {1}":format("DC", false) at (2, cr()).
                //                 cr().
                //                 cr().
                //                 cr().
                //             }
                //         }
                //     }
                // }
                
                // if g_BoosterObj["BOOSTER_SETS"]:hasKey(_setIdx)
                // {
                //     print "g_BoosterObj['BOOSTER_SETS'][{0}][{1}]: {2}":format(_setIdx, "RES", g_BoosterObj["BOOSTER_SETS"][_setIdx]:hasKey("RES")) at (2, cr()).
                //     if g_BoosterObj["BOOSTER_SETS"][_setIdx]:hasKey("RES")
                //     {
                        
                //         print "g_BoosterObj['BOOSTER_SETS'][{0}][{1}][{2}]: {3}":format(_setIdx, "RES", "MASS", g_BoosterObj["BOOSTER_SETS"][_setIdx]["RES"]:HasKey("MASS")) at (2, cr()).
                //         print "g_BoosterObj['BOOSTER_SETS'][{0}][{1}][{2}]: {3}":format(_setIdx, "RES", "PARTLIST", g_BoosterObj["BOOSTER_SETS"][_setIdx]["RES"]:HasKey("PARTLIST")) at (2, cr()).
                //         print "g_BoosterObj['BOOSTER_SETS'][{0}][{1}][{2}]: {3}":format(_setIdx, "RES", "PCT", g_BoosterObj["BOOSTER_SETS"][_setIdx]["RES"]:HasKey("PCT")) at (2, cr()).
                //         print "g_BoosterObj['BOOSTER_SETS'][{0}][{1}][{2}]: {3}":format(_setIdx, "RES", "TYPES", g_BoosterObj["BOOSTER_SETS"][_setIdx]["RES"]:HasKey("TYPES")) at (2, cr()).
                //         print "g_BoosterObj['BOOSTER_SETS'][{0}][{1}][{2}]: {3}":format(_setIdx, "RES", "UNITS", g_BoosterObj["BOOSTER_SETS"][_setIdx]["RES"]:HasKey("UNITS")) at (2, cr()).
                //     }
                // }

                //when (g_BoosterObj["BOOSTER_SETS"][_stgIdx]["RES"]["PCT"] <= 0.0125) or (Ship:Status <> "PRELAUNCH" and (g_BoosterObj["BOOSTER_SETS"][_stgIdx]["ENG"]["AVLTHRUST"] <= 5)) then
                when (g_BoosterObj["BOOSTER_SETS"][_setIdx]["RES"]["PCT"] <= 0.0125) or (Ship:Status <> "PRELAUNCH" and (g_BoosterObj["BOOSTER_SETS"][_setIdx]["ENG"]["PCT"] <= 0.10 )) then
                {
                    del_DisarmBoosterSep:call().
                    OutInfo("Staging booster set " + _setIdx).
                    from { local i to 0.} until i = g_BoosterObj["BOOSTER_SETS"][_setIdx]["DC"]["MODULES"]:Length step { set i to i + 1.} do 
                    {
                        local dc to g_BoosterObj["BOOSTER_SETS"][_setIdx]["DC"]["MODULES"][i].
                        if dc:HasEvent("decouple") 
                        {
                            dc:DoEvent("decouple").
                            OutInfo("Staging success").
                        }
                        else
                        {
                            OutInfo("Staging failure - Decouple event not found on part").
                        }
                    }
                    g_BoosterObj["BOOSTER_SETS"]:Remove(_setIdx).
                }
            }
        }
    }

    // JettisonFairings :: <string>PartTag -> <none>
    global function JettisonFairings
    {
        parameter _fairingTag is "fairingSep".

        for m in Ship:ModulesNamed("ProceduralFairingSide")
        {
            if m:Part:Tag:MatchesPattern(_fairingTag)
            {
                local fairingDecoupler to m:Part:GetModule("ProceduralFairingDecoupler").
                if DoEvent(fairingDecoupler, "decouple")
                {
                    OutInfo("Fairing jettison").
                }
                else if DoEvent(fairingDecoupler, "jettison fairing")
                {
                    OutInfo("Fairing jettison").
                }
                else if DoAction(fairingDecoupler, "decouple", true)
                {
                    OutInfo("Fairing jettison").
                }
                else
                {
                    OutInfo("No valid event or action found on fairing module").
                }
            }
        }
    }

    
    // GetBoosters :: [<none>] -> <lexicon>Boosters
    // Returns any strap-on boosters on the vessel that are tagged with 'booster.<n>'
    global function GetBoosters
    {
        parameter _ves is ship.

        //local b_lex         to lexicon().
        local stg_lex        to lexicon().
        local i             to 0.
        local idSet         to UniqueSet().
        local regex         to "".
        local stgBoosters   to list().
        local stgBoosterThr to 0.
        local stgResPct     to 0.
        local stgResLex     to lexicon().
        local stgResMass    to 0.
        local stgResSet     to uniqueSet().
        local stgResUnits   to 0.
        local uniqueBoosterID to uniqueSet().

        local b_lex to lexicon(
            "PRESENT", false, 
            "BOOSTER_SETS", lexicon()
        ).

        // Get the number of booster stages
        for b in _ves:PartsTaggedPattern("booster.\d+")
        {
            idSet:Add(b:Tag:replace("booster.",""):ToNumber()).
        }

        // Iterate through the stages
        for boosterID in idSet
        {
            set b_lex["PRESENT"]    to true.

            set regex               to "booster.{0}":format(boosterID).
            set stgBoosters         to ship:PartsTaggedPattern(regex).

            set stg_lex             to lex().
            set stgBoosterThr       to 0.
            set stgResPct           to 0.
            set stgResLex           to lexicon().
            set stgResMass          to 0.
            set stgResSet           to uniqueSet().
            set stgResUnits         to 0.

            uniqueBoosterID:Add(boosterID).
            if b_lex:HasKey(boosterID)
            {
                set stg_lex to b_lex["BOOSTER_SETS"][boosterID].
            }
            else
            {
                set stg_lex to lexicon(
                    "DC", lexicon(
                         "PARTLIST", list()
                        ,"MODULES",  list()   
                    ),
                    "ENG", lex(
                         "AVLTHRUST", 0
                        ,"PARTLIST", list()
                        ,"PCT",      0
                        ,"THRUST",   0
                    ),
                    "PARTLIST", list(),
                    "RES", lex(
                         "PCT",      0
                        ,"MASS",     0
                        ,"TYPES",    Lexicon()
                        ,"UNITS",    0
                        ,"PARTLIST", list()
                    )
                ).
            }

            for _item in stgBoosters
            {
                if _item:IsType("Decoupler")
                {
                    set stg_lex to ProcessBoosterItem(_item:TypeName, _item, boosterID, stg_lex).
                }
                else
                {
                    set stg_lex to ProcessBoosterItem(_item:TypeName, _item:Decoupler, boosterID, stg_lex).
                }
            }
            // Unset all the globals we created in the previous loop
            if defined _stgSummedThr_Cur 
            {
                unset _stgSummedThr_Cur.
                unset _stgSummedThr_Avl.
                unset _stgSummedEngs_Count.
                unset _stgSummedThr_Pct.
            }

            set b_lex["BOOSTER_SETS"][boosterID] to stg_lex.
        }
        return b_lex.
    }

    // TODO Write Engine Perf Module
    // GetEnginePerfData :: List<Engines> -> Lexicon<engine perf data>
    // Returns a lexicon containing engine performance data
    global function GetEnginePerfData_Old
    {
        parameter _engList to ActiveEngines().

        return lexicon("CURTHRUST", _engList["CURTHRUST"], "CURTWR", _engList["CURTWR"], "AVLTHRUST", _engList["AVLTHRUST"], "AVLTWR", _engList["AVLTWR"], "FUELFLOW", 0, "MASSFLOW", 0).
    }

    // GetResourcesFromEngines :: List<Engines> -> Lexicon<resource data>
    // Returns a lexicon containing data on the resources used by the passed-in engines
    global function GetResourcesFromEngines
    {
        parameter _engList to list().

        local _engRes_SummedPct to 0.
        local _engRes_SummedAmt to 0.
        local _engRes_SummedCap to 0.
        local _engRes_FuelFlow  to 0.
        local _engRes_MaxFuelFlow to 0.
        local _engRes_MassFlow  to 0.
        local _engRes_MaxMassFlow to 0.
        local _engRes_ResidualUnits to 0.
        
        local _resObj to lex(
             "PctRemaining",_engRes_SummedPct
            ,"Amt",   _engRes_SummedAmt
            ,"Cap",   _engRes_SummedCap
            ,"FuelFlow", _engRes_FuelFlow
            ,"MaxFuelFlow", _engRes_MaxFuelFlow
            ,"MassFlow", _engRes_MassFlow
            ,"MaxMassFlow", _engRes_MaxMassFlow
            ,"Resources",   lex()
        ).

        OutInfo("Engine: {0} ({1})":format(_engList[0]:name, _engList[0]:tag), 2).
        if _engList:Length > 0
        {
            for _eng in _engList
            {
                set _engRes_FuelFlow to _engRes_FuelFlow + _eng:FuelFlow.
                set _engRes_MaxFuelFlow to _engRes_MaxFuelFlow + _eng:MaxFuelFlow.
                set _engRes_MassFlow to _engRes_MassFlow + _eng:MassFlow.
                set _engRes_MaxMassFlow to _engRes_MaxMassFlow + _eng:MaxMassFlow.
                
                from { local _idx to 0.} until _idx > _eng:consumedResources:values:Length step { set _idx to _idx + 1.} do
                {
                    local res to _eng:consumedResources:values[_idx].
                    if not g_ResIgnoreList:Contains(res:name)
                    {
                        OutInfo("Processing Resource: {0}":format(res:name), 3).
                        set _resObj["Resources"][res:name] to res.
                        set _idx to _idx + 1.
                        set _engRes_SummedAmt to _engRes_SummedAmt + res:amount.
                        set _engRes_SummedCap to _engRes_SummedCap + res:capacity.
                        set _engRes_SummedPct to (_engRes_SummedPct + (max(0.001, res:Amount) / max(0.001, res:capacity))) / _idx.
                    }
                    else
                    {
                        OutInfo("Ignoring resource: {0}":format(res:name), 3).
                    }
                }

                set _engRes_ResidualUnits to _engRes_ResidualUnits + (_engRes_SummedCap * _eng:GetModule("ModuleEnginesRF"):GetField("Predicted Residuals")).
            }

            set _resObj["Amt"] to _engRes_SummedAmt.
            set _resObj["Cap"] to _engRes_SummedCap.
            set _resObj["FuelFlow"] to _engRes_FuelFlow.
            set _resObj["MaxFuelFlow"] to _engRes_MaxFuelFlow.
            set _resObj["MassFlow"] to _engRes_MassFlow.
            set _resObj["MaxMassFlow"] to _engRes_MaxMassFlow.
            set _resObj["Residuals"] to _engRes_ResidualUnits.
            set _resObj["TimeRemaining"] to 2 * ((_engRes_SummedAmt - _engRes_ResidualUnits) / _engRes_FuelFlow).
        }
        else
        {
            OutInfo("No engines in _engList", 2).
        }
        set _resObj["PctRemaining"] to _engRes_SummedPct.
        return _resObj.
    }

    
    // InitActiveEngines :: none -> none
    // Initializes the g_ActiveEnginesLex variable.
    global function InitActiveEngines
    {
        SetGlobalShipEnginesObject().
        
        if not (defined g_ActiveEnginesLex) 
        {
            global g_ActiveEnginesLex to lexicon().
        }
        set g_ActiveEnginesLex to ActiveEngines().
    }

    // #endregion

    // *** Parachutes
    // #region
    // ArmChutes :: [<List<modules>>ParachuteModules] -> none
    // Arms a list of parachutes. By default, all chutes on vessel.
    global function ArmChutes
    {
        parameter chuteList is list().

        if chuteList:Length = 0 set chuteList to ship:modulesNamed("RealChuteModule").
        for m in chuteList
        {
            m:doAction("arm parachute", true).
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
        set g_ArmAutoStage to True.
        when (ship:AvailableThrust < 0.001 and g_ArmAutoStage) then
        {
            if stage:number > g_stopStage
            {
                OutMsg("Staging...").
                SafeStage().
                wait 0.10.

                if g_ActiveEnginesLex:SepStg
                {
                    OutInfo("Sep motors activated, priming stage engines").
                    wait 0.50.
                    wait until stage:ready.
                    stage.
                }

                OutInfo("Engine ignition sequence initiated...").
                local ts_stg to Time:Seconds + 2.5.
                wait until Time:Seconds >= ts_stg or g_ActiveEnginesLex["CURTHRUST"] > 0.01.
                
                OutMsg("Staging complete...").
                wait 0.10.

                if stage:number = g_StageLogicTrigger
                {
                    g_StageLogicDelegate:Call().
                    OutInfo("STAGE LOGIC TRIGGER | Current Stage [{0}] | g_stopStage [{1}]":format(stage:number, g_stopStage), 1).
                }
                else if stage:number > g_stopStage
                {
                    OutInfo("STAGE PRESERVE | Current Stage [{0}] | g_stopStage [{1}]":format(stage:number, g_stopStage), 1).
                    set g_ArmAutoStage to True.
                    preserve.
                }
                else
                {
                    OutInfo("STAGE STOP | Current Stage [{0}] | g_stopStage [{1}]":format(stage:number, g_stopStage), 1).
                    set g_ArmAutoStage to False.
                }
            }
        }
    }



    
    // Given a stage number, it will determine if any engines in that stage have engine spool properties
    global function CheckEngineSpool
    {
        parameter stgNum.

        local hasSpoolTime to false.
        local maxSpoolTime to 0.0001.

        for _e in ship:engines 
        {
            if _e:stage = stgNum
            {
                local _m to _e:GetModule("ModuleEnginesRF").
                if _m:HasField("effective spool-up time") 
                {
                    set hasSpoolTime to true.
                    set maxSpoolTime to Max(_m:GetField("effective spool-up time"), maxSpoolTime).
                }
                else
                {
                    set maxSpoolTime to maxSpoolTime.
                }
            }
        }
        return list(hasSpoolTime, maxSpoolTime).
    }



    global function ArmHotStaging
    {
        local _engList to Ship:PartsTaggedPattern("(^HotStg$|^HotStage$)").
        if _engList:Length > 0
        {
            set g_StageLogicTrigger to _engList[0]:Stage + 1.
            set g_ActiveEngines to GetActiveEngines().
            set g_ActiveEnginesLex to ActiveEngines().
            set g_ConsumedResources to GetResourcesFromEngines(g_ActiveEngines).
            local engSpool to CheckEngineSpool(Stage:Number - 1).
            if engSpool[0] 
            {
                set v_SpoolTime to engSpool[1] + 0.1.
            }
            OutInfo("HotStaging Armed").

            // HotStaging Trigger
            when Stage:Number = g_StageLogicTrigger then
            {
                when g_ConsumedResources["TimeRemaining"] <= v_SpoolTime then
                {
                    OutInfo("HOT STAGING: IGNITION (0%)").
                    for eng in _engList
                    {
                        eng:Activate.
                    }
                    set g_TS to Time:Seconds + v_SpoolTime.
                    wait 0.01.
                    local engPerf to GetEnginePerfData(_engList).
                    until engPerf["THRPCT"] >= 0.75 or Time:Seconds >= g_TS
                    {
                        set engPerf to GetEnginePerfData(_engList).
                        OutInfo("HOT STAGING: IGNITION ({0}%)":Format(Round(engPerf["THRPCT"] * 100, 2))).
                        wait 0.01.
                    }
                    OutInfo("HOT STAGING: STAGING ({0}%)":Format(Round(engPerf["THRPCT"] * 100, 2))).

                    until Stage:Number = g_StageLogicTrigger
                    {
                        wait until Stage:Ready.
                        Stage.
                    }
                }
                set g_StageLogicTrigger to -99.
            }
            return true.
        }
        else
        {
            return false.
        }
    }




    global function CheckHotStageCondition
    {
        
        if hotStageActive
        {
            rcs on.
            set g_ActiveEnginesLex to ActiveEngines().
            if Time:Seconds >= g_TS and (g_ActiveEnginesLex["CURTHRUST"] / g_ActiveEnginesLex["AVLTHRUST"]) > 0.925
            {
                OutInfo("HotStaging: Decoupling").
                wait until Stage:Ready.
                Stage.
                set hotStageActive to false.
                set hotStageFlag to false.
                set g_TS to 0.
            }
        } 
        else
        {
            set g_ConsumedResources to GetResourcesFromEngines(GetActiveEngines()).
            OutInfo("T-Resource: {0} | T-HotStage: {1}":Format(Round(g_ConsumedResources["TimeRemaining"], 2), Round(g_ConsumedResources["TimeRemaining"] - _spoolTime, 2))).
            if g_ConsumedResources["TimeRemaining"] <= _spoolTime
            {
                OutInfo("HotStaging: Ignition").
                wait until Stage:Ready.
                Stage. // Hotstage!
                set g_TS to Time:Seconds + _spoolTime.
                set hotStageActive to true.
            }
        }
    }


    local function ParseStageConditionTag
    {
        parameter _partTag.

        if _partTag:Contains("StgCon")
        {
            local scStartPos to _partTag:Find("StgCon").
            local scStrLen   to choose _partTag:FindAt("|", scStartPos + 1) if _partTag:Contains("|") else _partTag:Length.
            local stgCondStr to _partTag:SubString(scStartPos, scStrLen).
            local stgCondList to stgCondStr:Split(".").

            local _cond    to choose stgCondList[1] if stgCondList:Length > 1 else "ETA".
            local _operand to choose stgCondList[2] if stgCondList:Length > 2 else "GE".
            local _thresh  to choose stgCondList[3] if stgCondList:Lenght > 3 else 0.

            if _cond = "ETA"
            {
                if g_TS < 0 
                {
                    set g_TS to Time:Seconds + _thresh.
                }
            }

            return list(_cond, _operand, _thresh, StgConDel[_cond]@).
        }
    }

    // CheckStagingCondition :: <part> -> <int>([-1|0|1])
    // Checks if a part has a valid staging condition defined in the name tag. 
    // - If so, checks that condition and returns 1 (True), 0 (False), or -1 (Missing / Invalid Condition)
    local function CheckStagingCondition
    {
        parameter _chkStg to Stage:Number - 1.
        
        local _stgConObj to choose g_ShipEngines[_chkStg]["StgCon"] if g_ShipEngines[_chkStg]:HasKey("StgCon") else Lexicon("Active", False).

        if _stgConObj:Active
        {
            if _stgConObj["CheckDelegate"]:Call(_stgConObj:TgtVal, _stgConObj:Op)
            {
                return 1.
            }
            else 
            {
                return 0.
            }
        }
        return -1.
    }

    // HotStage :: [<scalar>TriggerOnResourcePctRemaining] -> none
    //  Stages once the average resources remaining in the tanks for the active engines
    //  reaches the threshold
    global function HotStage
    {
        parameter _stgPctTrigger to 0.0025.
        
        //set g_ActiveEnginesLex   to ActiveEngines(ship).
        
        local _pctTrig  to _stgPctTrigger * 2.
        local _resObj   to GetResourcesFromEngines(g_ActiveEnginesLex:engines).
        local pctRemain to 0.
        local resStart  to 0.
        local resEnd    to 0.

        OutMsg("Hot Staging in progress...").

        set resStart to _resObj:Resources:values[0]:Amount.
        local ts to Time:Seconds + 1.

        until Time:Seconds >= ts
        {
            wait 0.01.
        }
        set resEnd to _resObj:Resources:values[0]:Amount.
        local resRateSec to (resStart - resEnd) / 0.01.
        local timeRemaining to (_resObj:Resources:values[0]:Amount - (_resObj:Resources:values[0]:Amount * (_pctTrig * 2))) / resRateSec.
        set ts to Time:Seconds + timeRemaining.

        until pctRemain <= _pctTrig or Time:Seconds >= ts
        {
            set pctRemain to _resObj:PctRemaining.
            set s_val to ship:prograde.
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
    // Function to wait until staging is ready, stage the vessel, then update g_ActiveEnginesLex
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
        set g_ActiveEnginesLex to ActiveEngines(ship, false).
        wait 0.05.
    }
    // #endregion
// #endregion

local function ProcessBoosterItemResource
{
    parameter   item is "",
                obj is lexicon().

    
    if obj:HasKey("RES") 
    {
        // if obj["RES"]:HasKey("PARTLIST")
        // {
        //    obj["RES"]["PARTLIST"]:Add(item). 
        // }
        // else
        // {
        //     set obj["RES"]["PARTLIST"] to list(item).
        // }

        if obj["RES"]:HasKey("TYPES")
        {
            if obj["RES"]["TYPES"]:HasKey(item:Name) { obj["RES"]["TYPES"][item:Name]:Add(item). }
            else { set obj["RES"]["TYPES"][item:Name] to list(item). }
        }
        else
        {
            set obj["RES"]["TYPES"] to lexicon(item:Name, list(item)).
        }

        if obj["RES"]:HasKey("MASS")
        {
            set obj["RES"]["MASS"]  to obj["RES"]["MASS"] + (item:Amount * item:Density).
        }
        set obj["RES"]["PCT"]   to ((obj["RES"]["PCT"] * (obj["RES"]["TYPES"]:Keys:Length - 1))+ (item:Amount / item:capacity)) / obj["RES"]["TYPES"]:Keys:Length.
        set obj["RES"]["UNITS"] to obj["RES"]["UNITS"] + item:Amount.
    }
    else
    {
        set obj["RES"] to lexicon(
            "PARTLIST", list(item),
            "MASS", item:Amount * item:density,
            "PCT", item:Amount / item:capacity,
            "TYPES", Lexicon(item:name, list(item)),
            "UNITS", item:Amount
        ).
    }
    return obj.
}

// Local Functions
local function ProcessBoosterItem
{
    parameter   type is "",
                item is "",
                bID is 0,
                obj is lexicon().

    if not (defined _stgSummedThr_Cur) 
    {
        global _stgSummedThr_Cur        to 0.
        global _stgSummedThr_Avl        to 0.
        global _stgSummedEngs_Count     to 0.
        global _stgSummedThr_Pct        to 0.
    }

    //local _stgBoosterThr_Avl to 0.
    // local _stgResMass        to 0.
    // local _stgResPct         to 0.
    // local _stgResUnits       to 0.
   
    if item:IsType("PART")
    {
        if item:IsType("ENGINE")
        {
            local _stgBoosterThr_Avl to item:AVAILABLETHRUSTAT(Body:Atm:AltitudePressure(Ship:Altitude)).
            
            set _stgSummedThr_Avl to _stgSummedThr_Avl + _stgBoosterThr_Avl.
            set _stgSummedThr_Cur to _stgSummedThr_Cur + item:Thrust.
            set _stgSummedEngs_Count to _stgSummedEngs_Count + 1.
            set _stgSummedThr_Pct to (max(0.00001, _stgSummedThr_Cur) / max(0.00001, _stgSummedThr_Avl)).// / _stgSummedEngs_Count.
            
            if obj:HasKey("ENG")
            {
                if obj["ENG"]:hasKey("AVLTHRUST") { set obj["ENG"]["AVLTHRUST"] to _stgSummedThr_Avl. }
                if obj["ENG"]:HasKey("PARTLIST")  { obj["ENG"]["PARTLIST"]:Add(item). }
                if obj["ENG"]:hasKey("PCT")       { set obj["ENG"]["PCT"] to _stgSummedThr_Pct. }
                if obj["ENG"]:hasKey("THRUST")    { set obj["ENG"]["THRUST"] to _stgSummedThr_Cur.}
            }
            else
            {
                set obj["ENG"] to lexicon(
                    "AVLTHRUST", _stgSummedThr_Avl
                    ,"PARTLIST", list(item)
                    ,"PCT",      _stgSummedThr_Pct
                    ,"THRUST",   _stgSummedThr_Cur
                ).
            }
        }
        else if type = "DECOUPLER" or type = "SEPARATOR"
        {
            local modDecoupleFlag to false.
            local modAnchoredFlag to false.
            if item:hasModule("ModuleDecouple")
            {
                set modDecoupleFlag to true.
            }
            else if item:HasModule("ModuleAnchoredDecoupler")
            {
                set modAnchoredFlag to true.
            }

            if obj:HasKey("DC")
            {
                obj["DC"]["PARTLIST"]:Add(item).
                if modDecoupleFlag 
                {
                    obj["DC"]["MODULES"]:Add(item:GetModule("ModuleDecouple")).
                }
                else if modAnchoredFlag
                {
                    obj["DC"]["MODULES"]:Add(item:GetModule("ModuleAnchoredDecoupler")).
                }
            }
            else
            {
                local dcMod to choose item:GetModule("ModuleDecouple") if modDecoupleFlag else choose item:GetModule("ModuleAnchoredDecoupler") if modAnchoredFlag else "".
                set obj["DC"] to lexicon(
                    "PARTLIST", list(item),
                    "MODULES", list(dcMod)
                ).
            }
        }

        if obj:hassuffix("PARTLIST")
        {
            obj["PARTLIST"]:Add(item).
        }
        else
        {
            set obj["PARTLIST"] to list(item).
        }

        if item:Resources:Length > 0
        {
            if not obj:HasKey("RES")
            { 
                set obj["RES"] to lexicon(
                    "MASS", 0
                    ,"PARTLIST", list()
                    ,"PCT", 0
                    ,"TYPES", Lexicon()
                    ,"UNITS", 0
                    ,"CAPACITY", 0
                ).
            }

            for _i_res in item:Resources
            {
                set obj to ProcessBoosterItemResource(_i_res, obj).
            }
        }

        set obj to ProcessBoosterItemChildren(item, bID, obj).
    }
    else if item:IsType("RESOURCE")
    {
        if obj:HasKey("RES") 
        {
            set obj["RES"]["MASS"]  to obj["RES"]["MASS"] + (item:Amount * item:density).
                obj["RES"]["PARTLIST"]:Add(item).
                obj["RES"]["TYPES"][item:name]:Add(item).
            
            local summedUnits to obj["RES"]["UNITS"] + item:Amount.
            local summedCapacity to obj["RES"]["CAPACITY"] + item:Capacity.

            set obj["RES"]["PCT"] to (summedUnits / summedCapacity).
            set obj["RES"]["UNITS"] to summedUnits.
            set obj["RES"]["CAPACITY"] to summedCapacity.
        }
        else
        {
            set obj["RES"] to lexicon(
                "MASS", item:Amount * item:density
                ,"PARTLIST", list(item)
                ,"PCT", item:Amount / item:capacity
                ,"TYPES", Lexicon(item:name, list(item))
                ,"UNITS", item:Amount
                ,"CAPACITY", item:Capacity
            ).
        }
    }
    return obj.
}

// Local Functions
// local function ProcessBoosterItem2
// {
//     parameter   type is "",
//                 item is "",
//                 bID is "",
//                 obj is lexicon().

//     local del_stgBoosterItem to ProcessBoosterItem@. // For recursion maybe?

//     local _stgBoosterThr     to 0.
//     local _stgResMass        to 0.
//     local _stgResPct         to 0.
//     local _stgResUnits       to 0.
//     local _stgResCapacity    to 0.
   
//     if item:IsType("PART")
//     {
//         if item:IsType("ENGINE")
//         {
//             set _stgBoosterThr to _stgBoosterThr + item:AVAILABLETHRUST.
//             if obj:HasKey("ENG")
//             {
//                 print "_stgBoosterThr: {0}":format(_stgBoosterThr) at (2, 40).
//                 print "item: {0}":format(item) at (2, 41).
//                 print "item:THRUST: {0}":format(item:AvailableThrust) at (2, 42).
//                 if obj["ENG"]:hasKey("AVLTHRUST") {
//                     //print "ENG/AVLTHRUST: true" at (2, 55).
//                     set obj["ENG"]["AVLTHRUST"] to _stgBoosterThr.
//                 }
//                 if obj["ENG"]:HasKey("PARTLIST") obj["ENG"]["PARTLIST"]:Add(item).
//                 //Breakpoint().
//             }
//             else
//             {
//                 set obj["ENG"] to lexicon(
//                     "AVLTHRUST", _stgBoosterThr
//                 ).
//             }
//         }
//         else if type = "DECOUPLER" or type = "SEPARATOR"
//         {
//             local modDecoupleFlag to false.
//             local modAnchoredFlag to false.
//             if item:hasModule("ModuleDecouple")
//             {
//                 set modDecoupleFlag to true.
//             }
//             else if item:HasModule("ModuleAnchoredDecoupler")
//             {
//                 set modAnchoredFlag to true.
//             }

//             if obj:HasKey("DC")
//             {
//                 obj["DC"]["PARTLIST"]:Add(item).
//                 if modDecoupleFlag 
//                 {
//                     obj["DC"]["MODULES"]:Add(item:GetModule("ModuleDecouple")).
//                 }
//                 else if modAnchoredFlag
//                 {
//                     obj["DC"]["MODULES"]:Add(item:GetModule("ModuleAnchoredDecoupler")).
//                 }
//             }
//             else
//             {
//                 set obj["DC"] to lexicon(
//                     "PARTLIST", list()
//                     ,"MODULES", list()
//                 ).
//             }
//         }

//         if obj:hassuffix("PARTLIST")
//         {
//             obj["PARTLIST"]:Add(item).
//         }
//         else
//         {
//             set obj["PARTLIST"] to list(item).
//         }

//         if item:Resources:Length > 0
//         {
//             if not obj:HasKey("RES")
//             { 
//                 set obj["RES"] to lexicon(
//                     "PARTLIST", list()
//                     ,"MASS", 0
//                     ,"PARTLIST", list()
//                     ,"PCT", 0
//                     ,"TYPES", Lexicon()
//                     ,"UNITS", 0
//                     ,"CAPACITY", 0
//                 ).
//             }

//             for _i_res in item:Resources
//             {
//                 if obj["RES"]:HasKey("RES_PARTS")
//                 {
//                     if obj["RES"]["RES_PARTS"]:hasKey(_i_res:name)
//                     {
//                         obj["RES"]["PARTS_BY_RES"][_i_res:name]:Add(item:cid).
//                     }
//                     else
//                     {
//                         set obj["RES"]["PARTS_BY_RES"][_i_res:name] to list(item:cid).
//                     }
//                 }
//                 set obj to del_stgBoosterItem:call("RESOURCE", _i_res, bID, obj).
//             }
//         }

//         set obj to ProcessBoosterItemChildren(item, bID, obj).
//     }
//     else if item:IsType("RESOURCE")
//     {
//         if obj:HasKey("RES") 
//         {
//                 obj["RES"]["PARTLIST"]:Add(item).
//                 obj["RES"]["TYPES"]:Add(item:name).
//             set obj["RES"]["MASS"]  to _stgResMass + (item:Amount * item:Density).
//             set obj["RES"]["PCT"]   to (_stgResPct + (item:Amount / item:Capacity)) / obj["RES"]["PARTLIST"]:Length.
//             set obj["RES"]["UNITS"] to _stgResUnits + item:Amount.
//             set obj["RES"]["CAPACITY"] to _stgResCapacity + item:Capacity.
//         }
//         else
//         {
//             set obj["RES"] to lexicon(
//                 "PARTLIST", list(item),
//                 "MASS", item:Amount * item:density,
//                 "PARTLIST", list(),
//                 "PCT", item:Amount / item:capacity,
//                 "TYPES", UniqueSet(item:name),
//                 "UNITS", item:Amount
//             ).
//         }
//     }
//     return obj.
// }


local function ProcessBoosterItemChildren
{
    parameter _item, _bID, _obj.

    local _iChildren to _item:Children.
    
    for _child in _iChildren
    {
        set _obj to ProcessBoosterItem(_child:typeName, _child, _bID, _obj).
    }
    return _obj.
}


local function GetEnginesInTree 
{ 
    parameter _p0. 
    
    local _engDel to GetEnginesInTree@.
    local _engList to list().
    if _p0:IsType("engine") _engList:Add(_p0).

    local _p0Children to _p0:children.
    for _p1 in _p0Children
    {
        _engDel:call(_p1).
    }
    return _engList.
}