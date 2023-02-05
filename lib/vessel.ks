@lazyGlobal off.
// #include "0:/lib/globals.ks"
// #include "0:/lib/loadDep.ks"
// #include "0:/lib/engines.ks"

// Variables *****
local v_SpinReady to false.


global g_ShipEngines to lexicon().

global g_ArmAutoStage to false.

global g_boosterObj  to lexicon().
global g_BoosterSepArmed to false.

local StageLogic to lexicon(
    "DEF", {}
    ,"AutoStgOFF", { set g_ArmAutoStage to False. set g_StageLogicDelegate to stageLogic["AutoStgON"]@.}
    ,"AutoStgON", { set g_ArmAutoStage to True.}
).

global g_StageLogicTrigger to -99.
global g_StageLogicDelegate to stageLogic["DEF"]@.

local _etaDel to { parameter _ETA, _Threshold is 0, _opType is "LE". return g_OP[_opType]:Call(_ETA, Abs(_Threshold)).}.
local _tsDel  to { parameter _TS,  _Threshold is 0, _opType is "GE". return g_OP[_opType]:Call(Time:Seconds, _TS).    }.
local _obtDel to { 
    parameter _obtPrm, _tgtVal, _opType is "LE". 
    
    if _obtPrm = "AP"          { return g_OP[_opType]:Call(Ship:Apoapsis, _tgtVal). } 
    else if _obtPrm = "PE"     { return g_OP[_opType]:Call(Ship:Periapsis, _tgtVal).} 
    else if _obtPrm = "ALT"    { return g_OP[_opType]:Call(Ship:Altitude, _tgtVal). }
    else if _obtPrm = "RDRALT" { return g_OP[_opType]:Call(ALT:Radar,     _tgtVal). }
    return false.
}.

local StgConDel to lexicon(
    "ETA",      { parameter _ETA, _Threshold is 0, _opType is "LE". return g_OP[_opType]:Call(_ETA, Abs(_Threshold)).}
    ,"TS",      _tsDel@
    ,"ETA_TS",  _tsDel@
    ,"ETA_AP",  _etaDel:Bind(ETA:Apoapsis)@
    ,"ETA_PE",  _etaDel:Bind(ETA:Periapsis)@
    ,"ETA_ECO", _etaDel:Bind(g_ETA_ECO)@
    ,"AP",      _obtDel:Bind("AP")@
    ,"PE",      _obtDel:Bind("PE")@
    ,"ALT",     _obtDel:Bind("ALT")@
    ,"ALTRDR",  _obtDel:BIND("RDRALT")@
).

local FieldByName to lexicon(
    "ETA", lexicon(
        "AP", { return ETA:Apoapsis.}
        ,"PE", { return ETA:Periapsis.}
        ,"G_TS", { return g_TS - Time:Seconds.}
        ,"NA", { return Time:Seconds * 999. }
    ),
    "ALT", lexicon(
        "AP", { return Ship:Apoapsis. }
        ,"PE", { return Ship:Periapsis.}
    )
).

local StgConInit to lexicon(
    "ETA", { parameter _BaseValStr, _LeadTime. set g_ETA_TS to Time:Seconds + FieldByName["ETA"][_BaseValStr]:Call() + _LeadTime. return g_ETA_TS.}
    ,"ALT", { parameter _BaseValStr, _LeadAlt. }
).

local NewStageInfo to lexicon(
    "HotStage",         lexicon()
    ,"SpinStg",        lexicon()
    ,"Engines",         lexicon()
    ,"Resources",       lexicon()
    ,"Stages",          lexicon()
    ,"Conditions",      lexicon()
).

