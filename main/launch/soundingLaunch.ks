@LazyGlobal off.
ClearScreen.

parameter params to list().

RunOncePath("0:/lib/libLoader.ks").
RunOncePath("0:/lib/launch.ks").

DispMain().

local cb                 to Ship:Engines[0]. // Initialized to any old engine for now
local curBoosterTag      to "".
local fairingJetAlt      to 100000.
local RCSAlt             to 32500.

local FairingsArmed      to false.
local RCSArmed           to false.
local RCSPresent         to Ship:ModulesNamed("ModuleRCSFX"):Length > 0.
local HotStagePresent    to Ship:PartsTaggedPattern("(HotStage|HotStg|HS)"):Length > 0.
local stagingCheckResult to 0.
local steeringDelegate   to { return ship:facing.}.
local ThrustThresh       to 0.

// Parameter default values.
local _tgtAlt        to 100.
local _tgtInc        to 0.
local _azObj         to list().

if params:length > 0
{
    set _tgtAlt to params[0].
    if params:length > 1 set _tgtInc to params[1].
    if params:length > 2 set _azObj to params[2].
}


wait until Ship:Unpacked.
local towerHeight to (Ship:Bounds:Size:Mag + 100).

// Set the steering delegate
if _azObj:Length = 0 and g_GuidedAscentMissions:Contains(g_MissionTag:Mission)
{
    set _azObj to l_az_calc_init(_tgtAlt, _tgtInc).
}

set g_azData to _azObj.
set g_LoopDelegates["Steering"] to GetAscentSteeringDelegate(_tgtAlt, _tgtInc, _azObj).

local timeStampSpan to TimeSpan(TIME:SECONDS).
if timeStampSpan:HOUR > 12 and timeStampSpan:HOUR <= 23
{
    LIGHTS off.
    wait 0.25.
    LIGHTS off.
}
else
{
    LIGHTS on.
}

if RCSPresent
{
    local rcsCheckDel to { parameter _params to list(). if _params:length = 0 { set _params to list(0.001, 5).} return Ship:Body:ATM:AltitudePressure(Ship:Altitude) <= _params[0] or g_ActiveEngines_Data:BurnTimeRemaining <= _params[1].}.
    local rcsActionDel to { parameter _params is list(). RCS on. return false.}.
    local rcsEventData to CreateLoopEvent("RCSEnable", "RCS", list(0.0025, 3), rcsCheckDel@, rcsActionDel@).
    set RCSArmed to RegisterLoopEvent(rcsEventData).
    OutInfo("Exiting RCSPresent block with result: {0}":Format(RCSArmed)).
}

Breakpoint(Terminal:Input:Enter, "*** Press ENTER to launch ***").
ClearScreen.
// DispTermGrid().
DispMain(ScriptPath()).
OutMsg("Launch initiated!").

set FairingsArmed to ArmFairingJettison("ascent").
OutInfo("ArmFairingJettison() result: {0}":Format(FairingsArmed)).
// if fairingsArmed
// {
//     set fairingJetAlt to g_LoopDelegates:Events:Fairings:Params[1].
// }


lock Throttle to 1.
wait 0.25.
LaunchCountdown().
OutInfo().
OutInfo("",1).

set g_ActiveEngines to GetEnginesForStage(Stage:Number).
set g_NextEngines   to GetNextEngines().

