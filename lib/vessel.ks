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
        
        return lex("CURTHRUST", actThr, "AVLTHRUST", avlThr, "CURTWR", curTWR, "AVLTWR", avlTWR, "ENGLIST", engList, "SEPSTG", sepFlag).
    }

    // ArmAutoBoosterSeparation :: <Lexicon>BoosterObject -> (none)
    // Creates a trigger for the boosters to seperate based on resource consumption
    global function ArmAutoBoosterSeparation
    {
        parameter _boosterObj is GetBoosters(ship).

        if _boosterObj:PRESENT
        {
            for _stgIdx in _boosterObj["STAGES"]:Keys
            {   
                // print "_boosterObj['STAGES']: {0}":format(_boosterObj:hasKey("STAGES")) at (2, 45).
                // if _boosterObj:hasKey("STAGES") 
                // {
                //     print "_boosterObj['STAGES'][{0}]: {1}":format(_stgIdx, _boosterObj["STAGES"]:hasKey(_stgIdx)) at (2, 46).
                //     if _boosterObj["STAGES"]:hasKey(_stgIdx)
                //     {
                //         print "_boosterObj['STAGES'][{0}][{1}]: {2}":format(_stgIdx, "DC", _boosterObj["STAGES"][_stgIdx]:hasKey("DC")) at (2, 47).
                //         if _boosterObj["STAGES"][_stgIdx]:hasKey("DC")
                //         {
                //             print "_boosterObj['STAGES'][{0}][{1}][{2}]: {3}":format(_stgIdx, "DC", _boosterObj["STAGES"][_stgIdx]["DC"]:hasKey("MODULES")) at (2, 48).
                //         }
                //     }
                // }
                // Breakpoint().

                // if _boosterObj["STAGES"]:hasKey(_stgIdx)
                // {
                //     print "_boosterObj['STAGES'][{0}][{1}]: {2}":format(_stgIdx, "RES", _boosterObj["STAGES"][_stgIdx]:hasKey("RES")) at (2, 50).
                //     if _boosterObj["STAGES"][_stgIdx]:hasKey("RES")
                //     {
                        
                //         print "_boosterObj['STAGES'][{0}][{1}][{2}]: {3}":format(_stgIdx, "RES", "MASS", _boosterObj["STAGES"][_stgIdx]["RES"]:HasKey("MASS")) at (2, 51).
                //         print "_boosterObj['STAGES'][{0}][{1}][{2}]: {3}":format(_stgIdx, "RES", "PARTLISTS", _boosterObj["STAGES"][_stgIdx]["RES"]:HasKey("PARTLISTS")) at (2, 52).
                //         print "_boosterObj['STAGES'][{0}][{1}][{2}]: {3}":format(_stgIdx, "RES", "PCT", _boosterObj["STAGES"][_stgIdx]["RES"]:HasKey("PCT")) at (2, 53).
                //         print "_boosterObj['STAGES'][{0}][{1}][{2}]: {3}":format(_stgIdx, "RES", "TYPES", _boosterObj["STAGES"][_stgIdx]["RES"]:HasKey("TYPES")) at (2, 54).
                //         print "_boosterObj['STAGES'][{0}][{1}][{2}]: {3}":format(_stgIdx, "RES", "UNITS", _boosterObj["STAGES"][_stgIdx]["RES"]:HasKey("UNITS")) at (2, 55).
                //     }
                // }
                // Breakpoint().

                when (_boosterObj["STAGES"][_stgIdx]["RES"]["PCT"] <= 0.01) or (Ship:Status <> "PRELAUNCH" and (_boosterObj["STAGES"][_stgIdx]["ENG"]["AVLTHRUST"] <= 0.01)) then
                {
                    for dc in _boosterObj["STAGES"][_stgIdx]["DC"]["MODULES"]
                    {
                        if dc:HasEvent("decouple") dc:DoEvent("decouple").
                    }
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
        local boosterID     to "".
        local stg_lex        to lexicon().
        local i             to 0.
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
            "STAGES", lexicon()
        ).

        for b in _ves:PartsTaggedPattern("booster.\d+")
        {
            set boosterID           to b:tag:replace("booster.","").
            set i                   to boosterID:toNumber(0).
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

            uniqueBoosterID:add(boosterID).
            if b_lex:HasKey(boosterID)
            {
                set stg_lex to b_lex["STAGES"][boosterID].
            }
            else
            {
                set stg_lex to lexicon(
                    "DC", lexicon(
                        "PARTLIST", list(),
                        "MODULES", list()   
                    ),
                    "ENG", lex(
                        "AVLTHRUST", stgBoosterThr,
                        "PARTLIST", list()
                    ),
                    "PARTLIST", list(b),
                    "RES", lex(
                        "PCT", stgResPct,
                        "MASS", stgResMass,
                        "TYPES", stgResSet,
                        "UNITS", stgResUnits,
                        "PARTLIST", list()
                    )
                ).
            }

            // from { local i to 0.} until i = uniqueBoosterID:length step { set i to i + 1.} do
            // {
            for b in stgBoosters
            {
                if b:IsType("Decoupler")
                {
                    set stg_lex to ProcessBoosterItem(b:TypeName, b, boosterID, stg_lex).
                }
                else
                {
                    set stg_lex to ProcessBoosterItem(b:TypeName, b:decoupler, boosterID, stg_lex).
                }


                // else if b:IsType("Engine")
                // {
                //     set stg_lex to ProcessBoosterItem(b:TypeName, b, boosterID, stg_lex).
                // }
                // set stg_lex to ProcessBoosterItem(b:TypeName, b, boosterID, stg_lex).
                // else
                // {
                    // set stg_lex["ENG"] to ProcessBoosterItem("ENGINE", b, stg_lex).
                    // if stg_lex["ENG"]:length = 0
                    // {
                    //     set stg_lex["ENG"] to GetEnginesInTree(b:decoupler).
                    // }
                    // else
                    // {
                    //     local engTree to GetEnginesInTree(b:decoupler).
                    //     if engTree:length > 0 
                    //     {
                    //         for eng in engTree
                    //         {
                    //             stg_lex["ENG"]:add(eng).
                    //         }
                    //     }
                    // }
                // }
            }
            set b_lex["STAGES"][boosterID] to stg_lex.
        }
        return b_lex.
    }

    // TODO Write Engine Perf Module
    // GetEnginePerfData :: List<Engines> -> Lexicon<engine perf data>
    // Returns a lexicon containing engine performance data
    global function GetEnginePerfData
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
            if stage:number >= g_stopStage
            {
                OutMsg("Staging...").
                SafeStage().
                wait 0.10.

                if g_activeEngines:SepStg
                {
                    OutInfo("Sep motors activated, priming stage engines").
                    wait 0.50.
                    wait until stage:ready.
                    stage.
                }

                OutInfo("Engine ignition sequence initiated...").
                local ts_stg to time:seconds + 2.5.
                wait until time:seconds >= ts_stg or g_activeEngines["CURTHRUST"] > 0.01.
                
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

local function ProcessBoosterItemResource
{
    parameter   item is "",
                obj is lexicon().

    local _stgResMass        to 0.
    local _stgResPct         to 0.
    local _stgResUnits       to 0.

    if obj:HasKey("RES") 
    {
            if obj["RES"]:HasKey("PARTLIST")
            {
               obj["RES"]["PARTLIST"]:Add(item). 
            }
            else
            {
                set obj["RES"]["PARTLIST"] to list(item).
            }

            if obj["RES"]:HasKey("TYPES")
            {
                obj["RES"]["TYPES"]:Add(item:name).
            }
            else
            {
                set obj["RES"]["TYPES"] to uniqueSet(item:name).
            }

            set obj["RES"]["MASS"]  to _stgResMass + (item:amount * item:density).
            set obj["RES"]["PCT"]   to (_stgResPct + (item:amount / item:capacity)) / obj["RES"]["PARTLIST"]:length.
            set obj["RES"]["UNITS"] to _stgResUnits + item:amount.
    }
    else
    {
        set obj["RES"] to lexicon(
            "PARTLIST", list(item),
            "MASS", item:amount * item:density,
            "PARTLIST", list(),
            "PCT", item:amount / item:capacity,
            "TYPES", uniqueSet(item:name),
            "UNITS", item:amount
        ).
    }
    return obj.
}

// Local Functions
local function ProcessBoosterItem
{
    parameter   type is "",
                item is "",
                bID is "",
                obj is lexicon().

    local _stgBoosterThr     to 0.
    local _stgResMass        to 0.
    local _stgResPct         to 0.
    local _stgResUnits       to 0.
   
    if item:IsType("PART")
    {
        if item:IsType("ENGINE")
        {
            set _stgBoosterThr to _stgBoosterThr + item:AVAILABLETHRUSTAT(Body:Atm:AltitudePressure(Ship:Altitude)).
            if obj:HasKey("ENG")
            {
                if obj["ENG"]:hasKey("AVLTHRUST") {
                    print "ENG/AVLTHRUST: true" at (2, 55).
                    set obj["ENG"]["AVLTHRUST"] to _stgBoosterThr.
                }
                if obj["ENG"]:HasKey("PARTLIST") obj["ENG"]["PARTLIST"]:add(item).
            }
            else
            {
                set obj["ENG"] to lexicon(
                    "AVLTHRUST", _stgBoosterThr
                ).
            }
        }
        else if type = "DECOUPLER" or type = "SEPARATOR"
        {
            if item:hasModule("ModuleDecouple") 
            {
                if obj:HasKey("DC")
                {
                    obj["DC"]["PARTLIST"]:add(item).
                    obj["DC"]["MODULES"]:add(item:GetModule("ModuleDecouple")).
                }
                else
                {
                    set obj["DC"] to lexicon(
                        "PARTLIST", list(),
                        "MODULES", list()
                    ).
                }
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
                    "PARTLIST", list(),
                    "MASS", 0,
                    "PARTLIST", list(),
                    "PCT", 0,
                    "TYPES", uniqueSet(),
                    "UNITS", 0
                ).
            }

            for _i_res in item:Resources
            {
                if obj["RES"]:HasKey("RES_PARTS")
                {
                    if obj["RES"]["RES_PARTS"]:hasKey(_i_res:name)
                    {
                        obj["RES"]["PARTS_BY_RES"][_i_res:name]:add(item:cid).
                    }
                    else
                    {
                        set obj["RES"]["PARTS_BY_RES"][_i_res:name] to list(item:cid).
                    }
                }
                set obj to ProcessBoosterItemResource(_i_res, obj).
            }
        }

        set obj to ProcessBoosterItemChildren(item, bID, obj).
    }
    else if item:IsType("RESOURCE")
    {
        if obj:HasKey("RES") 
        {
                obj["RES"]["PARTLIST"]:Add(item).
                obj["RES"]["TYPES"]:Add(item:name).
            set obj["RES"]["MASS"]  to _stgResMass + (item:amount * item:density).
            set obj["RES"]["PCT"]   to (_stgResPct + (item:amount / item:capacity)) / obj["RES"]["PARTLIST"]:length.
            set obj["RES"]["UNITS"] to _stgResUnits + item:amount.
        }
        else
        {
            set obj["RES"] to lexicon(
                "PARTLIST", list(item),
                "MASS", item:amount * item:density,
                "PARTLIST", list(),
                "PCT", item:amount / item:capacity,
                "TYPES", uniqueSet(item:name),
                "UNITS", item:amount
            ).
        }
    }
    return obj.
}

// Local Functions
local function ProcessBoosterItem2
{
    parameter   type is "",
                item is "",
                bID is "",
                obj is lexicon().

    local del_stgBoosterItem to ProcessBoosterItem@. // For recursion maybe?

    local _stgBoosterThr     to 0.
    local _stgResMass        to 0.
    local _stgResPct         to 0.
    local _stgResUnits       to 0.
   
    if item:IsType("PART")
    {
        if item:IsType("ENGINE")
        {
            set _stgBoosterThr to _stgBoosterThr + item:AVAILABLETHRUST.
            if obj:HasKey("ENG")
            {
                print "_stgBoosterThr: {0}":format(_stgBoosterThr) at (2, 40).
                print "item: {0}":format(item) at (2, 41).
                print "item:THRUST: {0}":format(item:AvailableThrust) at (2, 42).
                if obj["ENG"]:hasKey("AVLTHRUST") {
                    print "ENG/AVLTHRUST: true" at (2, 55).
                    set obj["ENG"]["AVLTHRUST"] to _stgBoosterThr.
                }
                if obj["ENG"]:HasKey("PARTLIST") obj["ENG"]["PARTLIST"]:add(item).
                Breakpoint().
            }
            else
            {
                set obj["ENG"] to lexicon(
                    "AVLTHRUST", _stgBoosterThr
                ).
            }
        }
        else if type = "DECOUPLER" or type = "SEPARATOR"
        {
            if item:hasModule("ModuleDecouple") 
            {
                if obj:HasKey("DC")
                {
                    obj["DC"]["PARTLIST"]:add(item).
                    obj["DC"]["MODULES"]:add(item:GetModule("ModuleDecouple")).
                }
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
                    "PARTLIST", list(),
                    "MASS", 0,
                    "PARTLIST", list(),
                    "PCT", 0,
                    "TYPES", uniqueSet(),
                    "UNITS", 0
                ).
            }

            for _i_res in item:Resources
            {
                if obj["RES"]:HasKey("RES_PARTS")
                {
                    if obj["RES"]["RES_PARTS"]:hasKey(_i_res:name)
                    {
                        obj["RES"]["PARTS_BY_RES"][_i_res:name]:add(item:cid).
                    }
                    else
                    {
                        set obj["RES"]["PARTS_BY_RES"][_i_res:name] to list(item:cid).
                    }
                }
                set obj to del_stgBoosterItem:call("RESOURCE", _i_res, bID, obj).
            }
        }

        set obj to ProcessBoosterItemChildren(item, bID, obj).
    }
    else if item:IsType("RESOURCE")
    {
        if obj:HasKey("RES") 
        {
                obj["RES"]["PARTLIST"]:Add(item).
                obj["RES"]["TYPES"]:Add(item:name).
            set obj["RES"]["MASS"]  to _stgResMass + (item:amount * item:density).
            set obj["RES"]["PCT"]   to (_stgResPct + (item:amount / item:capacity)) / obj["RES"]["PARTLIST"]:length.
            set obj["RES"]["UNITS"] to _stgResUnits + item:amount.
        }
        else
        {
            set obj["RES"] to lexicon(
                "PARTLIST", list(item),
                "MASS", item:amount * item:density,
                "PARTLIST", list(),
                "PCT", item:amount / item:capacity,
                "TYPES", uniqueSet(item:name),
                "UNITS", item:amount
            ).
        }
    }
    return obj.
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
    if _p0:IsType("engine") _engList:add(_p0).

    local _p0Children to _p0:children.
    for _p1 in _p0Children
    {
        _engDel:call(_p1).
    }
    return _engList.
}