set g_StageInfo to NewStageInfo:Copy().

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

        local lastUpdate    to 0.
        local actThr        to 0.
        local avlThr        to 0.
        local avlTWR        to 0.
        local curTWR        to 0.
        local fuelFlow      to 0.
        local fuelFlowMax   to 0.
        local massFlow      to 0.
        local massFlowMax   to 0.
        local maxSpoolTime  to 0.
        local engList       to list().
        local sepflag       to true.
        local localGrav     to GetLocalGravity(ves:Body, ves:Altitude).

        local causeStr      to "N/A".
        local failStr       to "N/A".
        local statusStr     to "NOMINAL".
        local engStatusLex  to lexicon("Status", statusStr, "Cause", causeStr, "FailedEngs", lex()).

        local sumThr_Del_AllEng to { 
            parameter _eng. 

            if not g_partInfo["Engines"]["SepMotors"]:contains(_eng:name) or (_eng:Tag:Length > 0 and _eng:Tag:Replace("sep",""):Length = _eng:Tag:Length)
            {
                set sepFlag to false.
            }

            engList:Add(_eng). 
            local _engMod to _eng:GetModule("ModuleEnginesRF").
            if _engMod:GetField("Status"):MatchesPattern(".*(FAILED)+.*")
            {
                set failStr to choose _engMod:GetField("cause") if _engMod:HasField("cause") else "UNKNOWN".
                set statusStr to "[{0}]:{1}":Format("FAILED", failStr).
                set engStatusLex["FailedEngs"][_eng:CID] to "[{0}]:{1}":Format("FAILED", failStr).
                set engStatusLex["Status"] to "FAILED".
                set g_ErrLvl to 1.
                // #TODO PartHighlighting
                // if g_PartHighlighting_On 
                // {

                // }
            }
            set actThr to actThr + _eng:thrust. 
            set avlThr to avlThr + _eng:AvailableThrustAt(body:Atm:AltitudePressure(ship:Altitude)).
            set fuelFlow to fuelFlow + _eng:fuelFlow.
            set fuelFlowMax to fuelFlowMax + _eng:maxFuelFlow.
            set massFlow to massFlow + _eng:massFlow.
            set massFlowMax to massFlowMax + _eng:maxMassFlow.
            set maxSpoolTime to choose max(maxSpoolTime, _engMod:GetField("effective spool-up time")) if _engMod:HasField("effective spool-up time") else maxSpoolTime.
        }.

        local sumThr_Del_NoSep to
        {
            parameter _eng.

            if not g_partInfo["Engines"]["SepMotors"]:contains(_eng:name) or (_eng:Tag:Length > 0 and _eng:Tag:Replace("sep",""):Length = _eng:Tag:Length)
            {
                set sepFlag to false.
                engList:Add(_eng). 
                local _engMod to _eng:GetModule("ModuleEnginesRF").
                if _engMod:GetField("Status"):MatchesPattern(".*FAILED.*")
                {
                    set failStr to choose _engMod:GetField("cause") if _engMod:HasField("cause") else "UNKNOWN".
                    set statusStr to "[{0}]:{1}":Format("FAILED", failStr).
                    set engStatusLex["FailedEngs"][_eng:CID] to "[{0}]:{1}":Format("FAILED", failStr).
                    set engStatusLex["Status"] to "FAILED".
                    
                    // #TODO PartHighlighting
                    // if g_PartHighlighting_On 
                    // {

                    // }
                }
                set actThr to actThr + _eng:thrust. 
                set avlThr to avlThr + _eng:AvailableThrustAt(body:Atm:AltitudePressure(ship:Altitude)).
                set fuelFlow to fuelFlow + _eng:fuelFlow.
                set fuelFlowMax to fuelFlowMax + _eng:maxFuelFlow.
                set massFlow to massFlow + _eng:massFlow.
                set massFlowMax to massFlowMax + _eng:maxMassFlow.
                set maxSpoolTime to choose max(maxSpoolTime, _engMod:GetField("effective spool-up time")) if _engMod:HasField("effective spool-up time") else maxSpoolTime.
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
            if eng:Stage >= Stage:Number and eng:ignition and not eng:flameout
            {
                sumThr_Del:call(eng).
            }
            else if eng:ignition and eng:flameout
            {
                set engStatusLex[eng:CID] to "FLAMEOUT".
            }
        }

        set avlTWR to max(0.00001, avlThr) / (ves:mass * localGrav).
        set curTWR to max(0.00001, actThr) / (ves:mass * localGrav).
        
        return lex(
             "CURTHRUST", actThr
            ,"AVLTHRUST", avlThr
            ,"PCTTHRUST", round(max(0.000000000000001, actThr) / max(0.00001, avlThr), 5)
            ,"CURTWR", curTWR
            ,"AVLTWR", avlTWR
            ,"TWRSAFE", curTWR > 1.05
            ,"FUELFLOW", fuelFlow
            ,"FUELFLOWMAX", fuelFlowMax
            ,"FLOWPCT", round(max(0.000000000000001, fuelFlow)/ max(0.00001, fuelFlowMax), 5)
            ,"MASSFLOW", massFlow
            ,"MASSFLOWMAX", massFlowMax
            ,"ENGLIST", engList
            ,"SEPSTG", sepFlag
            ,"MAXSPOOLTIME", maxSpoolTime
            ,"ENGSTATUS", engStatusLex
            ,"LASTUPDATE", Round(Time:Seconds, 5)
        ).
    }

    // Given a list of engines, return perf data
    global function GetEngineData
    {
        parameter engList is list(),
                  includeSpecs is true.

        local actThr        to 0.
        local avlThr        to 0.
        local avlTWR        to 0.
        local curTWR        to 0.
        local fuelFlow      to 0.
        local fuelFlowMax   to 0.
        local massFlow      to 0.
        local massFlowMax   to 0.
        local engStatus     to lexicon().
        local engFailReason to "".
        local localGrav     to constant:g * (Ship:Body:Radius / (Ship:Body:Radius + Ship:Altitude))^2.

        local maxSpoolTime  to 0.
        local maxEffSpool   to 0.
        from { local i to 0.} until i = engList:Length step { set i to i + 1.} do
        {
            local eng to engList[i].
            local engMod to eng:GetModule("ModuleEnginesRF").

            set avlThr to avlThr + eng:AvailableThrustAt(Body:Atm:AltitudePressure(Ship:Altitude)).
            set fuelFlowMax to fuelFlowMax + eng:MaxFuelFlow.
            set massFlowMax to massFlowMax + eng:MaxMassFlow.
            set engStatus[eng:CID] to engMod:GetField("Status").
            if includeSpecs 
            { 
                if engMod:HasField("effective spool-up time") 
                {
                    local thisSpool to engMod:GetField("effective spool-up time").
                    local effSpool  to thisSpool.
                    if eng:Tag:MatchesPattern("(HotStg|HotStage)\.\d*")
                    {
                        local engTags to eng:Tag:Split(".").
                        set effSpool to thisSpool + (engTags[1]:ToNumber(0.0000001) / 1000).
                    }
                    
                    set maxSpoolTime to Max(maxSpoolTime, thisSpool).
                    set maxEffSpool to Max(maxEffSpool, effSpool).
                }
            }
            if eng:ignition and not eng:flameout
            {
                // if engMod:GetField("Status") = "Failed" 
                // { 
                    
                //     //set engFailReason to m:GetField("").
                // }
                set actThr to actThr + eng:Thrust. 
                set fuelFlow to fuelFlow + eng:FuelFlow.
                set massFlow to massFlow + eng:MassFlow.
            }
            else if eng:ignition and eng:flameout
            {
                set engStatus[eng:CID] to "FLAMEOUT".
            }
        }.

        set avlTWR to max(0.00001, avlThr) / (Ship:Mass * localGrav).
        set curTWR to max(0.00001, actThr) / (Ship:Mass * localGrav).
        
        return lex(
             "CURTHRUST", actThr
            ,"AVLTHRUST", avlThr
            ,"PCTTHRUST", round(max(0.000000000000001, actThr) / max(0.00001, avlThr), 5)
            ,"CURTWR", curTWR
            ,"AVLTWR", avlTWR
            ,"TWRSAFE", curTWR > 1.05
            ,"FUELFLOW", fuelFlow
            ,"FUELFLOWMAX", fuelFlowMax
            ,"MASSFLOW", massFlow
            ,"MASSFLOWMAX", massFlowMax
            ,"ENGLIST", engList
            ,"ENGSTATUS", engStatus
            ,"STATUSSTR", engFailReason
            ,"MAXSPOOLTIME", maxSpoolTime
            ,"MAXEFFSPOOL", maxEffSpool
            ,"LASTUPDATE", Round(Time:Seconds, 5)
        ).
    }

    // GetActiveEngines :: <none> -> <List>Engines
    // Returns a list of the engines currently active (ignition == true and flameout == false)
    global function GetActiveEngines
    {
        parameter _includeSepMotors is false.

        local engList to list().

        for eng in Ship:Engines
        { 
            if eng:Stage >= Stage:Number and eng:Ignition and not eng:Flameout
            {
                if _includeSepMotors { engList:Add(eng). }
                else if not g_partInfo["Engines"]["SepMotors"]:Contains(eng:Name) or eng:Tag:Replace("sep"):Length > 0 { engList:Add(eng). }
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
                            local stgCondLex to ParseConditionTag(eng:tag, "StgCon").
                            set EngineObj[i]["StgCon"] to lexicon("ACTIVE", True, "CND", stgCondLex["Condition"], "INPUT", stgCondLex["Input"], "THRESH", stgCondLex["Threshold"], "CHKDEL", stgCondLex["CheckDelegate"], "INITDEL", stgCondLex["InitDelegate"]).
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
        set g_ShipLex["Engines"] to g_ShipEngines. 
    }


    // #endregion


    // ArmAutoBoosterSeparation :: <Lexicon>BoosterObject -> (none)
    // Creates a trigger for the boosters to seperate based on resource consumption
    global function ArmAutoBoosterSeparation
    {
        set g_BoosterObj to GetBoosters(ship).
        set g_line to 40.
        if g_BoosterObj:PRESENT
        {
            OutDebug("Arming Booster Sets").
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
                    OutDebug("Staging booster set " + _setIdx).
                    from { local i to 0.} until i = g_BoosterObj["BOOSTER_SETS"][_setIdx]["DC"]["MODULES"]:Length step { set i to i + 1.} do 
                    {
                        local dc to g_BoosterObj["BOOSTER_SETS"][_setIdx]["DC"]["MODULES"][i].
                        if dc:HasEvent("decouple") 
                        {
                            dc:DoEvent("decouple").
                            OutDebug("Staging success").
                        }
                        else
                        {
                            OutDebug("Staging failure - Decouple event not found on part").
                        }
                    }
                    g_BoosterObj["BOOSTER_SETS"]:Remove(_setIdx).
                    if g_BoosterObj["BOOSTER_SETS"]:Keys:Length = 0 
                    {
                        set g_BoosterSepArmed to false.
                    }
                }
                set g_BoosterSepArmed to True.
                OutDebug("Booster Set ({0}) Armed":Format(_setIdx)).
            }
        }
    }


    global function ArmFairingJettison
    {
        parameter _tag.

        local FairingJettisonDelegates to lexicon(
            "launch",   { parameter _alt is 125000. when Ship:Altitude >= _alt then { JettisonFairings("fairing.(Ascent|ASC|Launch)").}}
            ,"reentry", { parameter _alt is 7500.   when Ship:Altitude <= _alt then { JettisonFairings("fairing.(Reentry|RET|Descent|DESC)").}}
        ).

        local fairings to Ship:PartsTaggedPattern("fairing\.{0}":Format(_tag)).
        
        if fairings:Length > 0 
        {
            local fairingTags to fairings[0]:Tag:Split(".").
            local jettisonAlt to fairingTags[fairingTags:Length - 1]:ToNumber(5000).
            local triggerType to choose "Launch" if _tag:MatchesPattern("Ascent|ASC|Launch") else "Reentry".
            local triggerDel  to FairingJettisonDelegates[_tag]@.
            triggerDel:Call(jettisonAlt).
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
            
            set regex               to "booster\.{0}":format(boosterID).
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
                    set stg_lex to ProcessBoosterItem(_item:TypeName, _item, boosterID, stg_lex).
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
    // GetEngineData :: List<Engines> -> Lexicon<engine perf data>
    // Returns a lexicon containing engine performance data
    global function GetEngineData_Old
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
            ,"TimeRemaining", 999999
        ).

        //OutInfo("Engine: {0} ({1})":format(_engList[0]:name, _engList[0]:tag), 1).
        if _engList:Length > 0
        {
            for _eng in _engList
            {
                set _engRes_FuelFlow to _engRes_FuelFlow + _eng:FuelFlow.
                set _engRes_MaxFuelFlow to _engRes_MaxFuelFlow + _eng:MaxFuelFlow.
                set _engRes_MassFlow to _engRes_MassFlow + _eng:MassFlow.
                set _engRes_MaxMassFlow to _engRes_MaxMassFlow + _eng:MaxMassFlow.
                
                if _eng:ConsumedResources:Values:Length > 0
                {
                    from { local _idx to 0.} until _idx >= _eng:consumedResources:values:Length step { set _idx to _idx + 1.} do
                    {
                        local engResources to choose _eng:ConsumedResources if _eng:ConsumedResources:Values:Length > _idx else lexicon().
                        
                        // print "eng: {0}  |  resIDX: [{1}]  | resCount [{2}]":format(_eng:Name, _idx, engResources:Keys:Length) at (2, 25).
                        // print "engResources::" at (2, 26).
                        // print engResources at (2, 27).
                        // breakPoint().
                        local res to engResources:Values[_idx].
                        if not g_ResIgnoreList:Contains(res:name)
                        {
                            //OutInfo("Processing Resource: {0}":format(res:name), 3).
                            set _resObj["Resources"][res:name] to res.
                            set _idx to _idx + 1.
                            set _engRes_SummedAmt to _engRes_SummedAmt + res:amount.
                            set _engRes_SummedCap to _engRes_SummedCap + res:capacity.
                            set _engRes_SummedPct to (_engRes_SummedPct + (max(0.001, res:Amount) / max(0.001, res:capacity))) / (_idx).
                        }
                        else
                        {
                            //OutInfo("Ignoring resource: {0}":format(res:name), 3).
                        }
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
            set _resObj["PctRemaining"] to 100 * Round((max(0.00000000001, _engRes_SummedAmt) - _engRes_ResidualUnits) / _engRes_SummedCap, 5).
            set _resObj["TimeRemaining"] to 2 * min(99999999999999999, max(0.00000001, _engRes_SummedAmt - _engRes_ResidualUnits) / max(0.00000001, _engRes_FuelFlow)).
        }
        else
        {
            OutInfo("No engines in _engList", 1).
        }
        set _resObj["PctRemaining"] to _engRes_SummedPct.
        set _resObj["LastUpdate"] to Round(Time:Seconds, 5).
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

                if g_ActiveEnginesLex:SepStg and Stage:Number > g_StopStage
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
                    LoadNextStagingCondition().
                    set g_ArmAutoStage to True.
                    preserve.
                }
                else
                {
                    OutInfo("STAGE STOP | Current Stage [{0}] | g_stopStage [{1}]":format(stage:number, g_stopStage), 1).
                    LoadNextStagingCondition().
                    set g_ArmAutoStage to False.
                }
            }
        }
    }


    local function LoadNextStagingCondition
    {
        local stgConParts to Ship:PartsTaggedPattern(".*(StgCon\(.*\)).*").
        if stgConParts:Length > 0
        {

        }
    }


    
    // Given a stage number, it will determine if any engines in that stage have engine spool properties
    global function CheckEngineSpool
    {
        parameter engList is list().

        if engList:Length > 0
        {
            local hasSpoolTime to false.
            local maxSpoolTime to 0.0001.

            for _e in ship:engines 
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
            return list(hasSpoolTime, maxSpoolTime).
        }
        else
        {
            return list(false, 0).
        }
    }



    global function AbortSequenceStart
    {
        parameter _abortStr to "GENERAL",
                  _breakFlag to false.

        OutTee("ABORT SEQUENCE INITIATED [{0}]":format(_abortStr), 2).
        if _breakFlag
        {
            Breakpoint().
            print 1 / 0.
        }
    }


    // ArmSpinStaging :: <none> -> <Bool>SpinStaging Enabled / Disabled
    global function ArmSpinStaging_old
    {
        local spinParts to ship:PartsTaggedPattern("(SpinStab|SpinStg|SpinStage)").
        if spinParts:Length > 0
        {
            local spinStgLex to lexicon().
            local nextSpinStg to 99.
            local spinStgKey to 99.

            for p in spinParts
            {
                set spinStgKey to p:DecoupledIn.
                set nextSpinStg to min(nextSpinStg, spinStgKey).

                if spinStgLex:HasKey(spinStgKey)
                {
                    spinStgLex[spinStgKey]["Parts"]:Add(p).
                }
                else
                {
                    set spinStgLex[p:DecoupledIn] to lexicon(
                        "Condition",        ParseConditionTag(p:Tag, "SpinStg")
                        ,"Parts",           list(p)
                        ,"Decoupler",       list()
                        ,"Engines",         list()
                    ).
                }
                if p:TypeName = "Decoupler" 
                {
                    spinStgLex[spinStgKey]["Decoupler"]:Add(p).
                }
                else if p:TypeName = "Engine"
                {
                    spinStgLex[spinStgKey]["Engines"]:Add(p).
                }
            }

            when Stage:Number = nextSpinStg + 1 then
            {
                if spinStgLex:HasKey(nextSpinStg)
                {
                    local spinObj to spinStgLex[nextSpinStg].
                    
                    local baseVal to spinStgLex[nextSpinStg]["Condition"]["InitDelegate"]:Call().
                    local triggerDel to spinStgLex[nextSpinStg]["Condition"]["CheckDelegate"]:Bind(baseVal)@.
                    local useRCS to choose true if spinStgLex[nextSpinStg]["Engines"]:Length = 0 else false.
                    when triggerDel:Call() then
                    {
                        OutMsg("Initiating Spin Stabilization Sequence").
                        local spinStopTS to Time:Seconds + Min(15, g_ConsumedResources["TimeRemaining"]).
                        if useRCS
                        {
                            RCS On.
                            set ship:control:roll to 1.
                            local _stg to Stage:Number.
                            when Time:Seconds >= spinStopTS or Stage:Number < _stg then 
                            { 
                                set ship:control:roll to 0. 
                            }
                        }
                        else
                        {
                            for _eng in spinObj["Engines"]
                            {
                                _eng:Activate.
                            }
                            wait 0.01.
                            spinStgLex:Remove(nextSpinStg).
                            if spinStgLex:Keys:Length > 0
                            {
                                local doneFlag to false.
                                for i in Range(Stage:Number, 0, -1)
                                {
                                    if doneFlag
                                    {
                                    }
                                    else
                                    {
                                        if spinStgLex:Keys:Contains(i) 
                                        {
                                            set nextSpinStg to i.
                                            set doneFlag to true.
                                            preserve.
                                        }
                                    }
                                }
                            }
                        }

                    }
                }
            }
            return true.
        }
        else
        {
            return false.
        }
    }




    global function ArmSpinStabilization
    {
        local _spinList to Ship:PartsTaggedPattern("(SpinStg|SpinStab|SpinStage)").

        local nextSpinStage to -1.
        local spinLeadTime to 15.
        local spinDur to spinLeadTime.
        local spinType to "CTRL".

        local SpinCtrlFactor to 1.

        local _SpinStageLex to lexicon(
            "Active", false
            ,"NextSpinStage", nextSpinStage
            ,"Stages", lexicon()
        ).

        for p in _spinList
        {
            local pDecoupler to choose p if (p:TypeName:MatchesPattern("(Decoupler|Separator)") and p:Decoupler = "None") else p:Decoupler.
            OutInfo("p: {0} | pDecoupler: {1}":Format(p:Name, pDecoupler)).
            // Breakpoint().
            local spinStg to pDecoupler:Stage.
            set nextSpinStage to max(nextSpinStage, spinStg).
            if _SpinStageLex:HasKey(spinStg)
            {
                _SpinStageLex["Stages"][spinStg]["Parts"]:add(p).
            }
            else
            {
                set _SpinStageLex["Stages"][spinStg] to lexicon(
                    "Active",       false
                    ,"StageNum",    spinStg
                    ,"Parts",       list(p)
                    ,"Engines",     list()
                    ,"Decouplers",  list()
                    ,"SpinType",    spinType
                    ,"Condition",   list()
                ).
            }
            if p:TypeName = "Engine"
            {
                set spinType to "ENGINE".
                _SpinStageLex["Stages"][spinStg]["Engines"]:add(p).
            }
            else if p:TypeName = "Decoupler" and p:Decoupler = "None"
            {
                _SpinStageLex["Stages"][spinStg]["Decouplers"]:add(p).
            }
            
            if ship:PartsTaggedPattern("SpinCtrl"):Length > 0
            {
                set spinType to "FLAPS".
            }
            // if p:Tag:MatchesPattern("(SpinStg|SpinStab|SpinStage)\.\d*")
            // {
            //     set spinLeadTime to max(spinLeadTime, 5).
            // }
            set _SpinStageLex["Stages"][spinStg]["SpinType"] to spinType.
            set _SpinStageLex["Stages"][spinStg]["Logic"] to lexicon(
                "CONDITION", "STG"
                ,"INPUT", "TimeRemaining"
                ,"OP", "LT"
                ,"VALUE", spinLeadTime
            ).
        }
        set _SpinStageLex["Next"] to _SpinStageLex["Stages"][nextSpinStage].

        //
        // Triggers start below
        when g_StageLogicTrigger = (nextSpinStage + 1) then
        {
            // if Time:Seconds - g_ActiveEnginesLex:LastUpdate > 0.1
            // {
            //     set g_ActiveEngines to GetActiveEngines().
            //     set g_ActiveEnginesLex to ActiveEngines().
            //     set g_ConsumedResources to GetResourcesFromEngines(g_ActiveEngines).
            // }
            set _SpinStageLex["Next"]["Active"] to True.
            local _NextStgLex to _SpinStageLex["Stages"][nextSpinStage].
            local _NextStgLogic to _NextStgLex["Logic"].

            OutInfo("SpinStaging armed for {0}":Format(nextSpinStage), 2).
            
            local spinDel to "".
            if _NextStgLogic["INPUT"] = "TimeRemaining"
            {
                local getETADel to "".
                if _NextStgLogic["CONDITION"] = "STG"
                {
                    set getETADel to { return g_ConsumedResources["TimeRemaining"].}.
                }
                else if _NextStgLogic["CONDITION"] = "AP"
                {
                    set getETADel to { Return ETA:Apoapsis.}.
                }
                
                set spinDel to StgConDel["ETA"]@. //:Bind(getETADel:Call(), _NextStgLogic["VALUE"])@.
                
                when spinDel:call(getETADel:Call(), _NextStgLogic["VALUE"], _NextStgLogic["OP"]) then
                {
                    OutInfo("Initiating Spin Stabilization", 2).
                    local spinTS to choose spinDur if spinDur > 0 else Time:Seconds + (_NextStgLogic["VALUE"] * 2).
                    local rVal to Ship:Control:Roll.
                    if _NextStgLex["SpinType"] = "RCS"
                    {
                        RCS On.
                        set Ship:Control:Roll to SpinCtrlFactor.
                        when Time:Seconds >= spinTS then
                        {
                            set Ship:Control:Roll to rVal.
                            set v_SpinReady to true.
                        }
                    }
                    else if _NextStgLex["SpinType"] = "CTRL"
                    {
                        set Ship:Control:Roll to SpinCtrlFactor.
                        when Time:Seconds >= spinTS then
                        {
                            set Ship:Control:Roll to rVal.
                            set v_SpinReady to true.
                        }
                    }
                    else if _NextStgLex["SpinType"] = "ENGINE"
                    {
                        local engBurnTime to 1.
                        for eng in _NextStgLex["Engines"]
                        {
                            if not eng:ignition eng:activate.
                        }
                        set spinTS to Time:Seconds + engBurnTime.
                        when Time:Seconds >= spinTS then
                        {
                            set v_SpinReady to true.
                        }
                    }
                    else if _NextStgLex["SpinType"] = "FLAPS"
                    {
                        local flapList to list().
                        for p in ship:partsTaggedPattern("SpinCtrl")
                        {
                            if p:decoupledIn = nextSpinStage
                            {
                                flapList:Add(p:GetModule("FARControllableSurface")).
                            }
                        }

                        wait 0.001.
                        for m in flapList
                        {
                            until m:GetField("Flap Setting") > 1
                            {
                                if DoEvent(m, "Deflect More")
                                {
                                }
                                else
                                {
                                    break.
                                }
                            }
                        }
                        when Time:Seconds >= spinTS then
                        {
                            for m in flapList
                            {
                                until m:GetField("Flap Setting") = 0
                                {
                                    if DoEvent(m, "Deflect Less")
                                    {
                                    }
                                    else
                                    {
                                        break.
                                    }
                                }
                            }
                        }
                    }

                    OutInfo("", 2).
                    _SpinStageLex["Stages"]:Remove(nextSpinStage).
                    if _SpinStageLex["Stages"]:Length > 0
                    {
                        // #TODO: FINISH THE SPINSTAGE STUFFS
                    }
                }
            }
        }
    }



    // ArmHotStaging :: <none> -> <Bool>HotStaging Enabled / Disabled
    // Function that will create triggers for Hot Staging if engines with the 
    // appropriate tags are found
    global function ArmHotStaging
    {
        local _engList to Ship:PartsTaggedPattern("(^HotStg.*$|^HotStage.*$)").
        local _HotStageLex to lexicon().
        local _HotStageEngList to list().
        local nextHotStage to 0.
        
        if _engList:Length > 0
        {
            for eng in _engList
            {
                if _HotStageLex:HasKey(eng:Stage) 
                {
                    _HotStageLex[eng:Stage]:Add(eng).
                }
                else
                {
                    set _HotStageLex[eng:Stage] to list(eng).
                }
                set nextHotStage to Max(nextHotStage, eng:Stage).
            }

            local doneFlag to false.

            set g_StageLogicTrigger to nextHotStage + 1.
            set g_ActiveEngines to GetActiveEngines().
            set g_ActiveEnginesLex to ActiveEngines().
            set g_ConsumedResources to GetResourcesFromEngines(g_ActiveEngines).
            OutInfo("HotStaging Enabled").

            // HotStaging Trigger
            when Stage:Number = g_StageLogicTrigger then
            {
                set g_ActiveEngines to GetActiveEngines().
                set g_ActiveEnginesLex to ActiveEngines().
                set g_ConsumedResources to GetResourcesFromEngines(g_ActiveEngines).
                set _HotStageEngList to _HotStageLex[nextHotStage].
                local g_NextEnginesLex to GetEngineData(_HotStageEngList, true).

                local eff_SpoolTime to Abs(g_NextEnginesLex:MaxEffSpool).

                OutHUD("[HS{0}]: HotStaging armed":Format(nextHotStage)).
                set g_HotStageArmed to True.
                
                // Update the timestamp for hot staging once every second
                when Time:Seconds - g_TS_LastUpdate > 1 then
                {
                    set g_ConsumedResources to GetResourcesFromEngines(g_ActiveEngines).
                    set g_TS to Time:Seconds + (g_ConsumedResources:TimeRemaining - eff_SpoolTime).
                    wait 0.01.
                    GetTermChar().
                    if g_TermChar = Terminal:Input:EndCursor
                    {
                    }
                    else
                    {
                        set g_TS_LastUpdate to Time:Seconds.
                        Preserve.
                    }
                }

                when g_ConsumedResources["TimeRemaining"] <= eff_SpoolTime then
                {
                    OutInfo("HOT STAGING: IGNITION (0%)").
                    for eng in _HotStageEngList
                    {
                        eng:Activate.
                    }
                    set doneFlag to False.
                    set g_TS to 5 + Time:Seconds + eff_SpoolTime.
                    wait 0.01.
                    local engPerf to GetEngineData(_HotStageEngList).
                    until doneFlag
                    {
                        set engPerf to GetEngineData(_HotStageEngList).
                        set g_ActiveEngines to GetActiveEngines().
                        set g_ActiveEnginesLex to ActiveEngines().

                        if engPerf["PCTTHRUST"] >= 0.90 and g_ActiveEnginesLex["PCTTHRUST"] <= 0.01
                        {
                            set doneFlag to True.
                            OutInfo("", 2).
                        }
                        else if Time:Seconds >= g_TS
                        {
                            AbortSequenceStart("IGNITION FAILURE").                            
                        }
                        else
                        {
                            OutInfo("HOT STAGING: IGNITION ({0}%) ":Format(Round(engPerf["PCTTHRUST"] * 100, 1))).
                            OutInfo("ACTIVE THR (%): {0}kn/{1}kn ({2}%)  ":Format(Round(g_ActiveEnginesLex["CURTHRUST"], 2), Round(g_ActiveEnginesLex["AVLTHRUST"], 2), Round(g_ActiveEnginesLex["PCTTHRUST"] * 100, 2)), 2).
                        }
                        DispLaunchTelemetry().
                    }
                    OutInfo("HOT STAGING: STAGING ({0}%)":Format(Round(engPerf["PCTTHRUST"] * 100, 1))).

                    until Stage:Number = nextHotStage
                    {
                        wait until Stage:Ready.
                        Stage.
                        wait 0.025.
                    }

                    _HotStageLex:Remove(nextHotStage).
                    DispClr(10).
                    set g_Line to 10.
                }

                if _HotStageLex:Keys:Length > 0
                {
                    set g_ActiveEngines to GetActiveEngines().
                    set g_ActiveEnginesLex to ActiveEngines().
                    local keyHit to false.
                    from { local i to Stage:Number.} until keyHit or i < 0 step { set i to i - 1.} do 
                    {
                        if _HotStageLex:HasKey(i)
                        {
                            //set maxStage to i.
                            set nextHotStage to i.
                            set g_StageLogicTrigger to Min(Stage:Number, i + 1).
                            set keyHit to true.
                            //OutInfo("HotStaging Preserved", 1).
                            //preserve.
                        }
                    }
                }
                else
                {
                    set g_StageLogicTrigger to -99.
                    set g_HotStageArmed to false.
                    OutInfo("HotStaging Disarmed", 1).
                }
            }
            return true.
        }
        else
        {
            return false.
        }
    }




    // global function CheckHotStageCondition
    // {
        
    //     if hotStageActive
    //     {
    //         rcs on.
    //         set g_ActiveEnginesLex to ActiveEngines().
    //         if Time:Seconds >= g_TS and (g_ActiveEnginesLex["CURTHRUST"] / g_ActiveEnginesLex["AVLTHRUST"]) > 0.925
    //         {
    //             OutInfo("HotStaging: Decoupling").
    //             wait until Stage:Ready.
    //             Stage.
    //             set hotStageActive to false.
    //             set hotStageFlag to false.
    //             set g_TS to 0.
    //         }
    //     } 
    //     else
    //     {
    //         set g_ConsumedResources to GetResourcesFromEngines(GetActiveEngines()).
    //         OutInfo("T-Resource: {0} | T-HotStage: {1}":Format(Round(g_ConsumedResources["TimeRemaining"], 2), Round(g_ConsumedResources["TimeRemaining"] - _spoolTime, 2))).
    //         if g_ConsumedResources["TimeRemaining"] <= _spoolTime
    //         {
    //             OutInfo("HotStaging: Ignition").
    //             wait until Stage:Ready.
    //             Stage. // Hotstage!
    //             set g_TS to Time:Seconds + _spoolTime.
    //             set hotStageActive to true.
    //         }
    //     }
    // }


    local function ParseConditionTag
    {
        parameter _partTag,
                  _queryTag is "".
                  

        if _partTag:MatchesPattern(_queryTag + "\(")
        {
            local StgConStartIdx to _partTag:Find(_queryTag).
            local StgConStrLen   to choose _partTag:FindAt("|", StgConStartIdx + 1) if _partTag:SubString(StgConStartIdx, _partTag:Length - StgConStartIdx):Contains("|") else _partTag:Length.
            local StgCondStr to _partTag:SubString(StgConStartIdx, StgConStrLen).
            local StgCondPrms to StgCondStr:Remove(StgCondStr:Length - 1, 1):Replace("{0}(":Format(_queryTag), "").
            local StgCondList to StgCondPrms:Split(".").

            local _cond       to choose StgCondList[0] if StgCondList:Length > 0 else "ETA".
            local _baseValStr to choose StgCondList[1] if StgCondList:Length > 1 else "NA".
            local _operandStr to choose StgCondList[2] if StgCondList:Length > 2 else "GT".
            local _thresh     to choose StgCondList[3] if StgCondList:Length > 3 else 0.
            
            // if _cond = "ETA"
            // {
            //     if _input = "AP"      { set g_TS to { set g_TS to Time:Seconds + (ETA:Apoapsis - _thresh). } 
            //     else if _input = "PE" { set g_TS to Time:Seconds + (ETA:Periapsis - _thresh).}
            // }

            return lexicon(
                "Condition", _cond
                ,"BaseValue", _baseValStr
                ,"Input", _operandStr
                ,"Threshold", _thresh
                ,"CheckDelegate", StgConDel[_cond]@
                ,"InitDelegate", StgConInit[_cond]@
            ).
        }
        else if _partTag:MatchesPattern(_queryTag + "|.*\..*\..*\..*")
        {

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

        if g_stageInfo["HotStage"]:Keys:Contains(Stage:Number) 
        {
            g_stageInfo["HotStage"]:Remove(Stage:Number). 
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

    local _setDecoupler to "".
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

            set _setDecoupler to item:Decoupler.
        }
        else if item:IsType("Decoupler") or item:IsType("Separator")
        {
            set _setDecoupler to item.
        }
        else
        {
            set _setDecoupler to item:Decoupler.
        }

        // Decoupler parsing
        if _setDecoupler <> "None"
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
//                 "TYPES", UniqueSet(item:name),STageInfo
//                 "UNITS", item:Amount
//             ).
//         }
//     }
//     return obj.
// }



// Idk
global function ManualSpinStabilizationCheck 
{
    if g_TermChar = "q"
    {
        set Ship:Control:Roll to Max(-1, Min(1, Ship:Control:Roll - 0.20)).
        OutInfo("Ship:Control:Roll (-)[{0}]":Format(Round(Ship:Control:Roll, 3))).
        return true.
    }
    else if g_TermChar = "e"
    {
        set Ship:Control:Roll to Max(-1, Min(1, Ship:Control:Roll + 0.20)).
        OutInfo("Ship:Control:Roll (+)[{0}]":Format(Round(Ship:Control:Roll, 3))).
        return true.
    }
    else if g_TermChar = "w"
    {
        set Ship:Control:Roll to 0.
        OutInfo("Ship:Control:Roll (~)[{0}]":Format(Round(Ship:Control:Roll, 3))).
        return false.
    }
}


global function HydrateStageInfoObject
{
    local stgObj to NewStageInfo:Copy().
    
    for p in Ship:PartsTaggedPattern("(SpinStg|SpinStab|SpinStage|HotStg|HotStage|StgCon)")
    {

        if not stgObj["Stages"]:HasKey(p:Stage)
        {
            set stgObj["Stages"][p:Stage] to lexicon("Parts", list(p)).
        }

        if p:TypeName = "Engine"
        {
            if stgObj["Engines"]:HasKey(p:Stage) 
            {
                stgObj["Engines"][p:Stage]["Part"]:Add(p).
                stgObj["Engines"][p:Stage]["ModuleEnginesRF"]:Add(p:GetModule("ModuleEnginesRF")).
            }
            else
            {
                set stgObj["Engines"][p:Stage] to lexicon(
                    "Part", list(p)
                    ,"ModuleEnginesRF", list(p:GetModule("ModuleEnginesRF"))
                ).
            }
        }
        else if p:TypeName = "Decoupler"
        {
            if stgObj["Decouplers"]:HasKey(p:Stage) 
            {
                stgObj["Decouplers"][p:Stage]["Part"]:Add(p).
                
                local dcMod to "".

                if p:HasModule("ModuleDecouple")
                {
                    set dcMod to p:GetModule("ModuleDecouple").
                }
                else if p:HasModule("ModuleAnchoredDecoupler")
                {
                    set dcMod to p:GetModule("ModuleAnchoredDecoupler").
                }

                if dcMod:TypeName = "String"
                {
                }
                else
                {
                    if stgObj["Decouplers"][p:Stage]:HasKey(dcMod:Name)
                    {
                        stgObj["Decouplers"][p:Stage][dcMod:Name]:Add(dcMod).
                    }
                    else
                    {
                        set stgObj["Decouplers"][p:Stage][dcMod:Name] to list(dcMod).
                    }
                }
            }
            else
            {
                set stgObj["Decouplers"][p:Stage] to lexicon(
                    "Part", list(p)
                    ,"ModuleDecouplersRF", list(p:GetModule("ModuleDecouplersRF"))
                ).
                if p:HasModule("ModuleAnchoredDecoupler")
                {
                    if stgObj["Decouplers"][p:Stage]:HasKey("ModuleAnchoredDecoupler")
                    {
                        stgObj["Decouplers"][p:Stage]["ModuleAnchoredDecoupler"]:Add(p:GetModule("ModuleAnchoredDecoupler")).
                    }
                    else
                    {
                        set stgObj["Decouplers"][p:Stage]["ModuleAnchoredDecoupler"] to list(p:GetModule("ModuleAnchoredDecoupler")).
                    }
                }
            }
        }

        if p:Tag:MatchesPattern("(SpinStg|SpinStab|SpinStage)")
        {
            local spinCondition to choose ParseConditionTag(p:Tag, "SpinStg") if p:Tag:MatchesPattern("SpinStg") 
                else choose ParseConditionTag(p:Tag, "SpinStab") if p:Tag:MatchesPattern("SpinStab") 
                else choose ParseConditionTag(p:Tag, "SpinStage") if p:Tag:MatchesPattern("SpinStage")
                else "".

            if stgObj["SpinStg"]:HasKey(p:Stage)
            {
                stgObj["SpinStg"][p:Stage]["Parts"]:Add(p).
            }
            else
            {
                set stgObj["SpinStg"][p:Stage] to lexicon(
                    "Parts",        list(p)
                    ,"Engines",     list()
                    ,"Decouplers",  list()
                    ,"Condition",   spinCondition
                ).
            }

            if p:TypeName = "Engine" 
            {
                stgObj["SpinStg"][p:Stage]["Engines"]:Add(p).
            }
            else if p:TypeName = "Decoupler"
            {
                stgObj["SpinStg"][p:Stage]["Decouplers"]:Add(p).
            }

            set stgObj["Conditions"][p:Stage] to spinCondition.
        }
        if p:Tag:MatchesPattern("StgCon")
        {
            set stgObj["Conditions"][p:Stage] to ParseConditionTag(p:Tag, "StgCon").
        }

    }
    set g_StageInfo to stgObj.
    // from { local iStg to g_StartStage. } until iStg < 0 step { set iStg to iStg - 1. }  do
    // {
        
    // }
}






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