// Check if we have any special MECO engines to handle
local MECO_Engines to Ship:PartsTaggedPattern("MECO\|ascent").
if MECO_Engines:Length > 0
{
    // SetupMECOEvent(Ship:PartsTaggedPattern("MECO\|ascent")).
    local MECO_EngineID_List to list().
    for p in MECO_Engines 
    { 
        MECO_EngineID_List:Add(p:CID).
    }

    local MECO_Time to MECO_Engines[0]:Tag:Replace("MECO|ascent|",""):ToNumber(-1).
    global MECO_Action_Counter to 0.
    if MECO_Time >= 0 
    {
        local checkDel to { parameter _params is list(). OutDebug("MECO Check"). return MissionTime >= _params[1].}.
        local actionDel to 
        { 
            parameter _params is list(). 
            
            set MECO_Action_Counter to MECO_Action_Counter + 1. 
            OutDebug("MECO Action ({0}) ":Format(MECO_Action_Counter)). 
            
            local engIDList to _params[0].

            from { local i to 0.} until i = g_ActiveEngines:Length or engIDList:Length = 0 step { set i to i + 1.} do
            {
                local eng to g_ActiveEngines[i].
                
                if engIDList:Contains(eng:CID)
                {
                    if eng:ignition and not eng:flameout
                    {
                        eng:shutdown.
                        if eng:HasGimbal 
                        {
                            DoAction(eng:Gimbal, "Lock Gimbal", true).
                        }
                        engIDList:Remove(engIDList:Find(eng:CID)).
                    }
                }
            }
            wait 0.01. 
            return false.
        }.
            
        local MECO_Event to CreateLoopEvent("MECO", "EngineCutoff", list(MECO_EngineID_List, MECO_Time), checkDel@, actionDel@).
        if RegisterLoopEvent(MECO_Event)
        {
            OutDebug("MECO Handler Created").
        }
    }
}
// local AutoStageResult to ArmAutoStaging().
ArmAutoStaging().

// Arm hot staging if present
set g_HotStagingArmed to ArmHotStaging().

// if AutoStageResult = 1
// {
//     set stagingDelegateCheck  to g_LoopDelegates:Staging["Check"].
//     set stagingDelegateAction to g_LoopDelegates:Staging["Action"].
// }

set g_BoostersArmed to ArmBoosterStaging().

set s_Val to Ship:Facing.
lock steering to s_Val.

OutMsg().
OutInfo().
OutInfo("", 1).

OutMsg("Liftoff! ").
wait 1.
OutMsg("Vertical Ascent").
until Alt:Radar >= towerHeight
{
    set g_ActiveEngines to GetActiveEngines().
    set g_ActiveEngines_Data to GetEnginesPerformanceData(GetActiveEngines()).
    if g_BoostersArmed   { CheckBoosterStageCondition().}
    if g_LoopDelegates:HasKey("Staging")
    {
        if g_HotStagingArmed 
        { 
            if g_LoopDelegates:Staging:HotStaging:HasKey(STAGE:NUMBER - 1)
            {
                if g_LoopDelegates:Staging:HotStaging[STAGE:NUMBER - 1]:HasKey("Check")
                {
                    if g_LoopDelegates:Staging:HotStaging[STAGE:NUMBER - 1]:Check:CALL()
                    {
                        g_LoopDelegates:Staging:HotStaging[STAGE:NUMBER - 1]:Action:CALL().
                    }
                }
            }
        }
        else
        {
            set stagingCheckResult to g_LoopDelegates:Staging:Check:Call().
            if stagingCheckResult = 1
            {
                g_LoopDelegates:Staging["Action"]:Call().
            }
        }
    }

    DispLaunchTelemetry().
    // DispEngineTelemetry().
}

OutMsg("Gravity Turn").
until Stage:Number <= g_StageLimit
{
    set g_ActiveEngines to GetActiveEngines().
    set g_ActiveEngines_Data to GetEnginesPerformanceData(GetActiveEngines()).
    if g_BoostersArmed { CheckBoosterStageCondition().}
    if g_LoopDelegates:HasKey("Staging")
    {
        if g_HotStagingArmed 
        { 
            local doneFlag to false.
            from { local i to Stage:Number - 1.} until i = 0 or doneFlag step { set i to i - 1.} do
            {
                if g_LoopDelegates:Staging:HotStaging:HasKey(i)
                {
                    if g_LoopDelegates:Staging:HotStaging[i]:Check:CALL()
                    {
                        g_LoopDelegates:Staging:HotStaging[i]:Action:CALL().
                    }
                    set doneFlag to true.
                }
            }
        }
        else
        {
            set stagingCheckResult to g_LoopDelegates:Staging:Check:Call().
            if stagingCheckResult = 1
            {
                g_LoopDelegates:Staging["Action"]:Call().
            }
        }
    }
    
    // if fairingsArmed
    // {
    //     if Ship:Altitude >= fairingJetAlt
    //     {
    //         if g_LoopDelegates:Events:HasKey("Fairings")
    //         {
    //             if g_LoopDelegates:Events:Fairings:HasKey("Check")
    //             {
    //                 g_LoopDelegates:Events:Fairings:Check:Call().
    //             }
    //             else
    //             {
    //                 JettisonFairings(Ship:PartsTaggedPattern("fairing|ascent")).
    //             }
    //         }
    //         set fairingsArmed to g_LoopDelegates:Events:HasKey("fairing").
    //     }
    // }
    if RCSPresent
    {
        if Ship:Body:ATM:AltitudePressure(Ship:Altitude) <= 0.001 or g_ActiveEngines_Data:BurnTimeRemaining <= 5
        {
            RCS on.
            set RCSPresent to False.
        }
    }
    
    if g_LoopDelegates["Events"]:Keys:Length > 0 
    {
        ExecGLoopEvents().
    }

    set s_Val to g_LoopDelegates:Steering:Call().
    DispLaunchTelemetry().
    // DispEngineTelemetry().
    wait 0.01.
}

// set g_ActiveEngines_Data to GetEnginesPerformanceData(GetActiveEngines()).
// until g_ActiveEngines_Data:Thrust >= 0.2
// {
//     if g_BoostersArmed { CheckBoosterStageCondition().}
//     set g_ActiveEngines_Data to GetEnginesPerformanceData(GetActiveEngines()).

//     if fairingsArmed
//     {
//         if Ship:Altitude >= fairingJetAlt
//         {
//             g_LoopDelegates:Events["fairing"]:Delegate:Call().
//             set fairingsArmed to g_LoopDelegates:Events:HasKey("fairing").
//         }
//     }

//     DispLaunchTelemetry().
//     // DispEngineTelemetry().
//     wait 0.01.
// }

DisableAutoStaging().

OutMsg("Final Burn").
set g_ActiveEngines_Data to GetEnginesPerformanceData(GetActiveEngines()).
wait 0.25.
until g_ActiveEngines_Data:Thrust <= 0.25 // until Ship:AvailableThrust <= 0.01
{
    set s_Val to g_LoopDelegates:Steering:Call().
    set g_ActiveEngines_Data to GetEnginesPerformanceData(GetActiveEngines()).

    // if fairingsArmed
    // {
    //     g_LoopDelegates:Events["Fairings"]:Check:Call().
    //     set fairingsArmed to g_LoopDelegates:Events:HasKey("fairing").
    // }

    if g_LoopDelegates["Events"]:Keys:Length > 0 
    {
        ExecGLoopEvents().
    }

    DispLaunchTelemetry().
    // DispEngineTelemetry().
    wait 0.01.
}
ClearDispBlock("ENGINE_TELEMETRY").


OutMsg("Coasting out of atmosphere").
Until Ship:Altitude >= Body:ATM:Height
{
    set s_Val to Ship:Prograde.
    DispLaunchTelemetry().
    wait 0.01.
}

if g_StageLimitSet:Length > 0
{
    set core:tag to SetNextStageLimit(core:tag).
}

OutMsg("Launch script complete, performing exit actions").
wait 1.
ClearScreen.



// Test Functions
local function ArmBoosterStaging
{
    set g_BoosterObj to lexicon().

    local BoosterParts to Ship:PartsTaggedPattern("(^booster)+(\|\.)+(\d*)+").

    local setIdxList to UniqueSet().
    if BoosterParts:Length > 0
    {
        for p in BoosterParts
        {
            local setIdx to p:Tag:Replace("booster",""):Replace("|",""):Replace("as",""):ToNumber(0).
            set g_BoosterObj[setIdx] to ProcessBoosterTree(p, setIdx, g_BoosterObj).
            if setIdxList:Contains(setIdx)
            {
            }
            else 
            {
                setIdxList:Add(setIdx).
            }
        }
        set g_BoostersArmed to true.
    }
    else 
    {
        set g_BoostersArmed to false.
    }
    return g_BoostersArmed.
}


local function GetBoosterUpdateDel
{
    parameter _dc is Core:Part.

    local updateDel to { return g_BoosterObj.}.
    if not (_dc = Core:Part)
    {
        OutInfo("_dc: {0}":Format(_dc:name)).
        set updateDel to
        { 
            local setIdx to _dc:Tag:Replace("booster",""):Replace("|",""):Replace("as",""):ToNumber(0).
            if g_BoosterObj:HasKey(setIdx)
            { 
                if g_BoosterObj[setIdx]:HasKey("ENG") 
                {
                    set g_BoosterObj[setIdx]["ENG"]:ALLTHRUST to 0.
                }
            }
            set g_BoosterObj to ProcessBoosterTree(_dc, setIdx, g_BoosterObj).
            return g_BoosterObj.
        }.
    }
    else
    {
        OutInfo("_dc in GetBoosterUpdateDel is core:part!").
    }
    return updateDel@.
}

local function ProcessBoosterTree
{
    parameter _p,
              _setIdx,
              _boosterObj.

    local dc to choose _p if _p:IsType("Decoupler") else _p:Decoupler.
    local m to choose dc:GetModule("ModuleAnchoredDecoupler") if dc:HasModule("ModuleAnchoredDecoupler") else dc:GetModule("ModuleDecouple").
    local event to "".

    for _e in m:AllEvents
    {
        if _e:MatchesPattern("\(callable\).*decouple.*is KSPEvent")
        {
            set event to _e:Replace("(callable) ",""):Replace(", is KSPEvent","").
        }
    }
    
    // This resets the lex for each loop
    if not _boosterObj:HasKey(_setIdx)
    {
        set _boosterObj[_setIdx] to lexicon(
            "DC", lex(
                dc:UID, lex(
                    "P", dc
                    ,"M", m
                    ,"E", event
                    ,"S", dc:Stage
                )
            )
            ,"UPDATE", GetBoosterUpdateDel(dc)
        ).
    }
    else
    {
        if not _boosterObj[_setIdx]:HasKey("DC")
        {
            set _boosterObj[_setIdx]["DC"] to lexicon().
        }
        
        set _boosterObj[_setIdx]["DC"][dc:UID] to lexicon(
            "P", dc
            ,"M", m
            ,"E", event
            ,"S", dc:Stage
        ).

        if not _boosterObj[_setIdx]:HasKey("UPDATE")
        {
            set _boosterObj[_setIdx]["UPDATE"] to GetBoosterUpdateDel(dc).
        }
    }
    
    // Check to see if we need to airstart this booster set
    local as to false.
    if _p:Tag:Split("|"):Length > 2
    {
        if _p:Tag:Split("|")[1] = "as"
        {
            set as to true.
        }
    } 
    else if _p:Tag:Split("."):Length > 2
    {
        if _p:Tag:Split(".")[1] = "as" 
        {
            set as to true.
        }
    }
    set _boosterObj[_setIdx]["AS"] to as.


    for child in dc:Children
    {
        set _boosterObj to ProcessBoosterChildren(child, _setIdx, _boosterObj).
    }
    // if _boosterObj[setIdx]["RES"]:HasSuffix("AMOUNT")
    // {
    //     set _boosterObj[setIdx]["RES"]["PCTLEFT"] to Round(_boosterObj[setIdx]["RES"]:AMOUNT / _boosterObj[setIdx]["RES"]:CAPACITY, 5).
    // }
    // else
    // {
    //     set _boosterObj[setIdx]["RES"]["PCTLEFT"] to 1.
    // }

    return _boosterObj.
}

local function ProcessBoosterChildren
{
    parameter _p,
              _setIdx,
              _boosterObj.

    // OutInfo("Processing Child for (Set): [{0}] ({1})":Format(_p:Name, _setIdx), 1).

    local _bcObj to _boosterObj.
    if not _p:HasModule("ProceduralFairingDecoupler")
    {
        if _p:IsType("Engine")
        {
            set _bcObj to ProcessBoosterEngine(_p, _setIdx, _bcObj).
        }
        else if _p:HasModule("ModuleFuelTank")
        {
            set _bcObj to ProcessBoosterTank(_p, _setIdx, _bcObj).
        }
        
        if _p:Children:Length > 0
        {
            for _child in _p:Children
            {
                set _bcObj to ProcessBoosterChildren(_child, _setIdx, _bcObj).
            }
        }
    }
    
    return _bcObj.
}

local function ProcessBoosterEngine
{
    parameter _p,
              _setIdx,
              _boosterObj.

    // OutInfo("Processing Engine: [{0}]":Format(_p:Name), 1).

    local _beObj to _boosterObj.
    
    if not _beObj[_setIdx]:HasKey("ENG")
    {
        set _beObj[_setIdx]["ENG"] to lexicon(
            "ALLTHRUST", 0
            ,"AVLTHRUST", 0
            ,"PCTTHRUST", 0
            ,"PARTS", lex()
        ).
    }
    if not _beObj[_setIdx]:HasKey("SEP")
    {
        set _beObj[_setIdx]["SEP"] to lexicon().
    }

    if g_PartInfo:Engines:SEPREF:Contains(_p:Name) and _p:Tag:Length = 0
    {
        set _beObj[_setIdx]["SEP"][_p:UID] to _p.
    }
    else
    {
        local curThr  to _p:Thrust.
        local avlThr  to _p:AvailableThrustAt(Body:Atm:AltitudePressure(Ship:Altitude)).

        set _beObj[_setIdx]["ENG"]["PARTS"][_p:UID] to lexicon(
            "P", _p
            ,"M", _p:GetModule("ModuleEnginesRF")
            ,"S", _p:Stage
            ,"T", _p:Config
        ).
        set _beObj[_setIdx]["ENG"]:ALLTHRUST to _beObj[_setIdx]["ENG"]:ALLTHRUST + curThr.
        set _beObj[_setIdx]["ENG"]:AVLTHRUST to _beObj[_setIdx]["ENG"]:AVLTHRUST + avlThr.
        // set _beObj[_setIdx]["ENG"]:PCTTHRUST to Round(max(_beObj[_setIdx]["ENG"]:ALLTHRUST, 0.00000001) / max(_beObj[_setIdx]["ENG"]:AVLTHRUST, 0.0001), 4).
    }

    return _beObj.
}

local function ProcessBoosterTank
{
    parameter _p,
              _setIdx,
              _boosterObj.

    // OutInfo("Processing Tank: [{0}]":Format(_p:Name), 1).

    local _btObj to _boosterObj.
    if not _btObj[_setIdx]:HasKey("TANK")
    {
        set _btObj[_setIdx]["TANK"] to lexicon().
    }

    set _btObj[_setIdx]["TANK"][_p:UID] to lexicon(
        "P", _p
        ,"M", _p:GetModule("ModuleFuelTank")
    ).
    set _btObj to ProcessBoosterTankResources(_p, _btObj).

    return _btObj.
}

local function ProcessBoosterTankResources
{
    parameter _p,
              _setIdx,
              _boosterObj.

    local _brObj to _boosterObj.

    if not _brObj[_setIdx]:HasKey("RES")
    {
        set _brObj[_setIdx]["RES"] to lexicon(
            "AMOUNT", 0
            ,"CAPACITY", 0
            ,"RESLIST", list()
        ).
    }

    for _res in _p:Resources
    {
        _brObj[_setIdx]["RES"][_res:Name]:RESLIST:Add(_res).
        set _brObj[_setIdx]["RES"][_res:Name]:AMOUNT to Round(_brObj[_setIdx]["RES"][_res:Name]:AMOUNT + _res:Amount, 5).
        set _brObj[_setIdx]["RES"][_res:Name]:CAPACITY to Round(_brObj[_setIdx]["RES"][_res:Name]:CAPACITY + _res:Capacity, 5).
    }
    return _brObj.
}

local function CheckBoosterStageCondition
{
    parameter _pctThresh to 0.0625.

    if g_BoostersArmed 
    {
        // writeJson(g_BoosterObj, "0:/data/g_boosterobj.json").
        OutInfo("Boosters: [Armed(X)] [Set( )] [Update( )] [Cond( )]").
        if g_BoosterObj:Keys:Length > 0
        {
            OutInfo("Boosters: [Armed(X)] [Set(X)] [Update( )] [Cond( )]").
            local doneFlag to false.

            from { local i to 0.} until i = g_BoosterObj:Keys:Length or doneFlag step { set i to i + 1.} do
            {
                if not g_BoosterObj:Keys[i] = "UPDATE"
                {
                    local bSet to g_BoosterObj[g_BoosterObj:Keys[i]].
                    if bSet:HasKey("UPDATE") 
                    {
                        OutInfo("Boosters: [Armed(X)] [Set(X)] [Update(X)] [Cond( )]").
                        set g_BoosterObj to bSet:UPDATE:Call().
                        wait 0.01.
                        // writeJson(g_BoosterObj, Path("0:/data/g_BoosterObj.json")).
                        // local check to bSet["RES"]["PCTLEFT"] <= _pctThresh.
                        // OutInfo("BoosterStageCondition: {0} ({1})":Format(check, bSet["RES"]["PCTLEFT"]), 2).
                        // if bSet["RES"]["PCTLEFT"] <= _pctThresh
                        // if bSet["ENG"]:Values[0]:P:Thrust < 0.1
                        local bSetKey to bSet:Keys[i].
                        local engPresent to bSet:HasKey("Eng").
                        local allPresent to choose bSet["ENG"]:HasKey("AllThrust") if engPresent else false.
                        local avlPresent to choose bSet["ENG"]:HasKey("AvlThrust") if engPresent else false.

                        print "KEY [{0}] | ENG [{1}] | ALL [{2}] | AVL [{3}]":Format(bsetKey, engPresent, allPresent, avlPresent) at (0, 35).
                        set ThrustThresh to Max(ThrustThresh, bSet["ENG"]:AVLTHRUST * _pctThresh).
                        OutInfo("THRUST: {0} ({1})":Format(Round(bSet["ENG"]:ALLTHRUST, 2), Round(ThrustThresh, 2)), 1).
                        if bSet["ENG"]:ALLTHRUST < ThrustThresh
                        {
                            OutInfo("Boosters: [Armed(X)] [Set(X)] [Update(X)] [Cond(X)]").
                            StageBoosterSet(i).
                            // set bSet to "".
                            wait 0.025.
                            g_BoosterObj:Remove(i).
                            wait 0.01.
                            
                            if g_BoosterObj:Keys:Length < 1
                            {
                                set g_BoostersArmed to false.
                            }
                            else
                            {
                                
                            }
                            set doneFlag to true.
                        }
                    }
                }
            }
        }
        else
        {
            OutInfo("Boosters disarmed").
            set g_BoostersArmed to false.
        }
    }
}

local function StageBoosterSet
{
    parameter _setIdx.

    if g_BoosterObj:HasKey(_setIdx)
    {
        // local stgSet to g_BoosterObj[_setIdx].
    
        for eng in g_BoosterObj[_setIdx]["ENG"]:Parts:Values
        {
            if eng:P:Ignition and not eng:P:Flameout
            {
                eng:P:Shutdown.
            }
        }
        wait 0.01.
        for sep in g_BoosterObj[_setIdx]["SEP"]:Values
        {
            DoEvent(sep:GetModule("ModuleEnginesRF"), "activate engine").
            wait 0.01.
        }
        wait 0.01.
        for dc in g_BoosterObj[_setIdx]["DC"]:Keys
        {
            DoEvent(g_BoosterObj[_setIdx]["DC"][dc]:M, g_BoosterObj[_setIdx]["DC"][dc]:E).
        }
        wait 0.01.

        // Check for AirStarts in the next booster set if present
        if g_BoosterObj:HasKey(_setIdx + 1)
        {
            if g_BoosterObj[_setIdx + 1]:AS
            {
                for eng in g_BoosterObj[_setIdx + 1]["ENG"]:Parts:Values
                {
                    if not eng:P:Ignition
                    {
                        eng:P:Activate.
                    }
                }
            }
        }
        wait 0.01.
        // wait until Stage:Ready.
        // Stage.
        return true.
    }
    else
    {
        return false.
    }
    
}

local function CheckBoosterStaging_Old
{
    parameter _boosterIdx is 0.
              
    local booster_index to _boosterIdx.
    set curBoosterTag   to "booster.{0}":Format(booster_index).
    local boosterParts  to Ship:PartsTagged(curBoosterTag).
    if boosterParts:Length > 0
    {
        set cb to boosterParts[0]. // cb = CheckBooster
        if cb:IsType("Decoupler")
        {

        }
        else if cb:IsType("Engine")
        {
            if cb:Thrust <= 0.0001
            {
                for i in Range (0, cb:SymmetryCount - 1, 1)
                {
                    cb:SymmetryPartner(i):Shutdown.
                }
                wait until Stage:Ready.
                stage.
                wait 0.01.
            
                if Ship:PartsTaggedPattern("booster.\d*"):Length < 1
                {
                    set boostersArmed to false.
                }
                else
                {
                    set booster_index to booster_index + 1.
                }
            }
        }
    }
    return booster_index.
}